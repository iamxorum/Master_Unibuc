import { NextResponse } from "next/server";
import { runQueryByUserType, getTableName } from "@/lib/db";
import { getSession } from "@/lib/auth";
import oracledb from "oracledb";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const withStats = searchParams.get("stats") === "1" || searchParams.get("stats") === "true";
  const page = Math.max(1, parseInt(searchParams.get("page") ?? "1", 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(searchParams.get("limit") ?? "20", 10) || 20));
  const statusFilter = searchParams.get("statusFilter") ?? "all";
  const statusNames = searchParams.get("status");

  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";

  try {
    const result = await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");
      const clientTable = getTableName(userType, "client");

      const isClient = session.role === "client";
      const baseWhere = isClient ? `t.client_id = :client_id` : "1=1";
      const clientBinds: (string | number)[] = isClient ? [session.id] : [];

      let statusWhere = "";
      const statusBinds: string[] = [];
      if (isClient) {
        if (statusFilter === "open") statusWhere = " AND s.este_final = 'N'";
        else if (statusFilter === "closed") statusWhere = " AND s.este_final = 'Y'";
      } else if (statusNames && statusNames.trim()) {
        const names = statusNames.split(",").map((n) => n.trim()).filter(Boolean);
        if (names.length) {
          statusWhere = " AND s.nume IN (" + names.map((_, i) => ":sn" + i).join(",") + ")";
        }
      }
      const whereClause = baseWhere + statusWhere;
      const statusNamesList = !isClient && statusNames?.trim()
        ? statusNames.split(",").map((n) => n.trim()).filter(Boolean)
        : [];

      const countBinds: Record<string, unknown> = {};
      if (isClient) countBinds.client_id = session.id;
      statusNamesList.forEach((name, i) => {
        (countBinds as Record<string, unknown>)["sn" + i] = name;
      });
      const pageBinds = { ...countBinds, off: (page - 1) * limit, lim: limit };

      const countSql =
        `SELECT COUNT(*) AS cnt FROM ${ticketTable} t JOIN Tickly.status s ON s.status_id = t.status_id WHERE ` +
        whereClause;
      const countResult = await conn.execute(countSql, countBinds);
      const filteredTotal = Number((countResult.rows as Record<string, unknown>[])?.[0]?.CNT ?? 0);

      const sql = `
    SELECT t.ticket_id, t.titlu, t.data_creare, t.data_rezolvare,
          s.nume AS status_nume, p.nume AS prioritate_nume, cat.nume AS categorie_nume,
          c.email AS client_email,
          -- Dacă e AGENT folosește NUME_CLIENT din V_CLIENT_GLOBAL
          -- Dacă e B2C/B2B folosește DISPLAY_NAME din view-urile de AUTH
          ${userType === "AGENT" ? "c.nume_client" : "c.display_name"} AS client_nume
    FROM ${ticketTable} t
    JOIN TICKLY.STATUS s ON s.status_id = t.status_id
    JOIN TICKLY.PRIORITATE p ON p.prioritate_id = t.prioritate_id
    LEFT JOIN TICKLY.CATEGORIE cat ON cat.categorie_id = t.categorie_id
    JOIN ${clientTable} c ON c.client_id = t.client_id
    WHERE ` + whereClause + `
    ORDER BY t.data_creare DESC
    OFFSET :off ROWS FETCH NEXT :lim ROWS ONLY`;
         
      const r = await conn.execute(sql, pageBinds);
      const raw = (r.rows as Record<string, unknown>[]) || [];
      
      const tickets = raw.map((row) => ({
        ticket_id: row.TICKET_ID,
        titlu: row.TITLU,
        data_creare: row.DATA_CREARE,
        data_ultima_actualizare: row.DATA_CREARE, 
        data_rezolvare: row.DATA_REZOLVARE,
        status_nume: row.STATUS_NUME,
        prioritate_nume: row.PRIORITATE_NUME,
        categorie_nume: row.CATEGORIE_NUME, 
        client_email: row.CLIENT_EMAIL,
        client_nume: row.CLIENT_NUME,
      }));

      if (!withStats) return { tickets, total: filteredTotal };

      const statsSql = isClient
        ? `SELECT s.status_id, s.nume, s.este_final, NVL(t.cnt, 0) AS cnt
           FROM Tickly.status s
           LEFT JOIN (
             SELECT status_id, COUNT(*) AS cnt FROM ${ticketTable} WHERE client_id = :client_id GROUP BY status_id
           ) t ON t.status_id = s.status_id
           ORDER BY s.status_id`
        : `SELECT s.status_id, s.nume, s.este_final, NVL(t.cnt, 0) AS cnt
           FROM Tickly.status s
           LEFT JOIN (
             SELECT status_id, COUNT(*) AS cnt FROM ${ticketTable} GROUP BY status_id
           ) t ON t.status_id = s.status_id
           ORDER BY s.status_id`;
      const statsResult = await conn.execute(statsSql, isClient ? { client_id: session.id } : {});
      const statsRows = (statsResult.rows as Record<string, unknown>[]) || [];
      let statsTotal = 0;
      const statuses = statsRows.map((row) => {
        const count = Number(row.CNT ?? 0);
        statsTotal += count;
        return {
          status_id: row.STATUS_ID,
          nume: String(row.NUME ?? ""),
          este_final: row.ESTE_FINAL === "Y",
          count,
        };
      });

      return {
        tickets,
        total: filteredTotal,
        stats: {
          total: statsTotal,
          statuses,
        },
      };
    });

    if (withStats && result && typeof result === "object" && !Array.isArray(result)) {
      return NextResponse.json(result);
    }
    return NextResponse.json(Array.isArray(result) ? result : (result as { tickets: unknown }).tickets ?? []);
  } catch (e) {
    console.error("tickets api", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to fetch tickets" },
      { status: 500 }
    );
  }
}

if (!oracledb.outFormat) {
  oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
}

export async function POST(request: Request) {
  const session = await getSession();
  if (!session || !session.id) {
    return NextResponse.json({ error: "Trebuie să fii autentificat pentru a crea un tichet." }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { titlu, descriere, prioritate_id, categorie_id, client_type, client_id, is_agent_creation } = body;

    const isAgent = session.role === "agent";
    
    // Stabilim baza de date (PDB-ul țintă) și ID-ul clientului
    let targetUserType: "B2C" | "B2B" = (session.userType as "B2C" | "B2B") || "B2C";
    let targetClientId = session.id;

    if (isAgent) {
      if (!client_type || !client_id) {
        return NextResponse.json(
          { error: "Ca agent, trebuie să selectezi tipul și ID-ul clientului." },
          { status: 400 }
        );
      }
      // Suprascriem variabilele țintă cu selecția agentului din formular
      targetUserType = client_type as "B2C" | "B2B";
      targetClientId = client_id;
    } else if (session.userType === "AGENT") {
      // Failsafe pentru a asigura ca un user cu rol incorect dar userType AGENT sa nu treacă
      return NextResponse.json({ error: "Sesiune invalidă." }, { status: 403 });
    }

    // Validări de bază
    if (!titlu || !categorie_id || !prioritate_id) {
      return NextResponse.json(
        { error: "Te rog completează toate câmpurile obligatorii (Titlu, Categorie, Prioritate)." }, 
        { status: 400 }
      );
    }

    // Rulăm query-ul către baza de date B2C sau B2B, în funcție de targetUserType
    const result = await runQueryByUserType(targetUserType, async (conn) => {
      const ticketTable = getTableName(targetUserType, "ticket");

      const statusRes = await conn.execute(
        `SELECT status_id FROM Tickly.status WHERE este_final = 'N' ORDER BY status_id FETCH FIRST 1 ROWS ONLY`
      );
      
      const rows = statusRes.rows as Record<string, any>[];
      const defaultStatusId = rows?.[0]?.STATUS_ID;

      if (!defaultStatusId) {
        throw new Error("Nu s-a găsit niciun status valid (nefinal) în baza de date.");
      }
      
      const sql = `
        INSERT INTO ${ticketTable}
          (client_id, prioritate_id, status_id, categorie_id, titlu, descriere, data_creare)
        VALUES 
          (:client_id, :prio_id, :stat_id, :cat_id, :titlu, :descriere, SYSDATE)
        RETURNING ticket_id INTO :new_id
      `;

      const cleanBind = (val: any) => (val === undefined || val === "" || Number.isNaN(val) ? null : val);

      const binds = {
        client_id: targetClientId, // Folosim target-ul (fie din sesiune, fie suprascris de agent)
        prio_id: Number(prioritate_id),
        stat_id: defaultStatusId,
        cat_id: Number(categorie_id),
        titlu: titlu,
        descriere: cleanBind(descriere), 
        new_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      };

      const r = await conn.execute(sql, binds, { autoCommit: true });

      const outBinds = r.outBinds as any;
      const newTicketId = outBinds?.new_id?.[0] ?? outBinds?.new_id;

      return { ticket_id: newTicketId, message: "Tichet creat cu succes!" };
    });

    return NextResponse.json(result);

  } catch (e: any) {
    console.error("Eroare la crearea tichetului:", e);
    return NextResponse.json(
      { error: e.message || "A apărut o eroare la salvarea tichetului." }, 
      { status: 500 }
    );
  }
}