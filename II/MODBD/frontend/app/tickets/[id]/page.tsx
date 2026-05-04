"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

type TicketDetail = {
  ticket: {
    ticket_id: number;
    status_id: number | null;
    prioritate_id: number | null;
    departament_id: number | null;
    categorie_id: number | null;
    assigned_agent_id: number | null;
    titlu: string;
    descriere: string | null;
    data_creare: string;
    data_rezolvare: string | null;
    data_inchidere: string | null;
    status_nume: string;
    prioritate_nume: string;
    departament_nume: string;
    categorie_nume: string | null;
    client_email: string;
    client_nume: string | null;
    agent_nume: string | null;
    agent_email: string | null;
  };
  comments: {
    comment_id: number;
    content: string;
    created_date: string;
    source: string;
    author_name: string;
    author_id?: number | null;
    is_internal?: boolean;
  }[];
  timeline: Array<
    | { type: "comment"; comment_id: number; content: string; created_date: string; source: string; author_name: string; author_id?: number | null; is_internal?: boolean }
    | { type: "history"; history_id: number; event_type: string; created_date: string; author_name: string; display_text: string | null }
  >;
  attachments: {
    atasament_id: number;
    file_name: string;
    file_path: string;
    file_size: number | null;
    file_type: string | null;
    upload_date: string;
    uploader_type: string;
  }[];
};

type Lookup = {
  statuses: { id: number; nume: string }[];
  priorities: { id: number; nume: string }[];
  departments: { id: number; nume: string }[];
  categories: { id: number; nume: string }[];
  agents: { id: number; nume: string; email: string }[];
};

function formatDate(v: string | null) {
  if (!v) return "—";
  const d = new Date(v);
  return isNaN(d.getTime()) ? v : d.toLocaleString("ro-RO", { dateStyle: "short", timeStyle: "short" });
}

function formatBytes(n: number | null) {
  if (n == null) return "—";
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

function statusClass(s: string) {
  if (s === "Rezolvat" || s === "Inchis") return "bg-green-100 text-green-800";
  if (s === "In desfasurare" || s === "In asteptare") return "bg-blue-100 text-blue-800";
  return "bg-gray-100 text-gray-800";
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-0.5 py-2.5 border-b border-gray-100 last:border-0">
      <span className="text-xs font-medium uppercase tracking-wider text-gray-500">{label}</span>
      <span className="text-sm text-[#0e141b] font-medium">{value}</span>
    </div>
  );
}

type EditField = "prioritate" | "departament" | "categorie" | "agent" | null;

function InfoRowEditable({
  label,
  value,
  isEditing,
  onStartEdit,
  onEndEdit,
  children,
}: {
  label: string;
  value: React.ReactNode;
  isEditing: boolean;
  onStartEdit: () => void;
  onEndEdit: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="flex flex-col gap-0.5 py-2.5 border-b border-gray-100 last:border-0">
      <span className="text-xs font-medium uppercase tracking-wider text-gray-500">{label}</span>
      {isEditing ? (
        <div className="mt-0.5" onBlur={onEndEdit}>
          {children}
        </div>
      ) : (
        <button
          type="button"
          onClick={onStartEdit}
          className="text-left text-sm font-medium text-[#0e141b] hover:bg-gray-50 rounded-lg px-2 py-1 -mx-2 transition-colors w-full flex items-center justify-between gap-2"
        >
          {value}
          <span className="material-symbols-outlined text-base text-gray-400">expand_more</span>
        </button>
      )}
    </div>
  );
}

function TicketView({
  data,
  userRole,
  userId,
  lookup,
  onRefresh,
}: {
  data: TicketDetail;
  userRole: "client" | "agent";
  userId: number | null;
  lookup: Lookup | null;
  onRefresh: () => void;
}) {
  const { ticket, comments, attachments } = data;
  const timeline = data.timeline ?? comments.map((c) => ({ type: "comment" as const, ...c }));
  const commentItems = timeline.filter((t): t is Extract<typeof timeline[0], { type: "comment" }> => t.type === "comment");
  const historyItems = timeline.filter((t): t is Extract<typeof timeline[0], { type: "history" }> => t.type === "history");
  const hasAgent = ticket.agent_nume != null || ticket.agent_email != null;
  const isAgent = userRole === "agent";
  const [saving, setSaving] = useState(false);
  const [commentText, setCommentText] = useState("");
  const [commentSending, setCommentSending] = useState(false);
  const [commentInternal, setCommentInternal] = useState(false);
  const [editField, setEditField] = useState<EditField>(null);
  const [editingTitlu, setEditingTitlu] = useState(false);
  const [titluDraft, setTitluDraft] = useState(ticket.titlu);
  const [editingDescriere, setEditingDescriere] = useState(false);
  const [descriereDraft, setDescriereDraft] = useState(ticket.descriere ?? "");
  const [editingCommentId, setEditingCommentId] = useState<string | null>(null);
  const [editingCommentContent, setEditingCommentContent] = useState("");
  const ticketId = ticket.ticket_id;

  useEffect(() => {
    if (!editingTitlu) setTitluDraft(ticket.titlu);
  }, [ticket.titlu, editingTitlu]);
  useEffect(() => {
    if (!editingDescriere) setDescriereDraft(ticket.descriere ?? "");
  }, [ticket.descriere, editingDescriere]);

  const handlePatch = useCallback(
    async (payload: { descriere?: string | null; status_id?: number; prioritate_id?: number; departament_id?: number; categorie_id?: number | null; assigned_agent_id?: number | null }) => {
      setSaving(true);
      try {
        const res = await fetch("/api/tickets/" + ticketId, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const j = await res.json().catch(() => ({}));
          throw new Error((j as { error?: string }).error || "Update failed");
        }
        onRefresh();
      } catch (e) {
        console.error(e);
        alert(e instanceof Error ? e.message : "Update failed");
      } finally {
        setSaving(false);
      }
    },
    [ticketId, onRefresh]
  );

  const handleStatusChange = useCallback(
    (statusId: number) => () => {
      if (saving) return;
      handlePatch({ status_id: statusId });
    },
    [handlePatch, saving]
  );

  const handleCommentSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      const text = commentText.trim();
      if (!text || commentSending) return;
      setCommentSending(true);
      try {
        const res = await fetch("/api/tickets/" + ticketId + "/comments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ content: text, is_internal: isAgent ? commentInternal : undefined }),
        });
        if (!res.ok) {
          const j = await res.json().catch(() => ({}));
          throw new Error((j as { error?: string }).error || "Failed to add comment");
        }
        setCommentText("");
        onRefresh();
      } catch (e) {
        console.error(e);
        alert(e instanceof Error ? e.message : "Failed to add comment");
      } finally {
        setCommentSending(false);
      }
    },
    [ticketId, commentText, commentSending, commentInternal, isAgent, onRefresh]
  );

  const handleSaveTitlu = useCallback(() => {
    const newVal = titluDraft.trim();
    if (!newVal) {
      alert("Titlul nu poate fi gol.");
      return;
    }
    if (newVal === ticket.titlu) {
      setEditingTitlu(false);
      return;
    }
    setSaving(true);
    fetch("/api/tickets/" + ticketId, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ titlu: newVal }),
    })
      .then((r) => {
        if (!r.ok) return r.json().then((j: { error?: string }) => Promise.reject(new Error(j.error || "Update failed")));
        onRefresh();
        setEditingTitlu(false);
      })
      .catch((e) => {
        console.error(e);
        alert(e instanceof Error ? e.message : "Update failed");
      })
      .finally(() => setSaving(false));
  }, [ticketId, ticket.titlu, titluDraft, onRefresh]);

  const handleSaveDescriere = useCallback(() => {
    const newVal = descriereDraft.trim() || null;
    if (newVal === (ticket.descriere ?? "")) {
      setEditingDescriere(false);
      return;
    }
    setSaving(true);
    fetch("/api/tickets/" + ticketId, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ descriere: newVal || null }),
    })
      .then((r) => {
        if (!r.ok) return r.json().then((j: { error?: string }) => Promise.reject(new Error(j.error || "Update failed")));
        onRefresh();
        setEditingDescriere(false);
      })
      .catch((e) => {
        console.error(e);
        alert(e instanceof Error ? e.message : "Update failed");
      })
      .finally(() => setSaving(false));
  }, [ticketId, ticket.descriere, descriereDraft, onRefresh]);

  const handleSaveComment = useCallback(
    (cid: string, content: string) => {
      if (!content.trim()) return;
      setSaving(true);
      fetch("/api/tickets/" + ticketId + "/comments/" + cid, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content: content.trim() }),
      })
        .then((r) => {
          if (!r.ok) return r.json().then((j: { error?: string }) => Promise.reject(new Error(j.error || "Update failed")));
          setEditingCommentId(null);
          onRefresh();
        })
        .catch((e) => {
          console.error(e);
          alert(e instanceof Error ? e.message : "Update failed");
        })
        .finally(() => setSaving(false));
    },
    [ticketId, onRefresh]
  );

  const canEditComment = useCallback(
    (item: { type: string; source?: string; author_id?: number | null }) =>
      item.type === "comment" && item.source === userRole && userId != null && item.author_id === userId,
    [userRole, userId]
  );

  return (
    <div className="flex flex-col gap-8">
      <div className="flex items-center gap-2 text-sm">
        <Link href="/" className="text-gray-500 hover:text-primary transition-colors font-medium flex items-center gap-1.5 rounded-lg py-1 pr-1 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 focus-visible:ring-offset-1">
          <span className="material-symbols-outlined text-[18px]">arrow_back</span>
          Dashboard
        </Link>
        <span className="material-symbols-outlined text-gray-300 text-[16px]">chevron_right</span>
        <span className="text-[#0e141b] font-semibold truncate">#{ticket.ticket_id} {ticket.titlu}</span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 lg:gap-8">
        <div className="min-w-0 flex flex-col gap-6">
          {/* Card titlu + descriere */}
          <div className="bg-white border border-gray-200/90 rounded-2xl shadow-card-lg overflow-hidden">
            <div className="px-6 py-5">
              {editingTitlu ? (
                <div className="space-y-2">
                  <input
                    type="text"
                    value={titluDraft}
                    onChange={(e) => setTitluDraft(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl border border-gray-200 bg-gray-50/60 text-xl font-bold text-[#0e141b] focus:bg-white focus:border-primary/40"
                    placeholder="Titlul ticketului"
                    disabled={saving}
                  />
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={handleSaveTitlu}
                      disabled={saving}
                      className="px-4 py-2 bg-primary hover:bg-primary-hover text-white text-sm font-semibold rounded-xl disabled:opacity-50"
                    >
                      Salvează
                    </button>
                    <button
                      type="button"
                      onClick={() => { setEditingTitlu(false); setTitluDraft(ticket.titlu); }}
                      disabled={saving}
                      className="px-4 py-2 bg-gray-100 text-gray-700 text-sm font-medium rounded-xl hover:bg-gray-200"
                    >
                      Anulare
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  <h1 className="text-xl font-bold text-[#0e141b]">{ticket.titlu}</h1>
                  <button
                    type="button"
                    onClick={() => { setEditingTitlu(true); setTitluDraft(ticket.titlu); }}
                    className="mt-2 text-sm font-medium text-gray-600 hover:text-gray-800 flex items-center gap-1.5"
                  >
                    <span className="material-symbols-outlined text-lg">edit</span>
                    Editează titlul
                  </button>
                </>
              )}
              <div className="mt-4 pt-4 border-t border-gray-100">
                {editingDescriere ? (
                  <div className="space-y-2">
                    <textarea
                      value={descriereDraft}
                      onChange={(e) => setDescriereDraft(e.target.value)}
                      rows={5}
                      className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50/60 text-sm text-[#0e141b] focus:bg-white focus:border-primary/40 resize-y"
                      disabled={saving}
                    />
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={handleSaveDescriere}
                        disabled={saving}
                        className="px-4 py-2 bg-primary hover:bg-primary-hover text-white text-sm font-semibold rounded-xl disabled:opacity-50"
                      >
                        Salvează
                      </button>
                      <button
                        type="button"
                        onClick={() => { setEditingDescriere(false); setDescriereDraft(ticket.descriere ?? ""); }}
                        disabled={saving}
                        className="px-4 py-2 bg-gray-100 text-gray-700 text-sm font-medium rounded-xl hover:bg-gray-200"
                      >
                        Anulare
                      </button>
                    </div>
                  </div>
                ) : (
                  <>
                    {ticket.descriere ? (
                      <p className="text-sm text-gray-700 whitespace-pre-wrap leading-relaxed">{ticket.descriere}</p>
                    ) : (
                      <p className="text-sm text-gray-500 italic">Fără descriere</p>
                    )}
                    <button
                      type="button"
                      onClick={() => { setEditingDescriere(true); setDescriereDraft(ticket.descriere ?? ""); }}
                      className="mt-2 text-sm font-medium text-gray-600 hover:text-gray-800 flex items-center gap-1.5"
                    >
                      <span className="material-symbols-outlined text-lg">edit</span>
                      Editează descrierea
                    </button>
                  </>
                )}
              </div>
            </div>
          </div>

          {/* Card Comentarii + formular */}
          <div className="bg-white border border-gray-200/90 rounded-2xl shadow-card-lg overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 bg-primary/5">
              <h2 className="text-sm font-semibold text-[#0e141b] flex items-center gap-2">
                <span className="material-symbols-outlined text-lg text-primary">chat_bubble_outline</span>
                Comentarii
                {commentItems.length > 0 && (
                  <span className="text-xs font-normal text-gray-500">({commentItems.length})</span>
                )}
              </h2>
            </div>
            <div className="px-6 py-5">
              {commentItems.length === 0 ? (
                <p className="text-sm text-gray-500 flex items-center gap-2.5 py-2">
                  <span className="material-symbols-outlined text-lg text-gray-400">forum</span>
                  Niciun comentariu încă.
                </p>
              ) : (
                <ul className="space-y-4">
                  {commentItems.map((item) => (
                      <li key={item.source + "-" + item.comment_id} className="flex gap-3">
                        <div className={"shrink-0 size-10 rounded-full flex items-center justify-center text-xs font-bold " + (item.source === "agent" ? "bg-primary/10 text-primary" : "bg-gray-100 text-gray-600")}>
                          {item.source === "agent" ? "A" : "C"}
                        </div>
                        <div className={"min-w-0 flex-1 rounded-xl px-4 py-3 border " + (item.is_internal ? "bg-amber-50/80 border-amber-200/60" : "bg-gray-50/80 border-gray-100")}>
                          <div className="flex items-baseline gap-2 flex-wrap">
                            <span className="text-sm font-medium text-[#0e141b]">{item.author_name}</span>
                            <span className="text-xs text-gray-500">{item.source === "agent" ? "Agent" : "Client"}</span>
                            {item.is_internal && (
                              <span className="text-xs font-medium text-amber-700 bg-amber-100 px-1.5 py-0.5 rounded">Intern</span>
                            )}
                            <span className="text-xs text-gray-400 tabular-nums">{formatDate(item.created_date)}</span>
                            {canEditComment(item) && editingCommentId !== item.source + "-" + item.comment_id && (
                              <button
                                type="button"
                                onClick={() => { setEditingCommentId(item.source + "-" + item.comment_id); setEditingCommentContent(item.content); }}
                                className="text-xs font-medium text-gray-600 hover:text-gray-800 ml-auto"
                              >
                                Editează
                              </button>
                            )}
                          </div>
                          {editingCommentId === item.source + "-" + item.comment_id ? (
                            <div className="mt-2 space-y-2">
                              <textarea
                                value={editingCommentContent}
                                onChange={(e) => setEditingCommentContent(e.target.value)}
                                rows={3}
                                className="w-full px-3 py-2 rounded-lg border border-gray-200 text-sm resize-y"
                                disabled={saving}
                              />
                              <div className="flex gap-2">
                                <button
                                  type="button"
                                  onClick={() => handleSaveComment(item.source + "-" + item.comment_id, editingCommentContent)}
                                  disabled={saving}
                                  className="px-3 py-1.5 bg-primary text-white text-xs font-semibold rounded-lg"
                                >
                                  Salvează
                                </button>
                                <button
                                  type="button"
                                  onClick={() => { setEditingCommentId(null); }}
                                  disabled={saving}
                                  className="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs rounded-lg"
                                >
                                  Anulare
                                </button>
                              </div>
                            </div>
                          ) : (
                            <p className="text-sm text-gray-700 mt-1.5 whitespace-pre-wrap leading-relaxed">{item.content}</p>
                          )}
                        </div>
                      </li>
                  ))}
                </ul>
              )}
              <form onSubmit={handleCommentSubmit} className="mt-4 pt-4 border-t border-gray-100">
                <textarea
                  value={commentText}
                  onChange={(e) => setCommentText(e.target.value)}
                  placeholder="Adaugă un comentariu..."
                  rows={3}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50/60 text-[#0e141b] placeholder:text-gray-400 focus:bg-white focus:border-primary/40 focus:ring-2 focus:ring-primary/10 resize-y min-h-[80px]"
                  disabled={commentSending}
                />
                {isAgent && (
                  <label className="mt-3 flex items-center gap-2 cursor-pointer w-fit">
                    <input
                      type="checkbox"
                      checked={commentInternal}
                      onChange={(e) => setCommentInternal(e.target.checked)}
                      className="rounded border-gray-300 text-primary focus:ring-primary/40"
                    />
                    <span className="text-sm text-gray-600">Comentariu intern</span>
                  </label>
                )}
                <button
                  type="submit"
                  disabled={!commentText.trim() || commentSending}
                  className="mt-2 px-4 py-2 bg-primary hover:bg-primary-hover text-white text-sm font-semibold rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {commentSending ? "Se trimite…" : "Trimite comentariu"}
                </button>
              </form>
            </div>
          </div>

        </div>

        {/* Sidebar: Status CTAs (agent) + Informații ticket (cu edit inline pentru agent) */}
        <div className="space-y-6">
          {isAgent && lookup && (
            <div className="bg-white border border-gray-200/90 rounded-2xl shadow-card-lg overflow-hidden">
              <div className="px-5 py-4 border-b border-gray-100 bg-primary/5">
                <h2 className="text-sm font-semibold text-[#0e141b] flex items-center gap-2">
                  <span className="material-symbols-outlined text-lg text-primary">swap_horiz</span>
                  Schimbă statusul
                </h2>
              </div>
              <div className="px-5 py-4 flex flex-wrap gap-2">
                {lookup.statuses.map((s) => (
                  <button
                    key={s.id}
                    type="button"
                    onClick={handleStatusChange(s.id)}
                    disabled={saving || ticket.status_id === s.id}
                    className={"px-3 py-1.5 rounded-lg text-xs font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed " + (ticket.status_id === s.id ? statusClass(ticket.status_nume) + " ring-1 ring-primary/30" : "bg-gray-100 text-gray-700 hover:bg-gray-200")}
                  >
                    {s.nume}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className="bg-white border border-gray-200/90 rounded-2xl shadow-card-lg overflow-hidden">
            <div className="px-5 py-4 border-b border-gray-100 bg-gray-50/60">
              <h2 className="text-sm font-semibold text-[#0e141b] flex items-center gap-2">
                <span className="material-symbols-outlined text-lg text-primary">info</span>
                Informații ticket
              </h2>
            </div>
            <div className="px-5 py-1">
              <InfoRow label="ID" value={`#${ticket.ticket_id}`} />
              <InfoRow label="Client" value={ticket.client_nume || ticket.client_email || "—"} />

              {isAgent && lookup ? (
                <>
                  <InfoRowEditable
                    label="Agent"
                    value={
                      hasAgent ? (
                        <span className="truncate block" title={ticket.agent_email || undefined}>
                          {ticket.agent_nume || ticket.agent_email}
                        </span>
                      ) : (
                        <span className="text-amber-600 font-medium">Unassigned</span>
                      )
                    }
                    isEditing={editField === "agent"}
                    onStartEdit={() => setEditField("agent")}
                    onEndEdit={() => setEditField(null)}
                  >
                    <select
                      autoFocus
                      value={ticket.assigned_agent_id ?? ""}
                      onChange={(e) => {
                        const v = e.target.value;
                        handlePatch({ assigned_agent_id: v ? Number(v) : null });
                        setEditField(null);
                      }}
                      onBlur={() => setEditField(null)}
                      disabled={saving}
                      className="w-full px-3 py-2 rounded-xl border border-gray-200 bg-white text-sm focus:border-primary/40 focus:ring-2 focus:ring-primary/10"
                    >
                      <option value="">Unassigned</option>
                      {lookup.agents.map((a) => (
                        <option key={a.id} value={a.id}>{a.nume}</option>
                      ))}
                    </select>
                  </InfoRowEditable>
                  <InfoRowEditable
                    label="Prioritate"
                    value={ticket.prioritate_nume}
                    isEditing={editField === "prioritate"}
                    onStartEdit={() => setEditField("prioritate")}
                    onEndEdit={() => setEditField(null)}
                  >
                    <select
                      autoFocus
                      value={ticket.prioritate_id ?? ""}
                      onChange={(e) => {
                        const v = e.target.value;
                        if (v) {
                          handlePatch({ prioritate_id: Number(v) });
                          setEditField(null);
                        }
                      }}
                      onBlur={() => setEditField(null)}
                      disabled={saving}
                      className="w-full px-3 py-2 rounded-xl border border-gray-200 bg-white text-sm focus:border-primary/40 focus:ring-2 focus:ring-primary/10"
                    >
                      {lookup.priorities.map((p) => (
                        <option key={p.id} value={p.id}>{p.nume}</option>
                      ))}
                    </select>
                  </InfoRowEditable>
                  <InfoRowEditable
                    label="Categorie"
                    value={ticket.categorie_nume ?? "—"}
                    isEditing={editField === "categorie"}
                    onStartEdit={() => setEditField("categorie")}
                    onEndEdit={() => setEditField(null)}
                  >
                    <select
                      autoFocus
                      value={ticket.categorie_id ?? ""}
                      onChange={(e) => {
                        const v = e.target.value;
                        handlePatch({ categorie_id: v ? Number(v) : null });
                        setEditField(null);
                      }}
                      onBlur={() => setEditField(null)}
                      disabled={saving}
                      className="w-full px-3 py-2 rounded-xl border border-gray-200 bg-white text-sm focus:border-primary/40 focus:ring-2 focus:ring-primary/10"
                    >
                      <option value="">—</option>
                      {lookup.categories.map((c) => (
                        <option key={c.id} value={c.id}>{c.nume}</option>
                      ))}
                    </select>
                  </InfoRowEditable>
                  <InfoRowEditable
                    label="Departament"
                    value={ticket.departament_nume}
                    isEditing={editField === "departament"}
                    onStartEdit={() => setEditField("departament")}
                    onEndEdit={() => setEditField(null)}
                  >
                    <select
                      autoFocus
                      value={ticket.departament_id ?? ""}
                      onChange={(e) => {
                        const v = e.target.value;
                        if (v) {
                          handlePatch({ departament_id: Number(v) });
                          setEditField(null);
                        }
                      }}
                      onBlur={() => setEditField(null)}
                      disabled={saving}
                      className="w-full px-3 py-2 rounded-xl border border-gray-200 bg-white text-sm focus:border-primary/40 focus:ring-2 focus:ring-primary/10"
                    >
                      {lookup.departments.map((d) => (
                        <option key={d.id} value={d.id}>{d.nume}</option>
                      ))}
                    </select>
                  </InfoRowEditable>
                </>
              ) : (
                <InfoRow label="Prioritate" value={ticket.prioritate_nume} />
              )}

              <InfoRow label="Data creare" value={<span className="tabular-nums">{formatDate(ticket.data_creare)}</span>} />
              <InfoRow label="Data rezolvare" value={<span className="tabular-nums">{formatDate(ticket.data_rezolvare)}</span>} />
              <InfoRow label="Data închidere" value={<span className="tabular-nums">{formatDate(ticket.data_inchidere)}</span>} />
            </div>
          </div>

          {/* Istoric ticket */}
          <div className="bg-white border border-gray-200/90 rounded-2xl shadow-card-lg overflow-hidden flex flex-col min-h-0">
            <div className="px-5 py-4 border-b border-gray-100 bg-gray-50/60 shrink-0">
              <h2 className="text-sm font-semibold text-[#0e141b] flex items-center gap-2">
                <span className="material-symbols-outlined text-lg text-primary">history_edu</span>
                Istoric ticket
                {historyItems.length > 0 && (
                  <span className="text-xs font-normal text-gray-500">({historyItems.length})</span>
                )}
              </h2>
            </div>
            <div className="px-5 py-4 max-h-[280px] min-h-0 overflow-y-auto overflow-x-hidden">
              {historyItems.length === 0 ? (
                <p className="text-sm text-gray-500">Niciun eveniment încă.</p>
              ) : (
                <ul className="space-y-3 list-none p-0 m-0">
                  {historyItems.map((h) => (
                    <li key={"h-" + h.history_id} className="flex gap-2 text-sm">
                      <span className="material-symbols-outlined text-gray-400 shrink-0 text-lg mt-0.5" aria-hidden>edit_note</span>
                      <div className="min-w-0 flex-1 overflow-hidden">
                        <p className="text-gray-700 break-words">{h.display_text ?? "Descriere modificată"}</p>
                        <p className="text-xs text-gray-400 mt-0.5 truncate">
                          {h.author_name} · <span className="tabular-nums">{formatDate(h.created_date)}</span>
                        </p>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

type User = { id: number; role: "client" | "agent"; email: string; name: string };

export default function TicketDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const [data, setData] = useState<TicketDetail | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [lookup, setLookup] = useState<Lookup | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    if (!id) return;
    setLoading(true);
    Promise.all([
      fetch("/api/auth/me").then((r) => (r.ok ? r.json() : null)),
      fetch("/api/tickets/" + id).then((r) => {
        if (r.status === 404) throw new Error("Ticket not found");
        return r.ok ? r.json() : r.json().then((j: { error?: string }) => Promise.reject(new Error(j.error || "Failed to load")));
      }),
    ])
      .then(([me, ticketData]) => {
        setUser(me || null);
        setData(ticketData);
        if (me?.role === "agent") {
          return fetch("/api/tickets/lookup")
            .then((r) => (r.ok ? r.json() : null))
            .then(setLookup);
        }
      })
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-28 gap-4">
        <span className="material-symbols-outlined animate-spin text-5xl text-primary">progress_activity</span>
        <p className="text-sm text-gray-500">Loading ticket…</p>
      </div>
    );
  }
  if (error || !data) {
    return (
      <div className="rounded-2xl border border-red-200/80 bg-red-50 p-6 text-red-700 flex items-start gap-4 shadow-card">
        <span className="material-symbols-outlined text-2xl shrink-0">error</span>
        <div>
          <p className="font-semibold">Error</p>
          <p className="text-sm mt-1 opacity-90">{error || "Ticket not found."}</p>
          <Link href="/" className="inline-flex items-center gap-1.5 mt-4 text-sm font-medium text-primary hover:underline rounded focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 focus-visible:ring-offset-1">
            <span className="material-symbols-outlined text-[18px]">arrow_back</span>
            Back to Dashboard
          </Link>
        </div>
      </div>
    );
  }

  const role = user?.role ?? "client";
  const userId = user?.id ?? null;
  return (
    <TicketView
      data={data}
      userRole={role}
      userId={userId}
      lookup={lookup}
      onRefresh={() => {
        fetch("/api/tickets/" + id)
          .then((r) => r.ok ? r.json() : null)
          .then((d) => d && setData(d));
      }}
    />
  );
}
