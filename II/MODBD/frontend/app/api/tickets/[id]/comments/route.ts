import { NextResponse } from "next/server";
import { runQueryByUserType, getTableName } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const ticketId = Number((await params).id);
  if (!Number.isInteger(ticketId) || ticketId < 1) {
    return NextResponse.json({ error: "Invalid ticket id" }, { status: 400 });
  }

  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  // Determine user type from session or default to B2C
  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";

  let body: { content?: string; is_internal?: boolean };
  try {
    body = (await request.json()) as { content?: string; is_internal?: boolean };
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }
  const content = typeof body.content === "string" ? body.content.trim() : "";
  if (!content) {
    return NextResponse.json({ error: "Content is required" }, { status: 400 });
  }
  const isInternal = session.role === "agent" && body.is_internal === true;

  try {
    const result = await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");
      const commentClientTable = getTableName(userType, "comment_client");
      const commentAgentTable = getTableName(userType, "comment_agent");

      const ticketCheck = await conn.execute(
        `SELECT ticket_id, client_id FROM ${ticketTable} WHERE ticket_id = :id`,
        [ticketId]
      );
      const rows = (ticketCheck.rows as Record<string, unknown>[]) || [];
      if (rows.length === 0) return { error: "not_found" as const };

      const clientId = rows[0].CLIENT_ID != null ? Number(rows[0].CLIENT_ID) : null;

      if (session.role === "client") {
        if (clientId !== session.id) return { error: "forbidden" as const };
        await conn.execute(
          `INSERT INTO ${commentClientTable} (ticket_id, client_id, content) VALUES (:ticket_id, :client_id, :content)`,
          { ticket_id: ticketId, client_id: session.id, content }
        );
      } else {
        if (session.role !== "agent") return { error: "forbidden" as const };
        await conn.execute(
          `INSERT INTO ${commentAgentTable} (ticket_id, agent_id, content, is_internal) VALUES (:ticket_id, :agent_id, :content, :is_internal)`,
          { ticket_id: ticketId, agent_id: session.id, content, is_internal: isInternal ? "Y" : "N" }
        );
      }
      await conn.execute(
        `UPDATE ${ticketTable} SET data_ultima_actualizare = SYSDATE WHERE ticket_id = :tid`,
        { tid: ticketId }
      );
      return { ok: true };
    });

    if (result?.error === "not_found") {
      return NextResponse.json({ error: "Ticket not found" }, { status: 404 });
    }
    if (result?.error === "forbidden") {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("comment post", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to add comment" },
      { status: 500 }
    );
  }
}
