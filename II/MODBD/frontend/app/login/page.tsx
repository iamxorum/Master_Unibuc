"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Login failed");
        return;
      }
      router.push("/");
      router.refresh();
    } catch {
      setError("Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col gap-10 w-full max-w-md mx-auto pt-6">
      <div className="text-center">
        <div className="inline-flex size-16 items-center justify-center rounded-2xl bg-primary/10 text-primary mb-5 shadow-inner">
          <span className="material-symbols-outlined text-[2rem]">login</span>
        </div>
        <h1 className="text-3xl font-bold tracking-tight text-[#0e141b]">Sign in</h1>
      </div>
      <div className="bg-white border border-gray-200/90 rounded-2xl shadow-card-lg p-6 sm:p-8">
        <form onSubmit={handleSubmit} className="flex flex-col gap-5">
          {error && (
            <div className="rounded-xl bg-red-50 border border-red-100 text-red-700 text-sm px-4 py-3 flex items-center gap-2.5">
              <span className="material-symbols-outlined text-lg shrink-0">error</span>
              {error}
            </div>
          )}
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1.5">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50/60 text-[#0e141b] placeholder:text-gray-400 transition-colors focus:bg-white focus:border-primary/40 focus:ring-2 focus:ring-primary/10"
              placeholder="you@example.com"
            />
          </div>
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1.5">
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50/60 text-[#0e141b] placeholder:text-gray-400 transition-colors focus:bg-white focus:border-primary/40 focus:ring-2 focus:ring-primary/10"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 px-4 bg-primary hover:bg-primary-hover text-white font-semibold rounded-xl shadow-card transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.99] focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/40 focus-visible:ring-offset-2"
          >
            {loading ? (
              <span className="inline-flex items-center justify-center gap-2">
                <span className="material-symbols-outlined text-lg animate-spin">progress_activity</span>
                Signing in…
              </span>
            ) : (
              "Sign in"
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
