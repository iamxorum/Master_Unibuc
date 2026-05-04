"use client";

import { useEffect, useState } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  Cell,
  PieChart,
  Pie,
  Legend,
  ComposedChart,
  Line,
  Sector
} from "recharts";

// --- CULORI & CONFIGURĂRI ---
const COLORS = {
  primary: "#3B82F6", // Blue 500
  primaryGradientStart: "#60A5FA",
  primaryGradientEnd: "#2563EB",
  secondary: "#F59E0B", // Amber 500
  success: "#10B981",
  danger: "#EF4444",
  textMain: "#1E293B", // Slate 800
  textSub: "#64748B",  // Slate 500
  grid: "#E2E8F0"
};

// Componenta Card
function DashboardCard({ title, children, className = "" }: { title: string, children: React.ReactNode, className?: string }) {
  return (
    <div className={`bg-white p-6 rounded-2xl border border-slate-100 shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] flex flex-col ${className}`}>
      <h3 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-6 flex items-center gap-2">
        {title}
      </h3>
      <div className="flex-1 min-h-0 relative w-full">
        {children}
      </div>
    </div>
  );
}

// Tooltip Modern (Sticlă)
const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white/95 backdrop-blur-md p-4 border border-slate-100 shadow-xl rounded-xl text-sm z-50">
        <p className="font-bold text-slate-800 mb-2 border-b border-slate-100 pb-1">{label}</p>
        {payload.map((entry: any, index: number) => (
          <div key={index} className="flex items-center gap-3 text-xs font-medium mt-1.5">
            <span className="w-2 h-2 rounded-full shadow-sm" style={{ backgroundColor: entry.color }}></span>
            <span className="text-slate-500 min-w-[60px]">{entry.name}:</span>
            <span className="text-slate-900 font-bold text-base">
              {entry.name === "Medie Ore" ? `${entry.value} h` : entry.value}
            </span>
          </div>
        ))}
      </div>
    );
  }
  return null;
};

export default function ReportsPage() {
  const [data, setData] = useState<any>(null);
  const [syncing, setSyncing] = useState(false);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      const res = await fetch("/api/reports");
      if (!res.ok) throw new Error("Failed");
      const json = await res.json();
      setData(json);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const triggerSync = async () => {
    setSyncing(true);
    try {
      const res = await fetch("/api/reports", { method: "POST" });
      if (res.ok) {
        alert("Sincronizare completă!");
        loadData();
      }
    } finally {
      setSyncing(false);
    }
  };

  useEffect(() => { loadData(); }, []);

  if (loading) return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-4 bg-slate-50">
      <div className="w-12 h-12 border-4 border-blue-500/30 border-t-blue-500 rounded-full animate-spin"></div>
      <p className="text-slate-500 font-medium">Se încarcă dashboard-ul...</p>
    </div>
  );

  // --- PREGĂTIRE DATE (CASTING EXPLICIT LA NUMBER) ---
  
  // 1. SLA
  const slaTotal = Number(data?.sla?.TOTAL_CRITICE || 0);
  const slaOk = Number(data?.sla?.RESPECTAT_SLA || 0);
  const slaPercent = slaTotal > 0 ? Math.round((slaOk / slaTotal) * 100) : 0;
  const slaColor = slaPercent >= 95 ? COLORS.success : slaPercent >= 75 ? COLORS.secondary : COLORS.danger;

  // 2. Trend
  const trendData = [...(data?.trend || [])].reverse().map((item: any) => ({
    name: `${item.LUNA_NUME?.substring(0, 3)} '${item.AN?.toString().slice(-2)}`,
    Deschise: Number(item.TICHETE_DESCHISE),
    Rezolvate: Number(item.TICHETE_REZOLVATE),
  }));

  // 3. Topics
  const topicsData = data?.topics?.map((t: any) => ({
    name: t.TOPIC_NUME,
    tichete: Number(t.TOTAL_TICHETE),
    type: t.TOPIC_TYPE
  })) || [];

  // 4. Agents (AICI ESTE CHEIA PENTRU GRAFICUL TAU)
  const agentsData = data?.agents?.map((a: any) => ({
    name: a.NUME_COMPLET ? a.NUME_COMPLET.split(' ')[0] : "Anonim",
    fullName: a.NUME_COMPLET,
    // Cast explicit la Number, altfel Recharts nu deseneaza nimic
    Rezolvate: Number(a.TICHETE_REZOLVATE || 0),
    "Medie Ore": Number(a.MEDIE_ORE || 0),
  })) || [];

  return (
    <div className="p-6 md:p-8 max-w-[1600px] mx-auto space-y-8 bg-slate-50/50 min-h-screen font-sans text-slate-800">
      
      {/* HEADER */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-2xl border border-slate-100 shadow-sm">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-3">
            <span className="p-2 bg-blue-50 text-blue-600 rounded-lg shadow-sm">
                <span className="material-symbols-outlined text-2xl">analytics</span>
            </span>
            Dashboard Analitic
          </h1>
          <p className="text-sm text-slate-500 mt-1 ml-14">Sursă date: Oracle Materialized Views (Actualizat la cerere)</p>
        </div>
        <button
          onClick={triggerSync}
          disabled={syncing}
          className="flex items-center gap-2 bg-slate-900 hover:bg-blue-600 text-white px-5 py-2.5 rounded-xl transition-all shadow-lg hover:shadow-blue-500/30 active:scale-95 disabled:opacity-70"
        >
          <span className={`material-symbols-outlined text-[20px] ${syncing ? "animate-spin" : ""}`}>sync</span>
          {syncing ? "Sincronizare..." : "Refresh Date"}
        </button>
      </div>

      {/* KPI ROWS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* KPI 1: Volum */}
        <DashboardCard title="Volum Total Date">
           <div className="flex flex-col h-full justify-between mt-2">
             <div className="flex items-baseline gap-2">
               <span className="text-5xl font-black text-slate-900 tracking-tighter">
                 {new Intl.NumberFormat('ro-RO').format(Number(data?.total_facts || 0))}
               </span>
               <span className="text-sm font-bold text-slate-400">înregistrări</span>
             </div>
             <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden mt-4">
               <div className="h-full bg-gradient-to-r from-blue-400 to-blue-600 w-full"></div>
             </div>
           </div>
        </DashboardCard>

        {/* KPI 2: SLA Gauge (Modern) */}
        <DashboardCard title="Performanță SLA (48h)">
           <div className="relative h-[160px] w-full flex items-center justify-center -mt-6">
             <ResponsiveContainer width="100%" height="100%">
               <PieChart>
                 <Pie
                   data={[{ value: 1 }]}
                   cx="50%" cy="80%"
                   startAngle={180} endAngle={0}
                   innerRadius={65} outerRadius={85}
                   fill="#F1F5F9" stroke="none"
                   isAnimationActive={false}
                 />
                 <Pie
                   data={[{ value: slaPercent }]}
                   cx="50%" cy="80%"
                   startAngle={180}
                   endAngle={180 - (180 * slaPercent) / 100}
                   innerRadius={65} outerRadius={85}
                   fill={slaColor} stroke="none"
                   cornerRadius={10}
                 />
               </PieChart>
             </ResponsiveContainer>
             <div className="absolute bottom-6 flex flex-col items-center">
               <span className="text-4xl font-bold text-slate-800">{slaPercent}%</span>
               <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest bg-slate-100 px-2 py-0.5 rounded-full mt-1">Rată Succes</span>
             </div>
           </div>
        </DashboardCard>

        {/* KPI 3: Top Topic */}
        <DashboardCard title="Top Subiect">
           {data?.topics?.[0] ? (
             <div className="flex flex-col h-full justify-center">
               <h2 className="text-xl font-bold text-slate-800 leading-tight">
                 {data.topics[0].TOPIC_NUME}
               </h2>
               <div className="mt-4 flex items-center justify-between">
                 <span className={`px-3 py-1 rounded-lg text-xs font-bold uppercase ${data.topics[0].TOPIC_TYPE === 'S' ? 'bg-indigo-50 text-indigo-600' : 'bg-amber-50 text-amber-600'}`}>
                   {data.topics[0].TOPIC_TYPE === 'S' ? 'Serviciu' : 'Produs'}
                 </span>
                 <span className="text-2xl font-bold text-slate-700">{data.topics[0].TOTAL_TICHETE} <span className="text-sm text-slate-400 font-normal">tichete</span></span>
               </div>
             </div>
           ) : <p className="text-slate-400">Lipsă date.</p>}
        </DashboardCard>
      </div>

      {/* --- RANDUL 2: GRAFICE MARI --- */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 min-h-[400px]">
        
        {/* Trend Area Chart (2/3) */}
        <div className="lg:col-span-2">
            <DashboardCard title="Evoluție Lunară" className="h-[400px]">
                <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={trendData} margin={{ top: 20, right: 10, left: 0, bottom: 0 }}>
                    <defs>
                        <linearGradient id="colorDeschise" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor={COLORS.primary} stopOpacity={0.2}/>
                            <stop offset="95%" stopColor={COLORS.primary} stopOpacity={0}/>
                        </linearGradient>
                        <linearGradient id="colorRezolvate" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor={COLORS.success} stopOpacity={0.2}/>
                            <stop offset="95%" stopColor={COLORS.success} stopOpacity={0}/>
                        </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={COLORS.grid} />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: COLORS.textSub, fontSize: 12}} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{fill: COLORS.textSub, fontSize: 12}} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend verticalAlign="top" height={36} iconType="circle" />
                    <Area type="monotone" dataKey="Deschise" stroke={COLORS.primary} fillOpacity={1} fill="url(#colorDeschise)" strokeWidth={3} />
                    <Area type="monotone" dataKey="Rezolvate" stroke={COLORS.success} fillOpacity={1} fill="url(#colorRezolvate)" strokeWidth={3} />
                    </AreaChart>
                </ResponsiveContainer>
            </DashboardCard>
        </div>

        {/* Top Topics (1/3) */}
        <div>
            <DashboardCard title="Categorii" className="h-[400px]">
                <ResponsiveContainer width="100%" height="100%">
                    <BarChart layout="vertical" data={topicsData} margin={{ top: 0, right: 20, left: 40, bottom: 0 }}>
                        <XAxis type="number" hide />
                        <YAxis dataKey="name" type="category" width={130} tick={{fontSize: 11, fill: COLORS.textSub, fontWeight: 500}} interval={0} />
                        <Tooltip cursor={{fill: 'transparent'}} content={<CustomTooltip />} />
                        <Bar dataKey="tichete" name="Tichete" radius={[0, 4, 4, 0]} barSize={20}>
                            {topicsData.map((entry: any, index: number) => (
                            <Cell key={`cell-${index}`} fill={index % 2 === 0 ? COLORS.primary : "#8B5CF6"} />
                            ))}
                        </Bar>
                    </BarChart>
                </ResponsiveContainer>
            </DashboardCard>
        </div>
      </div>

      {/* --- RANDUL 3: AGENTI & DEPARTAMENTE (STILIZAT PREMIUM) --- */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* --- GRAFICUL DE AGENȚI REPARAT ȘI STILIZAT --- */}
        <DashboardCard title="Eficiență Agenți (Volum vs Viteză)" className="h-[450px]">
            {agentsData.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                    <ComposedChart data={agentsData} margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                        {/* Gradient pentru bare */}
                        <defs>
                            <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0%" stopColor={COLORS.primaryGradientStart} />
                                <stop offset="100%" stopColor={COLORS.primaryGradientEnd} />
                            </linearGradient>
                        </defs>
                        
                        <CartesianGrid stroke={COLORS.grid} strokeDasharray="3 3" vertical={false} />
                        
                        <XAxis 
                            dataKey="name" 
                            tick={{fontSize: 12, fill: COLORS.textSub}} 
                            axisLine={false} 
                            tickLine={false}
                            dy={10} 
                        />
                        
                        {/* Axa Stângă (Volum) - Albastră */}
                        <YAxis 
                            yAxisId="left" 
                            orientation="left" 
                            stroke={COLORS.primary} 
                            tick={{fill: COLORS.textSub, fontSize: 12}} 
                            axisLine={false} 
                            tickLine={false} 
                            label={{ value: 'Volum (Tichete)', angle: -90, position: 'insideLeft', style: {fill: COLORS.primary, fontSize: 10, fontWeight: 'bold'} }}
                        />
                        
                        {/* Axa Dreaptă (Viteză) - Portocalie */}
                        <YAxis 
                            yAxisId="right" 
                            orientation="right" 
                            stroke={COLORS.secondary} 
                            tick={{fill: COLORS.textSub, fontSize: 12}} 
                            axisLine={false} 
                            tickLine={false} 
                            label={{ value: 'Timp Mediu (Ore)', angle: 90, position: 'insideRight', style: {fill: COLORS.secondary, fontSize: 10, fontWeight: 'bold'} }}
                        />
                        
                        <Tooltip content={<CustomTooltip />} />
                        <Legend wrapperStyle={{ paddingTop: '20px' }} iconType="circle" />
                        
                        {/* Bare cu Gradient și colțuri rotunjite */}
                        <Bar 
                            yAxisId="left" 
                            dataKey="Rezolvate" 
                            name="Tichete Rezolvate" 
                            barSize={32} 
                            fill="url(#barGradient)" 
                            radius={[8, 8, 0, 0]} 
                        />
                        
                        {/* Linie Curbată, Groasă, cu Umbră */}
                        <Line 
                            yAxisId="right" 
                            type="monotone" 
                            dataKey="Medie Ore" 
                            name="Medie Ore" 
                            stroke={COLORS.secondary} 
                            strokeWidth={4} 
                            dot={{r: 6, fill: 'white', stroke: COLORS.secondary, strokeWidth: 3}} 
                            activeDot={{r: 8, strokeWidth: 0}} 
                        />
                    </ComposedChart>
                </ResponsiveContainer>
            ) : (
                <div className="flex h-full items-center justify-center flex-col gap-2 text-slate-400">
                    <span className="material-symbols-outlined text-4xl">bar_chart_off</span>
                    <span>Nu există date suficiente pentru agenți.</span>
                </div>
            )}
        </DashboardCard>

        {/* --- TABEL DEPARTAMENTE STILIZAT --- */}
        <DashboardCard title="Performanță Financiară & Operațională" className="h-[450px]">
            <div className="overflow-auto h-full -mx-2 px-2">
                <table className="w-full text-sm text-left border-separate border-spacing-y-2">
                    <thead className="bg-white text-slate-400 font-bold uppercase text-[10px] sticky top-0 z-10 tracking-wider">
                        <tr>
                            <th className="px-4 py-2 text-left">Departament</th>
                            <th className="px-4 py-2 text-center">An</th>
                            <th className="px-4 py-2 text-right">Volum</th>
                            <th className="px-4 py-2 text-right">Venit Est.</th>
                            <th className="px-4 py-2 text-right">Timp Mediu</th>
                        </tr>
                    </thead>
                    <tbody>
                        {data?.dept_stats?.map((row: any, i: number) => {
                             const avgTime = row.MV_COUNT_TIMP > 0 ? (row.MV_SUM_TIMP / row.MV_COUNT_TIMP).toFixed(1) : "—";
                             const isHigh = Number(avgTime) > 48;
                             return (
                                <tr key={i} className="bg-slate-50 hover:bg-white hover:shadow-md hover:scale-[1.01] transition-all duration-200 group rounded-xl">
                                    <td className="px-4 py-3 font-semibold text-slate-700 rounded-l-xl border-y border-l border-transparent group-hover:border-slate-100">
                                        {row.DEPARTAMENT_NUME}
                                    </td>
                                    <td className="px-4 py-3 text-center text-slate-500 border-y border-transparent group-hover:border-slate-100">
                                        <span className="bg-white border border-slate-200 px-2 py-0.5 rounded text-xs font-mono">{row.AN}</span>
                                    </td>
                                    <td className="px-4 py-3 text-right font-bold text-slate-800 border-y border-transparent group-hover:border-slate-100">
                                        {new Intl.NumberFormat('ro-RO').format(row.MV_TOTAL_TICHETE)}
                                    </td>
                                    <td className="px-4 py-3 text-right text-emerald-600 font-medium border-y border-transparent group-hover:border-slate-100 whitespace-nowrap">
                                      {new Intl.NumberFormat('ro-RO', { style: 'currency', currency: 'RON', maximumFractionDigits: 0 }).format(row.MV_VENIT_TOTAL)}
                                    </td>
                                    
                                    {/* AICI ESTE FIX-UL VIZUAL */}
                                    <td className="px-4 py-3 text-right rounded-r-xl border-y border-r border-transparent group-hover:border-slate-100">
                                        <div className="flex justify-end">
                                            <span className={`inline-flex items-center justify-center min-w-[70px] px-2.5 py-1 rounded-full text-xs font-bold whitespace-nowrap border ${isHigh ? 'bg-red-50 text-red-600 border-red-100' : 'bg-blue-50 text-blue-600 border-blue-100'}`}>
                                                {avgTime} h
                                            </span>
                                        </div>
                                    </td>
                                </tr>
                             )
                        })}
                    </tbody>
                </table>
            </div>
        </DashboardCard>
      </div>
    </div>
  );
}