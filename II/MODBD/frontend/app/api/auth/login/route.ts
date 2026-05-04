import { NextRequest, NextResponse } from "next/server";
import { compare } from "bcryptjs";
import { runQueryByUserType } from "@/lib/db";
import { setSession } from "@/lib/auth";
import { getTableName } from "@/lib/constants";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const email = typeof body.email === "string" ? body.email.trim() : "";
    const password = typeof body.password === "string" ? body.password : "";
    if (!email || !password) {
      return NextResponse.json({ error: "Email and password required" }, { status: 400 });
    }

    // Try B2C first (sv1)
    let found = await runQueryByUserType("B2C", async (conn) => {
      const clientTable = getTableName("B2C", "client");
      const result = await conn.execute(
        `SELECT client_id, password_hash, prenume||' '||nume AS display_name FROM ${clientTable} WHERE email = :email`,
        [email]
      );
      const rows = (result.rows as Record<string, unknown>[]) || [];
      if (rows.length > 0) {
        const row = rows[0];
        const hash = row.PASSWORD_HASH;
        const hashStr = hash != null ? String(hash) : "";
        if (hashStr) {
          const ok = await compare(password, hashStr);
          if (ok)
            return {
              role: "client" as const,
              id: Number(row.CLIENT_ID),
              email,
              name: String(row.DISPLAY_NAME || email),
              userType: "B2C" as const,
            };
        }
        return null;
      }
      return null;
    }).catch(() => null);

    // If not found in B2C, try B2B (sv2)
    if (!found) {
      found = await runQueryByUserType("B2B", async (conn) => {
        const clientTable = getTableName("B2B", "client");
        const result = await conn.execute(
          `SELECT client_id, password_hash, denumire AS display_name FROM ${clientTable} WHERE email = :email`,
          [email]
        );
        const rows = (result.rows as Record<string, unknown>[]) || [];
        if (rows.length > 0) {
          const row = rows[0];
          const hash = row.PASSWORD_HASH;
          const hashStr = hash != null ? String(hash) : "";
          if (hashStr) {
            const ok = await compare(password, hashStr);
            if (ok)
              return {
                role: "client" as const,
                id: Number(row.CLIENT_ID),
                email,
                name: String(row.DISPLAY_NAME || email),
                userType: "B2B" as const,
              };
          }
          return null;
        }
        return null;
      }).catch(() => null);
    }

    // If not found in clients, try Agent (sv3)
    if (!found) {
      found = await runQueryByUserType("AGENT", async (conn) => {
        const result = await conn.execute(
          `SELECT agent_id, password_hash, prenume||' '||nume AS display_name FROM TICKLY.agent_sec WHERE email = :email`,
          [email]
        );
        const rows = (result.rows as Record<string, unknown>[]) || [];
        if (rows.length > 0) {
          const row = rows[0];
          const hash = row.PASSWORD_HASH;
          const hashStr = hash != null ? String(hash) : "";
          if (hashStr) {
            const ok = await compare(password, hashStr);
            if (ok)
              return {
                role: "agent" as const,
                id: Number(row.AGENT_ID),
                email,
                name: String(row.DISPLAY_NAME || email),
                userType: "AGENT" as const,
              };
          }
          return null;
        }
        return null;
      }).catch(() => null);
    }

    if (!found) {
      return NextResponse.json({ error: "Invalid email or password" }, { status: 401 });
    }

    await setSession({
      role: found.role,
      id: found.id,
      email: found.email,
      name: found.name,
      userType: found.userType,
    });
    return NextResponse.json({
      role: found.role,
      id: found.id,
      email: found.email,
      name: found.name,
      userType: found.userType,
    });
  } catch (e) {
    console.error("login", e);
    return NextResponse.json({ error: "Login failed" }, { status: 500 });
  }
}
