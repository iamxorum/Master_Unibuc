import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const SESSION_COOKIE = "tickly_session";

export function proxy(request: NextRequest) {
  const session = request.cookies.get(SESSION_COOKIE)?.value;
  const isLoggedIn = !!session;
  const isLoginPage = request.nextUrl.pathname === "/login";

  if (isLoginPage) {
    if (isLoggedIn) return NextResponse.redirect(new URL("/", request.url));
    return NextResponse.next();
  }

  if (!isLoggedIn) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/", "/login", "/tickets/:path*"],
};
