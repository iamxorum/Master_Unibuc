import { NextResponse } from "next/server";
import { runQuery } from "@/lib/db";
import { getSession } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function GET() {
  const session = await getSession();
  if (session?.role !== "agent") {
    return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
  }

  try {
    const data = await runQuery(async (conn) => {
      // 0. Counter Fact Table
      const factCount = await conn.execute(
        `SELECT COUNT(*) as cnt FROM TickLy_DW.fact_ticket`
      );
      // FIX: Castam explicit rows la 'any[]' sau 'Record<string, any>[]'
      const factRows = factCount.rows as Record<string, any>[]; 
      const totalFacts = factRows?.[0]?.CNT ?? 0;

      // 1. SLA (Gauge)
      const sla = await conn.execute(
        `SELECT respectat_sla, total_critice 
         FROM TickLy_DW.mv_report_sla 
         ORDER BY an DESC, luna DESC FETCH FIRST 1 ROW ONLY`
      );
      const slaRows = sla.rows as Record<string, any>[];

      // 2. Trend (Line Chart Data)
      const trend = await conn.execute(
        `SELECT luna_nume, an, tichete_deschise, tichete_rezolvate 
         FROM TickLy_DW.mv_report_trend 
         ORDER BY sort_key DESC FETCH FIRST 12 ROWS ONLY`
      );

      // 3. Top Topics (Bar Chart Data)
      const topics = await conn.execute(
        `SELECT topic_nume, topic_type, total_tichete 
         FROM TickLy_DW.mv_report_top_topics 
         ORDER BY total_tichete DESC FETCH FIRST 5 ROWS ONLY`
      );

      // 4. Agents (Scatter Plot Data)
      const agents = await conn.execute(
        `SELECT nume_complet, departament, tichete_rezolvate, medie_ore
         FROM TickLy_DW.mv_report_agents 
         ORDER BY tichete_rezolvate DESC FETCH FIRST 5 ROWS ONLY`
      );

      // 5. Dept Stats (Yearly)
      const deptStats = await conn.execute(
        `SELECT departament_nume, an, mv_total_tichete, mv_venit_total, mv_sum_timp, mv_count_timp
         FROM TickLy_DW.mv_dept_yearly_stats
         ORDER BY an DESC, mv_total_tichete DESC`
      );

      // 6. Dept Performance
      const deptPerf = await conn.execute(
        `SELECT departament, luna_nume, an, timp_mediu_ore, volum_tichete
         FROM TickLy_DW.mv_report_dept_perf
         ORDER BY sort_key DESC FETCH FIRST 10 ROWS ONLY`
      );

      return {
        total_facts: totalFacts,
        sla: slaRows?.[0] || { RESPECTAT_SLA: 0, TOTAL_CRITICE: 0 },
        trend: trend.rows || [],
        topics: topics.rows || [],
        agents: agents.rows || [],
        dept_stats: deptStats.rows || [],
        dept_perf: deptPerf.rows || []
      };
    });

    return NextResponse.json(data);
  } catch (e: any) {
    console.error("API Error:", e);
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}

// Trigger Sync DW
export async function POST() {
  const session = await getSession();
  if (session?.role !== "agent") return NextResponse.json({ error: "Unauthorized" }, { status: 403 });

  try {
    await runQuery(async (conn) => {
      await conn.execute(`BEGIN TickLy_DW.SYNC_DATA_WAREHOUSE; END;`);
    });
    return NextResponse.json({ success: true });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}