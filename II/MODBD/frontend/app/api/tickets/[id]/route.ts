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

  // Determine user type from session or default to B2C
  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";

  try {
    const result = await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");
      const clientTable = getTableName(userType, "client");
      const commentClientTable = getTableName(userType, "comment_client");
      const commentAgentTable = getTableName(userType, "comment_agent");
      const ticketHistoryTable = getTableName(userType, "ticket_history");

      const clientNameField = userType === "B2C" ? "prenume||' '||nume" : userType === "B2B" ? "denumire" : "nume_client";

      const ticketResult = await conn.execute(
        `SELECT t.ticket_id, t.client_id, t.status_id, t.prioritate_id, t.departament_id, t.categorie_id,
                t.titlu, t.descriere, t.data_creare, t.data_rezolvare, t.data_inchidere,
                s.nume AS status_nume, p.nume AS prioritate_nume, d.nume AS departament_nume,
                cat.nume AS categorie_nume,
                c.email AS client_email,
                ${clientNameField} AS client_nume
         FROM ${ticketTable} t
         JOIN Tickly.status s ON s.status_id = t.status_id
         JOIN Tickly.prioritate p ON p.prioritate_id = t.prioritate_id
         JOIN Tickly.departament d ON d.departament_id = t.departament_id
         LEFT JOIN Tickly.categorie cat ON cat.categorie_id = t.categorie_id
         JOIN ${clientTable} c ON c.client_id = t.client_id
         WHERE t.ticket_id = :id`,
        [id]
      );
      const ticketRows = (ticketResult.rows as Record<string, unknown>[]) || [];
      if (ticketRows.length === 0) return null;

      const t = ticketRows[0];
      const ticket = {
        ticket_id: toJsonSafe(t.TICKET_ID) as number,
        status_id: t.STATUS_ID != null ? Number(t.STATUS_ID) : null,
        prioritate_id: t.PRIORITATE_ID != null ? Number(t.PRIORITATE_ID) : null,
        departament_id: t.DEPARTAMENT_ID != null ? Number(t.DEPARTAMENT_ID) : null,
        categorie_id: t.CATEGORIE_ID != null ? Number(t.CATEGORIE_ID) : null,
        titlu: toJsonSafe(t.TITLU) as string,
        descriere: t.DESCRIERE != null ? toJsonSafe(t.DESCRIERE) as string : null,
        data_creare: toJsonSafe(t.DATA_CREARE) as string,
        data_rezolvare: t.DATA_REZOLVARE != null ? toJsonSafe(t.DATA_REZOLVARE) as string : null,
        data_inchidere: t.DATA_INCHIDERE != null ? toJsonSafe(t.DATA_INCHIDERE) as string : null,
        status_nume: toJsonSafe(t.STATUS_NUME) as string,
        prioritate_nume: toJsonSafe(t.PRIORITATE_NUME) as string,
        departament_nume: toJsonSafe(t.DEPARTAMENT_NUME) as string,
        categorie_nume: t.CATEGORIE_NUME != null ? (toJsonSafe(t.CATEGORIE_NUME) as string) : null,
        client_email: toJsonSafe(t.CLIENT_EMAIL) as string,
        client_nume: t.CLIENT_NUME != null ? toJsonSafe(t.CLIENT_NUME) as string : null,
      };

      const commentsResult = await conn.execute(
        `SELECT comment_id, content, created_date, source, author_name, author_id, is_internal FROM (
           SELECT cc.comment_id, cc.content, cc.created_date, 'client' AS source,
                  c.email AS author_name,
                  cc.client_id AS author_id,
                  'N' AS is_internal
           FROM ${commentClientTable} cc
           JOIN ${clientTable} c ON c.client_id = cc.client_id
           WHERE cc.ticket_id = :id1
           UNION ALL
           SELECT ca.comment_id, ca.content, ca.created_date, 'agent' AS source,
                  a.prenume||' '||a.nume AS author_name,
                  ca.agent_id AS author_id,
                  ca.is_internal
           FROM ${commentAgentTable} ca
           JOIN Tickly.agent_profil a ON a.agent_id = ca.agent_id
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
        author_name: c.AUTHOR_NAME != null ? (toJsonSafe(c.AUTHOR_NAME) as string) : "—",
        author_id: c.AUTHOR_ID != null ? Number(c.AUTHOR_ID) : null,
        is_internal: (c.IS_INTERNAL as string) === "Y",
      }));
      if (session.role === "client") {
        comments = comments.filter((c) => !c.is_internal);
      }

      const historyResult = await conn.execute(
        `SELECT history_id, event_type, created_date, created_by_role, created_by_id, author_name, display_text
         FROM ${ticketHistoryTable} WHERE ticket_id = :id ORDER BY created_date`,
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
    if (session.role === "client" && result.clientId !== session.id) {
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
  departament_id?: number;
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

  // Determine user type from session or default to B2C
  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";

  let body: PatchBody;
  try {
    body = (await request.json()) as PatchBody;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const isAgent = session.role === "agent";
  if (!isAgent && (body.status_id != null || body.prioritate_id != null || body.departament_id != null || body.categorie_id !== undefined || body.assigned_agent_id !== undefined)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  try {
    await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");
      const ticketHistoryTable = getTableName(userType, "ticket_history");

      const ownTicketCheck = await conn.execute(
        `SELECT client_id FROM ${ticketTable} WHERE ticket_id = :id`,
        [id]
      );
      const rows = (ownTicketCheck.rows as Record<string, unknown>[]) || [];
      if (rows.length === 0) return;
      const ticketClientId = rows[0].CLIENT_ID != null ? Number(rows[0].CLIENT_ID) : null;
      const canEditTicket = isAgent || ticketClientId === session.id;

      if (body.titlu !== undefined && canEditTicket) {
        const newTitlu = (body.titlu ?? "").trim() || null;
        if (newTitlu != null) {
          await conn.execute(
            `UPDATE ${ticketTable} SET titlu = :titlu, data_ultima_actualizare = SYSDATE WHERE ticket_id = :id`,
            { id, titlu: newTitlu }
          );
          await conn.execute(
            `INSERT INTO ${ticketHistoryTable} (ticket_id, event_type, created_by_role, created_by_id, author_name, display_text)
             VALUES (:id, 'TITLU_MODIFICAT', :role, :author_id, :author_name, 'Titlul a fost modificat')`,
            { id, role: session.role, author_id: session.id, author_name: session.name || "" }
          );
        }
      }

      if (body.descriere !== undefined && canEditTicket) {
        const newDesc = body.descriere === null || body.descriere === "" ? null : body.descriere;
        await conn.execute(
          `UPDATE ${ticketTable} SET descriere = :descriere, data_ultima_actualizare = SYSDATE WHERE ticket_id = :id`,
          { id, descriere: newDesc }
        );
        await conn.execute(
          `INSERT INTO ${ticketHistoryTable} (ticket_id, event_type, created_by_role, created_by_id, author_name, display_text)
           VALUES (:id, 'DESCRIERE_MODIFICATA', :role, :author_id, :author_name, 'Descrierea a fost modificată')`,
          { id, role: session.role, author_id: session.id, author_name: session.name || "" }
        );
      }

      if (!isAgent) return;

      if (body.status_id != null || body.prioritate_id != null || body.departament_id != null || body.categorie_id !== undefined) {
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
        if (body.departament_id != null) {
          updates.push("departament_id = :departament_id");
          binds.departament_id = body.departament_id;
        }
        if (body.categorie_id !== undefined) {
          updates.push("categorie_id = :categorie_id");
          binds.categorie_id = body.categorie_id;
        }
        if (body.status_id != null) {
          const statusNameResult = await conn.execute(
            "SELECT nume FROM Tickly.status WHERE status_id = :sid",
            [body.status_id]
          );
          const sn = (statusNameResult.rows as Record<string, unknown>[])?.[0]?.NUME as string | undefined;
          if (sn === "Rezolvat") {
            updates.push("data_rezolvare = NVL(data_rezolvare, SYSDATE)");
          } else if (sn === "Inchis") {
            updates.push("data_inchidere = NVL(data_inchidere, SYSDATE)");
          }
        }
        if (updates.length > 0) {
          updates.push("data_ultima_actualizare = SYSDATE");
          await conn.execute(
            `UPDATE ${ticketTable} SET ${updates.join(", ")} WHERE ticket_id = :id`,
            binds
          );
        }
      }

      if (body.assigned_agent_id !== undefined) {
        const ticketAgentTable = userType === "B2C" ? "Tickly.ticket_agent_fizic" : userType === "B2B" ? "Tickly.ticket_agent_juridic" : "Tickly.v_ticket_agent";
        await conn.execute(`DELETE FROM ${ticketAgentTable} WHERE ticket_id = :id AND rol = 'PRIMARY'`, [id]);
        if (body.assigned_agent_id != null) {
          await conn.execute(
            `INSERT INTO ${ticketAgentTable} (ticket_id, agent_id, rol) VALUES (:id, :agent_id, 'PRIMARY')`,
            { id, agent_id: body.assigned_agent_id }
          );
        }
        await conn.execute(
          `UPDATE ${ticketTable} SET data_ultima_actualizare = SYSDATE WHERE ticket_id = :id`,
          [id]
        );
      }
    });

    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("ticket patch", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to update ticket" },
      { status: 500 }
    );
  }
}
