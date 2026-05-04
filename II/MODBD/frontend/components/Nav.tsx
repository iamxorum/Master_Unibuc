"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

// 1. Definim tipul pentru props
type NavProps = {
  user?: {
    id: number;
    role: string;
    email: string;
    name: string;
  } | null;
};

// 2. Destructurăm 'user' din props
export function Nav({ user }: NavProps) {
  const pathname = usePathname();
  const router = useRouter();
  const isLogin = pathname === "/login";

  // 3. Verificăm dacă este agent
  const isAgent = user?.role === "agent";

  if (isLogin) return null;

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  return (
    <nav className="flex items-center gap-2">
      <Link
        href="/"
        className={
          pathname === "/"
            ? "text-primary bg-primary/10 px-4 py-2.5 rounded-xl text-sm font-semibold transition-colors duration-200 shadow-inner"
            : "text-gray-600 hover:bg-gray-100 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors duration-200"
        }
      >
        <span className="material-symbols-outlined text-[18px] align-middle mr-1.5">dashboard</span>
        Dashboard
      </Link>

      {/* 4. Afișăm link-ul de Rapoarte DOAR dacă userul este Agent */}
      {isAgent && (
        <Link
          href="/reports"
          className={
            pathname === "/reports"
              ? "text-primary bg-primary/10 px-4 py-2.5 rounded-xl text-sm font-semibold transition-colors duration-200 shadow-inner"
              : "text-gray-600 hover:bg-gray-100 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors duration-200"
          }
        >
          <span className="material-symbols-outlined text-[18px] align-middle mr-1.5">analytics</span>
          Rapoarte DW
        </Link>
      )}

      <button
        type="button"
        onClick={handleLogout}
        className="text-gray-600 hover:bg-gray-100 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors duration-200 border border-transparent hover:border-gray-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 focus-visible:ring-offset-2"
      >
        <span className="material-symbols-outlined text-[18px] align-middle mr-1.5">logout</span>
        Logout
      </button>
    </nav>
  );
}