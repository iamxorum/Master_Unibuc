import NextAuth, { DefaultSession } from "next-auth";

declare module "next-auth" {
  interface Session {
    id?: string;
    role?: string;
    userType?: string;
    user: {
      id?: string;
      role?: string;
    } & DefaultSession["user"];
  }

  interface User {
    role?: string;
    userType?: string;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id?: string;
    role?: string;
    userType?: string;
  }
}