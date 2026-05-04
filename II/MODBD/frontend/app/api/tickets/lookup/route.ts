import { NextResponse } from "next/server";
import { runQuery } from "@/lib/db";
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

export async function GET() {
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }
  if (session.role !== "agent") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  try {
    const result = await runQuery(async (conn) => {
      const [statusRows, prioritateRows, departamentRows, categorieRows, agentRows] = await Promise.all([
        conn.execute("SELECT status_id, nume FROM Tickly.status ORDER BY status_id"),
        conn.execute("SELECT prioritate_id, nume FROM Tickly.prioritate ORDER BY nivel"),
        conn.execute("SELECT departament_id, nume FROM Tickly.departament ORDER BY nume"),
        conn.execute("SELECT categorie_id, nume FROM Tickly.categorie ORDER BY nume"),
        conn.execute("SELECT agent_id, prenume, nume, email FROM Tickly.agent_profil WHERE is_active = 'Y' ORDER BY nume, prenume"),
      ]);

      const map = (rows: unknown[], idKey: string, labelKey: string) =>
        (rows as Record<string, unknown>[]).map((r) => ({
          id: Number(r[idKey]),
          nume: toJsonSafe(r[labelKey]) as string,
        }));

      const agents = (agentRows.rows as Record<string, unknown>[]) || [];
      return {
        statuses: map(statusRows.rows as Record<string, unknown>[], "STATUS_ID", "NUME"),
        priorities: map(prioritateRows.rows as Record<string, unknown>[], "PRIORITATE_ID", "NUME"),
        departments: map(departamentRows.rows as Record<string, unknown>[], "DEPARTAMENT_ID", "NUME"),
        categories: map(categorieRows.rows as Record<string, unknown>[], "CATEGORIE_ID", "NUME"),
        agents: agents.map((a) => ({
          id: Number(a.AGENT_ID),
          nume: `${toJsonSafe(a.PRENUME)} ${toJsonSafe(a.NUME)}`,
          email: toJsonSafe(a.EMAIL) as string,
        })),
      };
    });

    return NextResponse.json(result);
  } catch (e) {
    console.error("lookup api", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to fetch lookup data" },
      { status: 500 }
    );
  }
}
