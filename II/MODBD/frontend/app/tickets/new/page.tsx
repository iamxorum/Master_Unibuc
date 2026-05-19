import { getSession } from "@/lib/auth";
import NewTicketForm from "./NewTicketForm";

export const dynamic = "force-dynamic";

export default async function NewTicketPage() {
  // Preluăm sesiunea nativă direct pe server, exact ca în layout.tsx
  const session = await getSession();

  return <NewTicketForm session={session} />;
}