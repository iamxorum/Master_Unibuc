"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

type MetaData = {
  departments: { DEPARTAMENT_ID: number; NUME: string }[];
  priorities: { PRIORITATE_ID: number; NUME: string }[];
  categories: { CATEGORIE_ID: number; NUME: string }[];
};

export default function NewTicketPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [meta, setMeta] = useState<MetaData | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    titlu: "",
    descriere: "",
    departament_id: "",
    prioritate_id: "",
    categorie_id: "",
  });

  // Fetch dropdown options
  useEffect(() => {
    fetch("/api/tickets/meta")
      .then((r) => r.json())
      .then((data) => {
        if (data.error) throw new Error(data.error);
        setMeta(data);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.titlu || !formData.departament_id || !formData.prioritate_id) {
      alert("Te rog completează câmpurile obligatorii.");
      return;
    }

    setSaving(true);
    try {
      const res = await fetch("/api/tickets", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const json = await res.json();

      if (!res.ok) throw new Error(json.error || "A apărut o eroare.");

      // Redirect la pagina ticketului creat
      router.push(`/tickets/${json.ticket_id}`);
      router.refresh();
    } catch (e: any) {
      alert(e.message);
      setSaving(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <span className="material-symbols-outlined animate-spin text-4xl text-primary">progress_activity</span>
      </div>
    );
  }

  if (error) {
    return <div className="p-6 text-red-600">Eroare: {error}</div>;
  }

  return (
    <div className="max-w-3xl mx-auto">
      {/* Breadcrumbs & Header */}
      <div className="mb-8">
        <Link
          href="/"
          className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-primary transition-colors mb-4"
        >
          <span className="material-symbols-outlined text-[18px]">arrow_back</span>
          Înapoi la Dashboard
        </Link>
        <h1 className="text-3xl font-bold text-[#0e141b]">Deschide un Ticket Nou</h1>
        <p className="text-gray-500 mt-2">Descrie problema ta și te vom ajuta în cel mai scurt timp.</p>
      </div>

      <form onSubmit={handleSubmit} className="bg-white p-8 rounded-2xl shadow-card border border-gray-100 space-y-6">
        {/* Titlu */}
        <div>
          <label htmlFor="titlu" className="block text-sm font-semibold text-gray-700 mb-1.5">
            Subiect <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="titlu"
            name="titlu"
            value={formData.titlu}
            onChange={handleChange}
            placeholder="Ex: Problemă la conectare VPN"
            className="w-full rounded-xl border border-gray-200 px-4 py-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all"
            required
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Departament */}
          <div>
            <label htmlFor="departament_id" className="block text-sm font-semibold text-gray-700 mb-1.5">
              Departament <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                id="departament_id"
                name="departament_id"
                value={formData.departament_id}
                onChange={handleChange}
                className="w-full appearance-none rounded-xl border border-gray-200 bg-white px-4 py-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all"
                required
              >
                <option value="">Alege departamentul...</option>
                {meta?.departments.map((d) => (
                  <option key={d.DEPARTAMENT_ID} value={d.DEPARTAMENT_ID}>
                    {d.NUME}
                  </option>
                ))}
              </select>
              <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
                expand_more
              </span>
            </div>
          </div>

          {/* Prioritate */}
          <div>
            <label htmlFor="prioritate_id" className="block text-sm font-semibold text-gray-700 mb-1.5">
              Prioritate <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                id="prioritate_id"
                name="prioritate_id"
                value={formData.prioritate_id}
                onChange={handleChange}
                className="w-full appearance-none rounded-xl border border-gray-200 bg-white px-4 py-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all"
                required
              >
                <option value="">Alege prioritatea...</option>
                {meta?.priorities.map((p) => (
                  <option key={p.PRIORITATE_ID} value={p.PRIORITATE_ID}>
                    {p.NUME}
                  </option>
                ))}
              </select>
              <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
                expand_more
              </span>
            </div>
          </div>
        </div>

        {/* Categorie */}
        <div>
          <label htmlFor="categorie_id" className="block text-sm font-semibold text-gray-700 mb-1.5">
            Categorie (Opțional)
          </label>
          <div className="relative">
            <select
              id="categorie_id"
              name="categorie_id"
              value={formData.categorie_id}
              onChange={handleChange}
              className="w-full appearance-none rounded-xl border border-gray-200 bg-white px-4 py-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all"
            >
              <option value="">Alege categoria...</option>
              {meta?.categories.map((c) => (
                <option key={c.CATEGORIE_ID} value={c.CATEGORIE_ID}>
                  {c.NUME}
                </option>
              ))}
            </select>
            <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
              expand_more
            </span>
          </div>
        </div>

        {/* Descriere */}
        <div>
          <label htmlFor="descriere" className="block text-sm font-semibold text-gray-700 mb-1.5">
            Descriere detaliată
          </label>
          <textarea
            id="descriere"
            name="descriere"
            value={formData.descriere}
            onChange={handleChange}
            rows={6}
            placeholder="Oferă cât mai multe detalii despre problema întâmpinată..."
            className="w-full rounded-xl border border-gray-200 px-4 py-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all resize-y"
          />
        </div>

        {/* Actions */}
        <div className="pt-4 flex items-center justify-end gap-3">
          <Link
            href="/"
            className="rounded-xl px-6 py-2.5 text-sm font-semibold text-gray-600 hover:bg-gray-100 transition-colors"
          >
            Anulează
          </Link>
          <button
            type="submit"
            disabled={saving}
            className="rounded-xl bg-primary px-8 py-2.5 text-sm font-semibold text-white shadow-lg shadow-primary/30 hover:bg-primary-hover hover:shadow-primary/40 disabled:opacity-70 disabled:cursor-not-allowed transition-all active:scale-[0.98]"
          >
            {saving ? "Se trimite..." : "Trimite Ticket"}
          </button>
        </div>
      </form>
    </div>
  );
}