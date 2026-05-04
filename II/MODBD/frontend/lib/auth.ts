import { cookies } from "next/headers";
import { type UserType } from "./constants";

const SESSION_COOKIE = "tickly_session";
const SESSION_MAX_AGE = 60 * 60 * 24; // 24h

export type Session = {
  role: "client" | "agent";
  id: number;
  email: string;
  name: string;
  userType?: UserType; // B2C, B2B for clients; AGENT for agents
};

export async function getSession(): Promise<Session | null> {
  const cookieStore = await cookies();
  const raw = cookieStore.get(SESSION_COOKIE)?.value;
  if (!raw) return null;
  try {
    const data = JSON.parse(decodeURIComponent(raw)) as Session;
    if (data.role && data.id && data.email && data.name) return data;
  } catch {
    return null;
  }
  return null;
}

export async function setSession(session: Session) {
  const cookieStore = await cookies();
  cookieStore.set(SESSION_COOKIE, encodeURIComponent(JSON.stringify(session)), {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: SESSION_MAX_AGE,
    path: "/",
  });
}

export async function clearSession() {
  const cookieStore = await cookies();
  cookieStore.delete(SESSION_COOKIE);
}
