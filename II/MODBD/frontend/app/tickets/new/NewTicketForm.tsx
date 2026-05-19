"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

type MetaData = {
  priorities: { PRIORITATE_ID: number; NUME: string }[];
  categories: { CATEGORIE_ID: number; NUME: string }[];
};

type ClientData = {
  ID: string;
  NUME: string;
};

interface NewTicketFormProps {
  session: any;
}

export default function NewTicketForm({ session }: NewTicketFormProps) {
  const router = useRouter();
  const isAgent = session?.role === "agent";

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [meta, setMeta] = useState<MetaData | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [clients, setClients] = useState<ClientData[]>([]);
  const [fetchingClients, setFetchingClients] = useState(false);

  const [formData, setFormData] = useState({
    titlu: "",
    descriere: "",
    prioritate_id: "",
    categorie_id: "",
    client_type: "B2C", 
    client_id: "",      
  });

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

  useEffect(() => {
    if (!isAgent) return;

    setFetchingClients(true);
    fetch(`/api/clients?type=${formData.client_type}`)
      .then((r) => r.json())
      .then((data) => {
        if (data.error) throw new Error(data.error);
        setClients(data);
        setFormData((prev) => ({ ...prev, client_id: "" })); 
      })
      .catch((e) => console.error("Eroare la aducerea clienților:", e))
      .finally(() => setFetchingClients(false));
  }, [isAgent, formData.client_type]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.titlu || !formData.categorie_id || !formData.prioritate_id) {
      alert("Te rog completează câmpurile obligatorii (Subiect, Categorie, Prioritate).");
      return;
    }

    if (isAgent && !formData.client_id) {
      alert("Te rog selectează clientul pentru care creezi ticketul.");
      return;
    }

    setSaving(true);
    try {
      const res = await fetch("/api/tickets", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...formData, is_agent_creation: isAgent }),
      });

      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "A apărut o eroare.");

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

  const labelStyle = "block text-sm font-semibold text-gray-700 mb-1.5";
  const inputStyle = "w-full rounded-xl border border-gray-200 px-4 py-3 text-sm transition-all outline-none bg-white focus:border-primary";
  
  // Am înlocuit appearance-none cu proprietăți native cross-browser de fundal (săgeată SVG curată)
  const selectStyle = `${inputStyle} pr-10 cursor-pointer`;

  return (
    <div className="max-w-3xl mx-auto">
      <div className="mb-8">
        <Link href="/" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-primary mb-4">
          <span className="material-symbols-outlined text-[18px]">arrow_back</span>
          Înapoi la Dashboard
        </Link>
        <h1 className="text-3xl font-bold text-[#0e141b]">Deschide un Ticket Nou</h1>
        <p className="text-gray-500 mt-2">Descrie problema ta și te vom ajuta în cel mai scurt timp.</p>
      </div>

      <form onSubmit={handleSubmit} className="bg-white p-8 rounded-2xl border border-gray-100 space-y-6 shadow-sm">
        
        {/* Sectiunea On-Behalf (Agent) */}
        {isAgent && (
          <div className="p-5 bg-blue-50/40 border border-blue-100 rounded-xl space-y-4 mb-6">
            <h3 className="text-sm font-bold text-blue-800 flex items-center gap-2">
              <span className="material-symbols-outlined text-lg">support_agent</span>
              Creare Ticket "On Behalf"
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className={labelStyle}>Tip Client</label>
                <select name="client_type" value={formData.client_type} onChange={handleChange} className={selectStyle}>
                  <option value="B2C">Persoană Fizică (B2C)</option>
                  <option value="B2B">Persoană Juridică (B2B)</option>
                </select>
              </div>

              <div>
                <label className={labelStyle}>Selectează Clientul</label>
                <select name="client_id" value={formData.client_id} onChange={handleChange} disabled={fetchingClients} required={isAgent} className={selectStyle}>
                  <option value="">{fetchingClients ? "Se încarcă..." : "Alege clientul..."}</option>
                  {clients.map((c) => (
                    <option key={c.ID} value={c.ID}>{c.NUME} ({c.ID})</option>
                  ))}
                </select>
              </div>
            </div>
          </div>
        )}

        <div>
          <label htmlFor="titlu" className={labelStyle}>
            Subiect <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="titlu"
            name="titlu"
            value={formData.titlu}
            onChange={handleChange}
            placeholder="Ex: Problemă la conectare VPN"
            className={inputStyle}
            required
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label htmlFor="categorie_id" className={labelStyle}>
              Categorie <span className="text-red-500">*</span>
            </label>
            <select id="categorie_id" name="categorie_id" value={formData.categorie_id} onChange={handleChange} className={selectStyle} required>
              <option value="">Alege categoria...</option>
              {meta?.categories.map((c) => (
                <option key={c.CATEGORIE_ID} value={c.CATEGORIE_ID}>{c.NUME}</option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="prioritate_id" className={labelStyle}>
              Prioritate <span className="text-red-500">*</span>
            </label>
            <select id="prioritate_id" name="prioritate_id" value={formData.prioritate_id} onChange={handleChange} className={selectStyle} required>
              <option value="">Alege prioritatea...</option>
              {meta?.priorities.map((p) => (
                <option key={p.PRIORITATE_ID} value={p.PRIORITATE_ID}>{p.NUME}</option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <label htmlFor="descriere" className={labelStyle}>Descriere detaliată</label>
          <textarea
            id="descriere"
            name="descriere"
            value={formData.descriere}
            onChange={handleChange}
            rows={6}
            placeholder="Oferă cât mai multe detalii despre problema întâmpinată..."
            className={`${inputStyle} resize-y`}
          />
        </div>

        <div className="pt-4 flex items-center justify-end gap-4">
          <Link href="/" className="px-5 py-2.5 text-sm font-semibold text-gray-600 hover:bg-gray-100 rounded-xl transition-colors">
            Anulează
          </Link>
          <button
            type="submit"
            disabled={saving}
            className="rounded-xl bg-primary px-8 py-2.5 text-sm font-semibold text-white hover:bg-primary-hover disabled:opacity-70 disabled:cursor-not-allowed transition-all active:scale-[0.98]"
          >
            {saving ? "Se trimite..." : "Trimite Ticket"}
          </button>
        </div>
      </form>
    </div>
  );
}