import type { Metadata } from "next";
import Link from "next/link";
import { Nav } from "@/components/Nav";
import { getSession } from "@/lib/auth"; // <-- Importăm sesiunea
import "./globals.css";

export const metadata: Metadata = {
  title: "TickLy",
  description: "TickLy Support Dashboard",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // 1. Obținem sesiunea pe server (Server Component)
  const session = await getSession();

  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
        <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL@24,400,0" rel="stylesheet" />
      </head>
      <body className="font-display antialiased bg-background-light text-[#0e141b] min-h-screen flex flex-col" style={{ fontFamily: "'Inter', sans-serif" }}>
        <header className="sticky top-0 z-50 flex items-center justify-between border-b border-gray-200/90 bg-white/98 backdrop-blur-md px-6 py-3.5 shadow-card">
          <Link href="/" className="flex items-center gap-3 rounded-xl transition-all duration-200 hover:opacity-90 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/40 focus-visible:ring-offset-2">
            <div className="size-10 flex items-center justify-center bg-primary/10 rounded-xl text-primary shadow-inner">
              <span className="material-symbols-outlined text-2xl">confirmation_number</span>
            </div>
            <h2 className="text-xl font-bold tracking-tight text-[#0e141b]">TickLy</h2>
          </Link>
          
          <Nav user={session} />
        </header>
        <main className="flex-1 flex justify-center py-10 px-4 sm:px-6 lg:px-8">
          <div className="w-full max-w-[1100px]">{children}</div>
        </main>
      </body>
    </html>
  );
}