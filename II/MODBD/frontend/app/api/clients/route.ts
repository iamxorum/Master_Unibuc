import { NextResponse } from "next/server";
import { runQueryByUserType } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  // Verificăm dacă utilizatorul este autentificat
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Neautorizat" }, { status: 401 });
  }

  // Preluăm instanța selectată din frontend (B2C sau B2B)
  const { searchParams } = new URL(request.url);
  const type = (searchParams.get("type") || "B2C") as "B2C" | "B2B";

  try {
    const data = await runQueryByUserType(type, async (conn) => {
      let query = "";

      // Construim query-ul direct pe tabelele fizice conform schemelor SQL oferite
      if (type === "B2C") {
        query = `
          SELECT 
            client_id AS ID, 
            nume || ' ' || prenume AS NUME 
          FROM TICKLY.client_fizic
          WHERE client_id IS NOT NULL
          ORDER BY nume ASC, prenume ASC
        `;
      } else {
        query = `
          SELECT 
            client_id AS ID, 
            denumire AS NUME 
          FROM TICKLY.client_juridic
          WHERE client_id IS NOT NULL
          ORDER BY denumire ASC
        `;
      }
      
      const result = await conn.execute(query);
      return result.rows || [];
    });

    return NextResponse.json(data);
  } catch (e: any) {
    console.error("Eroare în api/clients:", e);
    return NextResponse.json(
      { error: e.message || "A apărut o eroare la încărcarea clienților." }, 
      { status: 500 }
    );
  }
}