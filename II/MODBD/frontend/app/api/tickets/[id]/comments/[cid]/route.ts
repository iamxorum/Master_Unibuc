import { NextResponse } from "next/server";
import { runQueryByUserType, getTableName } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string; cid: string }> }
) {
  const ticketId = Number((await params).id);
  const cidRaw = (await params).cid as string;
  if (!Number.isInteger(ticketId) || ticketId < 1 || !cidRaw) {
    return NextResponse.json({ error: "Invalid ticket or comment id" }, { status: 400 });
  }

  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  // Determine user type from session or default to B2C
  const userType = (session.userType || "B2C") as "B2C" | "B2B" | "AGENT";

  const match = /^(client|agent)-(\d+)$/.exec(cidRaw.trim());
  if (!match) {
    return NextResponse.json({ error: "Invalid comment id format" }, { status: 400 });
  }
  const [, source, commentIdStr] = match;
  const commentId = Number(commentIdStr);
  if (!Number.isInteger(commentId) || commentId < 1) {
    return NextResponse.json({ error: "Invalid comment id" }, { status: 400 });
  }

  if (session.role !== source) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let body: { content?: string };
  try {
    body = (await request.json()) as { content?: string };
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }
  const content = typeof body.content === "string" ? body.content.trim() : "";
  if (!content) {
    return NextResponse.json({ error: "Content is required" }, { status: 400 });
  }

  try {
    const updateResult = await runQueryByUserType(userType, async (conn) => {
      const commentClientTable = getTableName(userType, "comment_client");
      const commentAgentTable = getTableName(userType, "comment_agent");
      const ticketTable = getTableName(userType, "ticket");

      if (source === "client") {
        return await conn.execute(
          `UPDATE ${commentClientTable} SET content = :content
           WHERE comment_id = :comment_id AND ticket_id = :ticket_id AND client_id = :client_id`,
          { content, comment_id: commentId, ticket_id: ticketId, client_id: session.id }
        );
      } else {
        return await conn.execute(
          `UPDATE ${commentAgentTable} SET content = :content
           WHERE comment_id = :comment_id AND ticket_id = :ticket_id AND agent_id = :agent_id`,
          { content, comment_id: commentId, ticket_id: ticketId, agent_id: session.id }
        );
      }
    });

    const updated = Number((updateResult as { rowsAffected?: number }).rowsAffected) > 0;
    if (!updated) {
      return NextResponse.json({ error: "Comment not found or you cannot edit it" }, { status: 404 });
    }

    await runQueryByUserType(userType, async (conn) => {
      const ticketTable = getTableName(userType, "ticket");
      await conn.execute(
        `UPDATE ${ticketTable} SET data_ultima_actualizare = SYSDATE WHERE ticket_id = :tid`,
        { tid: ticketId }
      );
    });

    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("comment patch", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Failed to update comment" },
      { status: 500 }
    );
  }
}
