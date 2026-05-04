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

  // Determine user type from session or default to B2C
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

      // Build bind object for count and select (Oracle named binds)
      const countBinds: Record<string, unknown> = {};
      if (isClient) countBinds.client_id = session.id;
      statusNamesList.forEach((name, i) => {
        (countBinds as Record<string, unknown>)["sn" + i] = name;
      });
      const pageBinds = { ...countBinds, off: (page - 1) * limit, lim: limit };

      // Count total for current filter
      const countSql =
        `SELECT COUNT(*) AS cnt FROM ${ticketTable} t JOIN Tickly.status s ON s.status_id = t.status_id WHERE ` +
        whereClause;
      const countResult = await conn.execute(countSql, countBinds);
      const filteredTotal = Number((countResult.rows as Record<string, unknown>[])?.[0]?.CNT ?? 0);

      const sql =
        `SELECT t.ticket_id, t.titlu, t.data_creare, t.data_ultima_actualizare, t.data_rezolvare,
                s.nume AS status_nume, p.nume AS prioritate_nume, d.nume AS departament_nume,
                c.email AS client_email,
                ${userType === "B2C" ? "c.prenume||' '||c.nume" : userType === "B2B" ? "c.denumire" : "c.nume_client"} AS client_nume
         FROM ${ticketTable} t
         JOIN Tickly.status s ON s.status_id = t.status_id
         JOIN Tickly.prioritate p ON p.prioritate_id = t.prioritate_id
         JOIN Tickly.departament d ON d.departament_id = t.departament_id
         JOIN ${clientTable} c ON c.client_id = t.client_id
         WHERE ` +
        whereClause +
        ` ORDER BY NVL(t.data_ultima_actualizare, t.data_creare) DESC, t.data_creare DESC
         OFFSET :off ROWS FETCH NEXT :lim ROWS ONLY`;
      const r = await conn.execute(sql, pageBinds);
      const raw = (r.rows as Record<string, unknown>[]) || [];
      const tickets = raw.map((row) => ({
        ticket_id: row.TICKET_ID,
        titlu: row.TITLU,
        data_creare: row.DATA_CREARE,
        data_ultima_actualizare: row.DATA_ULTIMA_ACTUALIZARE ?? row.DATA_CREARE,
        data_rezolvare: row.DATA_REZOLVARE,
        status_nume: row.STATUS_NUME,
        prioritate_nume: row.PRIORITATE_NUME,
        departament_nume: row.DEPARTAMENT_NUME,
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

  // Determină tipul de utilizator pentru a ști către ce server trimitem (SV1 - B2C sau SV2 - B2B)
  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";

  // Agenții (SV3) nu au rolul de a crea tichete
  if (userType === "AGENT") {
    return NextResponse.json({ error: "Agenții nu pot crea tichete." }, { status: 403 });
  }

  try {
    const body = await request.json();
    const { titlu, descriere, departament_id, prioritate_id, categorie_id } = body;

    if (!titlu || !departament_id || !prioritate_id) {
      return NextResponse.json(
        { error: "Te rog completează toate câmpurile obligatorii (Titlu, Departament, Prioritate)." }, 
        { status: 400 }
      );
    }

    const result = await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");

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
          (client_id, departament_id, prioritate_id, status_id, categorie_id, titlu, descriere, data_creare)
        VALUES 
          (:client_id, :dep_id, :prio_id, :stat_id, :cat_id, :titlu, :descriere, SYSDATE)
        RETURNING ticket_id INTO :new_id
      `;

      const cleanBind = (val: any) => (val === undefined || val === "" || Number.isNaN(val) ? null : val);

      const binds = {
        client_id: session.id,
        dep_id: Number(departament_id),
        prio_id: Number(prioritate_id),
        stat_id: defaultStatusId,
        cat_id: categorie_id ? Number(categorie_id) : null,
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