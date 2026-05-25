import { NextRequest, NextResponse } from "next/server";
import { compare } from "bcryptjs";
import { runQueryByUserType } from "@/lib/db";
import { setSession, type Session } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const email = typeof body.email === "string" ? body.email.trim() : "";
    const password = typeof body.password === "string" ? body.password : "";

    if (!email || !password) {
      return NextResponse.json({ error: "Email and password required" }, { status: 400 });
    }

    const [b2cResult, b2bResult, agentResult] = await Promise.allSettled([
      runQueryByUserType("B2C", async (conn) => {
        const result = await conn.execute(
          `SELECT client_id, password_hash, display_name FROM TICKLY.V_CLIENT_FIZIC_AUTH WHERE email = :email`,
          [email]
        );
        return { rows: result.rows as any[], type: "B2C", role: "client" };
      }),
      runQueryByUserType("B2B", async (conn) => {
        const result = await conn.execute(
          `SELECT client_id, password_hash, display_name FROM TICKLY.V_CLIENT_JURIDIC_AUTH WHERE email = :email`,
          [email]
        );
        return { rows: result.rows as any[], type: "B2B", role: "client" };
      }),
      runQueryByUserType("AGENT", async (conn) => {
        const result = await conn.execute(
          `SELECT agent_id, password_hash, display_name FROM TICKLY.V_AGENT_AUTH WHERE email = :email`,
          [email]
        );
        return { rows: result.rows as any[], type: "AGENT", role: "agent" };
      })
    ]);

    const checkPassword = async (promiseResult: any) => {
      if (promiseResult.status === "fulfilled" && promiseResult.value.rows.length > 0) {
        const user = promiseResult.value.rows[0];
        const isValid = await compare(password, String(user.PASSWORD_HASH));
        if (isValid) {
          return {
            role: promiseResult.value.role,
            id: Number(user.CLIENT_ID || user.AGENT_ID),
            email,
            name: String(user.DISPLAY_NAME),
            userType: promiseResult.value.type,
          } as Session;
        }
      }
      return null;
    };

    const found = (await checkPassword(b2cResult)) 
               || (await checkPassword(b2bResult)) 
               || (await checkPassword(agentResult));

    if (!found) {
      return NextResponse.json({ error: "Invalid email or password" }, { status: 401 });
    }

    await setSession(found);
    return NextResponse.json(found);

  } catch (e) {
    console.error("login critical error:", e);
    return NextResponse.json({ error: "Login failed" }, { status: 500 });
  }
}