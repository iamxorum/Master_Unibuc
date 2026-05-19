import { NextResponse } from "next/server";
import { runQueryByUserType, getTableName } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const dynamic = "force-dynamic";

function toJsonSafe(value: unknown): unknown {
  if (value == null) return null;
  if (typeof value === "number" || typeof value === "boolean") return value;
  if (typeof value === "string") return value;
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "object") return String(value);
  return value;
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const id = Number((await params).id);
  if (!Number.isInteger(id) || id < 1) {
    return NextResponse.json({ error: "Invalid ticket id" }, { status: 400 });
  }

  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";
  const isAgent = session.role === "agent";

  try {
    const result = await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");
      const clientTable = getTableName(userType, "client");
      const commentClientTable = getTableName(userType, "comment_client");
      const commentAgentTable = getTableName(userType, "comment_agent");
      const ticketHistoryTable = getTableName(userType, "ticket_history");

      const clientNameField = userType === "AGENT" ? "c.nume_client" : "c.display_name";

      // SECURIZARE: Dacă este client, adăugăm filtru pe client_id direct în SQL
      let securityWhere = "";
      const queryBinds: Record<string, any> = { id };
      
      if (!isAgent) {
        securityWhere = " AND t.client_id = :client_id";
        queryBinds.client_id = session.id;
      }

      const ticketResult = await conn.execute(
        `SELECT t.ticket_id, t.client_id, t.status_id, t.prioritate_id, t.categorie_id,
                t.titlu, t.descriere, t.data_creare, t.data_rezolvare,
                s.nume AS status_nume, p.nume AS prioritate_nume, 
                cat.nume AS categorie_nume,
                NULL AS client_email,
                ${clientNameField} AS client_nume,
                ${userType === "AGENT" ? "t.tip_client" : "'LOCAL'"} AS tip_sursa
         FROM ${ticketTable} t
         JOIN TICKLY.STATUS s ON s.status_id = t.status_id
         JOIN TICKLY.PRIORITATE p ON p.prioritate_id = t.prioritate_id
         LEFT JOIN TICKLY.CATEGORIE cat ON cat.categorie_id = t.categorie_id
         JOIN ${clientTable} c ON c.client_id = t.client_id
         WHERE t.ticket_id = :id ${securityWhere}`,
        queryBinds
      );

      const ticketRows = (ticketResult.rows as Record<string, unknown>[]) || [];
      if (ticketRows.length === 0) return null;

      const t = ticketRows[0];
      
      // REGULĂ CONEXIUNE: Identificăm dacă datele aparțin bazei de date juridice (B2B)
      const isRemoteJuridic = t.TIP_SURSA === 'JURIDIC';
      const isCurrentlyB2B = userType === "B2B";
      const isJuridicContext = isRemoteJuridic || isCurrentlyB2B;

      // DB Link se aplică DOAR dacă un AGENT (aflat pe SV1) accesează un tichet marcat ca JURIDIC (pe SV2)
      const suffix = (userType === "AGENT" && isRemoteJuridic) ? "@LINK_SV2" : "";

      // Stabilim tabelele asimilate contextului curent
      const actualAgentLinkTable = isJuridicContext 
        ? `TICKLY.ticket_agent_juridic${suffix}` 
        : "TICKLY.ticket_agent_fizic";

      const agentAssignResult = await conn.execute(
        `SELECT ta.agent_id, ap.prenume || ' ' || ap.nume as agent_nume
         FROM ${actualAgentLinkTable} ta
         JOIN TICKLY.agent_profil ap ON ap.agent_id = ta.agent_id
         WHERE ta.ticket_id = :id AND ta.rol = 'PRIMARY'`,
        [id]
      );
      const agentData = (agentAssignResult.rows as any[])?.[0];

      const ticket = {
        ticket_id: toJsonSafe(t.TICKET_ID) as number,
        status_id: t.STATUS_ID != null ? Number(t.STATUS_ID) : null,
        prioritate_id: t.PRIORITATE_ID != null ? Number(t.PRIORITATE_ID) : null,
        categorie_id: t.CATEGORIE_ID != null ? Number(t.CATEGORIE_ID) : null,
        titlu: toJsonSafe(t.TITLU) as string,
        descriere: t.DESCRIERE != null ? toJsonSafe(t.DESCRIERE) as string : null,
        data_creare: toJsonSafe(t.DATA_CREARE) as string,
        data_rezolvare: t.DATA_REZOLVARE != null ? toJsonSafe(t.DATA_REZOLVARE) as string : null,
        data_inchidere: t.DATA_REZOLVARE != null ? toJsonSafe(t.DATA_REZOLVARE) as string : null,
        status_nume: toJsonSafe(t.STATUS_NUME) as string,
        prioritate_nume: toJsonSafe(t.PRIORITATE_NUME) as string,
        categorie_nume: t.CATEGORIE_NUME != null ? (toJsonSafe(t.CATEGORIE_NUME) as string) : null,
        client_email: t.CLIENT_EMAIL ? String(t.CLIENT_EMAIL) : "Confidențial (SV3)",
        client_nume: t.CLIENT_NUME != null ? toJsonSafe(t.CLIENT_NUME) as string : null,
        assigned_agent_id: agentData ? Number(agentData.AGENT_ID) : null,
        assigned_agent_nume: agentData ? String(agentData.AGENT_NUME) : null,
        assigned_agent: agentData ? {
          id: Number(agentData.AGENT_ID),
          nume: String(agentData.AGENT_NUME)
        } : null
      };

      const actualCommentClient = isJuridicContext ? `TICKLY.comment_client_juridic${suffix}` : commentClientTable;
      const actualCommentAgent = isJuridicContext ? `TICKLY.comment_agent_juridic${suffix}` : commentAgentTable;
      const actualHistoryTable = isJuridicContext ? `TICKLY.ticket_history_juridic${suffix}` : ticketHistoryTable;

      const commentsResult = await conn.execute(
        `SELECT comment_id, content, created_date, source, author_name, author_id, is_internal FROM (
           SELECT cc.comment_id, cc.content, cc.created_date, 'client' AS source,
                  NULL AS author_name,
                  cc.client_id AS author_id,
                  'N' AS is_internal
           FROM ${actualCommentClient} cc
           WHERE cc.ticket_id = :id1
           UNION ALL
           SELECT ca.comment_id, ca.content, ca.created_date, 'agent' AS source,
                  a.prenume||' '||a.nume AS author_name,
                  ca.agent_id AS author_id,
                  ca.is_internal
           FROM ${actualCommentAgent} ca
           LEFT JOIN Tickly.agent_profil a ON a.agent_id = ca.agent_id
           WHERE ca.ticket_id = :id2
         ) ORDER BY created_date`,
        { id1: id, id2: id }
      );

      const commentRows = (commentsResult.rows as Record<string, unknown>[]) || [];
      let comments = commentRows.map((c) => ({
        comment_id: toJsonSafe(c.COMMENT_ID) as number,
        content: toJsonSafe(c.CONTENT) as string,
        created_date: toJsonSafe(c.CREATED_DATE) as string,
        source: toJsonSafe(c.SOURCE) as string,
        author_name: c.AUTHOR_NAME != null ? (toJsonSafe(c.AUTHOR_NAME) as string) : (c.SOURCE === 'client' ? 'Client' : '—'),
        author_id: c.AUTHOR_ID != null ? Number(c.AUTHOR_ID) : null,
        is_internal: (c.IS_INTERNAL as string) === "Y",
      }));
      
      if (session.role === "client") {
        comments = comments.filter((c) => !c.is_internal);
      }

      const historyResult = await conn.execute(
        `SELECT history_id, event_type, created_date, created_by_role, created_by_id, author_name, display_text
         FROM ${actualHistoryTable} WHERE ticket_id = :id ORDER BY created_date`,
        [id]
      );
      const historyRows = (historyResult.rows as Record<string, unknown>[]) || [];
      const history = historyRows.map((h) => ({
        history_id: toJsonSafe(h.HISTORY_ID) as number,
        event_type: toJsonSafe(h.EVENT_TYPE) as string,
        created_date: toJsonSafe(h.CREATED_DATE) as string,
        author_name: h.AUTHOR_NAME != null ? (toJsonSafe(h.AUTHOR_NAME) as string) : "—",
        display_text: h.DISPLAY_TEXT != null ? (toJsonSafe(h.DISPLAY_TEXT) as string) : null,
      }));

      const timeline = [
        ...comments.map((c) => ({ type: "comment" as const, ...c })),
        ...history.map((h) => ({ type: "history" as const, ...h })),
      ].sort((a, b) => new Date(a.created_date).getTime() - new Date(b.created_date).getTime());

      const clientId = t.CLIENT_ID != null ? Number(t.CLIENT_ID) : null;
      return { ticket, comments, timeline, attachments: [], clientId };
    });

    if (result == null) {
      return NextResponse.json({ error: "Ticket not found" }, { status: 404 });
    }
    
    // Failsafe adițional de securitate pe backend
    if (!isAgent && result.clientId !== session.id) {
      return NextResponse.json({ error: "Ticket not found" }, { status: 404 });
    }

    return NextResponse.json({ ticket: result.ticket, comments: result.comments, timeline: result.timeline, attachments: result.attachments });
  } catch (e) {
    console.error("ticket detail api", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to fetch ticket" },
      { status: 500 }
    );
  }
}

type PatchBody = {
  titlu?: string;
  descriere?: string | null;
  status_id?: number;
  prioritate_id?: number;
  categorie_id?: number | null;
  assigned_agent_id?: number | null;
};

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const id = Number((await params).id);
  if (!Number.isInteger(id) || id < 1) {
    return NextResponse.json({ error: "Invalid ticket id" }, { status: 400 });
  }

  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";
  const isAgent = session.role === "agent";

  let body: PatchBody;
  try {
    body = (await request.json()) as PatchBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (!isAgent && (body.status_id != null || body.prioritate_id != null || body.categorie_id !== undefined || body.assigned_agent_id !== undefined)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  try {
    const errorResult = await runQueryByUserType(userType, async (conn) => {
      // Verificăm dacă tichetul există și dacă aparține clientului (atunci când nu e agent)
      let securityCheckWhere = "";
      const checkBinds: Record<string, any> = { id };

      if (!isAgent) {
        securityCheckWhere = " AND client_id = :client_id";
        checkBinds.client_id = session.id;
      }

      const checkResult = await conn.execute(
        `SELECT ${userType === "AGENT" ? "tip_client" : "'LOCAL'"} as tip, client_id 
         FROM ${getTableName(userType, "ticket")} WHERE ticket_id = :id ${securityCheckWhere}`,
        checkBinds
      );
      
      const rowsCheck = (checkResult.rows as any[]) || [];
      if (rowsCheck.length === 0) {
        return { status: 404, error: "Ticket not found" };
      }

      const isRemoteJuridic = rowsCheck[0].TIP === 'JURIDIC';
      const isCurrentlyB2B = userType === "B2B";
      const isJuridicContext = isRemoteJuridic || isCurrentlyB2B;
      const suffix = (userType === "AGENT" && isRemoteJuridic) ? "@LINK_SV2" : "";
      
      let physicalTable: string;
      let physicalHistoryTable: string;

      if (userType === "AGENT") {
        physicalTable = isRemoteJuridic ? `TICKLY.ticket_juridic${suffix}` : "TICKLY.ticket_fizic";
        physicalHistoryTable = isRemoteJuridic ? `TICKLY.ticket_history_juridic${suffix}` : "TICKLY.ticket_history_fizic";
      } else {
        physicalTable = getTableName(userType, "ticket");
        physicalHistoryTable = getTableName(userType, "ticket_history");
      }

      if (body.titlu !== undefined) {
        const newTitlu = (body.titlu ?? "").trim() || null;
        if (newTitlu != null) {
          await conn.execute(
            `UPDATE ${physicalTable} SET titlu = :titlu WHERE ticket_id = :id`,
            { id, titlu: newTitlu }
          );
          await conn.execute(
            `INSERT INTO ${physicalHistoryTable} (ticket_id, event_type, created_by_role, created_by_id, author_name, display_text)
             VALUES (:id, 'TITLU_MODIFICAT', :role, :author_id, :author_name, 'Titlul a fost modificat')`,
            { id, role: session.role, author_id: session.id, author_name: session.name || "" }
          );
        }
      }

      if (body.descriere !== undefined) {
        const newDesc = body.descriere === null || body.descriere === "" ? null : body.descriere;
        await conn.execute(
          `UPDATE ${physicalTable} SET descriere = :descriere WHERE ticket_id = :id`,
          { id, descriere: newDesc }
        );
        await conn.execute(
          `INSERT INTO ${physicalHistoryTable} (ticket_id, event_type, created_by_role, created_by_id, author_name, display_text)
           VALUES (:id, 'DESCRIERE_MODIFICATA', :role, :author_id, :author_name, 'Descrierea a fost modificată')`,
          { id, role: session.role, author_id: session.id, author_name: session.name || "" }
        );
      }

      if (!isAgent) return null;

      if (body.status_id != null || body.prioritate_id != null || body.categorie_id !== undefined) {
        const updates: string[] = [];
        const binds: Record<string, number | null> = { id };
        if (body.status_id != null) {
          updates.push("status_id = :status_id");
          binds.status_id = body.status_id;
        }
        if (body.prioritate_id != null) {
          updates.push("prioritate_id = :prioritate_id");
          binds.prioritate_id = body.prioritate_id;
        }
        if (body.categorie_id !== undefined) {
          updates.push("categorie_id = :categorie_id");
          binds.categorie_id = body.categorie_id;
        }
        if (body.status_id != null) {
          const statusNameResult = await conn.execute(
            "SELECT nume FROM TICKLY.STATUS WHERE status_id = :sid",
            [body.status_id]
          );
          const sn = (statusNameResult.rows as Record<string, unknown>[])?.[0]?.NUME as string | undefined;
          if (sn === "Rezolvat" || sn === "Inchis") {
            updates.push("data_rezolvare = NVL(data_rezolvare, SYSDATE)");
          }
        }
        if (updates.length > 0) {
          await conn.execute(
            `UPDATE ${physicalTable} SET ${updates.join(", ")} WHERE ticket_id = :id`,
            binds
          );
        }
      }

      if (body.assigned_agent_id !== undefined) {
        const actualTicketAgentTable = isJuridicContext 
          ? `TICKLY.ticket_agent_juridic${suffix}` 
          : "TICKLY.ticket_agent_fizic";

        await conn.execute(
          `DELETE FROM ${actualTicketAgentTable} WHERE ticket_id = :id AND rol = 'PRIMARY'`, 
          [id]
        );

        if (body.assigned_agent_id != null) {
          await conn.execute(
            `INSERT INTO ${actualTicketAgentTable} (ticket_id, agent_id, rol) 
             VALUES (:id, :agent_id, 'PRIMARY')`,
            { id, agent_id: body.assigned_agent_id }
          );
          
          await conn.execute(
            `INSERT INTO ${physicalHistoryTable} (ticket_id, event_type, created_by_role, created_by_id, author_name, display_text)
             VALUES (:id, 'AGENT_ASIGNAT', :role, :author_id, :author_name, 'Ticket asignat unui nou agent')`,
            { 
              id, 
              role: session.role, 
              author_id: session.id, 
              author_name: session.name || "" 
            }
          );
        }
      }
      return null;
    });

    if (errorResult) {
      return NextResponse.json({ error: errorResult.error }, { status: errorResult.status });
    }

    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("ticket patch", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to update ticket" },
      { status: 500 }
    );
  }
}