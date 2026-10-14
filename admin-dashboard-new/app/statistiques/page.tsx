"use client";

import { useEffect, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Bar, BarChart, XAxis, YAxis } from "recharts";
import {
  BookOpen,
  Megaphone,
  Radio,
  Play,
  Eye,
  Users,
  Heart,
  Download,
  Bell,
  BellOff,
  FileText,
  type LucideIcon,
} from "lucide-react";
import { statsService } from "@/lib/services/stats";
import { enseignementsService } from "@/lib/services/enseignements";
import { annoncesService } from "@/lib/services/annonces";
import { livesService } from "@/lib/services/lives";
import { textResumesService } from "@/lib/services/textResumes";
import type {
  Enseignement,
  Annonce,
  LiveStream,
  TextResume,
  UserStats,
} from "@/lib/types";

const playsChartConfig = {
  plays: { label: "Écoutes", color: "var(--chart-1)" },
} satisfies ChartConfig;

export default function StatistiquesPage() {
  const [enseignements, setEnseignements] = useState<Enseignement[]>([]);
  const [annonces, setAnnonces] = useState<Annonce[]>([]);
  const [lives, setLives] = useState<LiveStream[]>([]);
  const [textResumes, setTextResumes] = useState<TextResume[]>([]);
  const [userStats, setUserStats] = useState<UserStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    try {
      const [e, a, l, t, u] = await Promise.all([
        enseignementsService.getAll(),
        annoncesService.getAll(),
        livesService.getAll(),
        textResumesService.getAll(),
        statsService.getUserStats().catch(() => null),
      ]);
      setEnseignements(e);
      setAnnonces(a);
      setLives(l);
      setTextResumes(t);
      setUserStats(u);
      setError(null);
    } catch (e: any) {
      setError(e.message || "Erreur de chargement");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const totalPlays = enseignements.reduce(
    (s, e) => s + (e.playCount || 0),
    0
  );
  const totalPdfViews = textResumes.reduce(
    (s, t) => s + (t.viewCount || 0),
    0
  );
  const liveCount = lives.filter((l) => l.status === "live").length;

  const cards: {
    label: string;
    value: number;
    icon: LucideIcon;
    description: string;
    iconClass: string;
  }[] = [
    {
      label: "Utilisateurs",
      value: userStats?.totalUsers ?? 0,
      icon: Users,
      description: `${userStats?.notificationsEnabled ?? 0} notifications activées`,
      iconClass: "bg-accent/15 text-accent-foreground",
    },
    {
      label: "Enseignements",
      value: enseignements.length,
      icon: BookOpen,
      description: `${enseignements.filter((e) => e.isNew).length} nouveaux`,
      iconClass: "bg-info/15 text-info",
    },
    {
      label: "Écoutes totales",
      value: totalPlays,
      icon: Play,
      description: "Lectures audio cumulées",
      iconClass: "bg-success/15 text-success",
    },
    {
      label: "Vues PDF",
      value: totalPdfViews,
      icon: Eye,
      description: `${textResumes.length} résumés publiés`,
      iconClass: "bg-chart-5/15 text-chart-5",
    },
    {
      label: "Lives",
      value: lives.length,
      icon: Radio,
      description: `${liveCount} en direct`,
      iconClass: "bg-destructive/15 text-destructive",
    },
    {
      label: "Annonces",
      value: annonces.length,
      icon: Megaphone,
      description: "Total publiées",
      iconClass: "bg-warning/15 text-warning",
    },
  ];

  // Top 10 enseignements par écoutes
  const topPlays = [...enseignements]
    .sort((a, b) => (b.playCount || 0) - (a.playCount || 0))
    .slice(0, 10)
    .map((e) => ({
      name:
        e.title.length > 28 ? `${e.title.slice(0, 28)}…` : e.title,
      plays: e.playCount || 0,
    }));

  // Répartition par catégorie
  const categories = Array.from(
    new Set(enseignements.map((e) => e.category).filter(Boolean))
  ).map((category) => {
    const count = enseignements.filter(
      (e) => e.category === category
    ).length;
    return {
      category,
      count,
      pct:
        enseignements.length > 0
          ? (count / enseignements.length) * 100
          : 0,
    };
  });

  const liveStatuses: {
    key: LiveStream["status"];
    label: string;
    dot: string;
    badge: string;
  }[] = [
    {
      key: "live",
      label: "En direct",
      dot: "bg-destructive animate-pulse",
      badge: "text-destructive",
    },
    {
      key: "scheduled",
      label: "Programmés",
      dot: "bg-warning",
      badge: "text-warning",
    },
    {
      key: "ended",
      label: "Terminés",
      dot: "bg-muted-foreground",
      badge: "text-muted-foreground",
    },
  ];

  const engagement = [
    {
      icon: Heart,
      label: "Favoris",
      value: userStats?.totalFavorites ?? 0,
      sub: `${userStats?.usersWithFavorites ?? 0} utilisateur(s)`,
    },
    {
      icon: Download,
      label: "Téléchargements",
      value: userStats?.totalDownloads ?? 0,
      sub: `${userStats?.usersWithDownloads ?? 0} utilisateur(s)`,
    },
    {
      icon: Bell,
      label: "Notifications activées",
      value: userStats?.notificationsEnabled ?? 0,
      sub: "utilisateurs",
    },
    {
      icon: BellOff,
      label: "Notifications désactivées",
      value: userStats?.notificationsDisabled ?? 0,
      sub: "utilisateurs",
    },
  ];

  return (
    <DashboardShell
      title="Statistiques"
      subtitle="Vue d'ensemble du contenu publié et de l'engagement"
      onRefresh={load}
    >
      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}

      {/* Cartes de stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
        {cards.map((c) => (
          <Card key={c.label}>
            <CardContent className="pt-5">
              <div
                className={`w-9 h-9 rounded-lg flex items-center justify-center mb-3 ${c.iconClass}`}
              >
                <c.icon className="w-4 h-4" />
              </div>
              <p className="text-2xl font-semibold tracking-tight">
                {loading ? "…" : c.value.toLocaleString("fr-FR")}
              </p>
              <p className="text-sm font-medium mt-0.5">{c.label}</p>
              <p className="text-xs text-muted-foreground mt-0.5">
                {c.description}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
        {/* Top écoutes */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Play className="w-4 h-4 text-muted-foreground" />
              Top 10 — Enseignements les plus écoutés
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <p className="py-12 text-center text-sm text-muted-foreground">
                Chargement…
              </p>
            ) : topPlays.length === 0 ? (
              <p className="py-12 text-center text-sm text-muted-foreground">
                Aucun enseignement
              </p>
            ) : (
              <ChartContainer
                config={playsChartConfig}
                className="h-[320px] w-full aspect-auto"
              >
                <BarChart
                  data={topPlays}
                  layout="vertical"
                  margin={{ left: 8, right: 16, top: 4, bottom: 4 }}
                >
                  <XAxis type="number" hide />
                  <YAxis
                    dataKey="name"
                    type="category"
                    width={160}
                    tickLine={false}
                    axisLine={false}
                  />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar
                    dataKey="plays"
                    fill="var(--color-plays)"
                    radius={[0, 4, 4, 0]}
                  />
                </BarChart>
              </ChartContainer>
            )}
          </CardContent>
        </Card>

        {/* Répartition par catégorie */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-muted-foreground" />
              Répartition des enseignements
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {loading ? (
              <p className="py-12 text-center text-sm text-muted-foreground">
                Chargement…
              </p>
            ) : categories.length === 0 ? (
              <p className="py-12 text-center text-sm text-muted-foreground">
                Aucun enseignement
              </p>
            ) : (
              categories.map((c) => (
                <div key={c.category}>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="font-medium">{c.category}</span>
                    <span className="text-muted-foreground">
                      {c.count} ({c.pct.toFixed(0)}%)
                    </span>
                  </div>
                  <Progress value={c.pct} className="h-2" />
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Statut des lives */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Radio className="w-4 h-4 text-muted-foreground" />
              Statut des lives
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {liveStatuses.map((s) => {
              const count = lives.filter((l) => l.status === s.key).length;
              return (
                <div
                  key={s.key}
                  className="flex items-center justify-between p-4 rounded-xl bg-muted/50 border border-border"
                >
                  <div className="flex items-center gap-3">
                    <span className={`w-2.5 h-2.5 rounded-full ${s.dot}`} />
                    <span className="text-sm font-medium">{s.label}</span>
                  </div>
                  <span className={`text-lg font-semibold ${s.badge}`}>
                    {count}
                  </span>
                </div>
              );
            })}
          </CardContent>
        </Card>

        {/* Engagement utilisateurs */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <FileText className="w-4 h-4 text-muted-foreground" />
              Engagement des utilisateurs
            </CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-3">
            {engagement.map((e) => (
              <div
                key={e.label}
                className="p-4 rounded-xl bg-muted/50 border border-border"
              >
                <div className="flex items-center gap-2 mb-2">
                  <e.icon className="w-4 h-4 text-accent-foreground" />
                  <span className="text-xs text-muted-foreground">
                    {e.label}
                  </span>
                </div>
                <p className="text-xl font-semibold tracking-tight">
                  {loading ? "…" : e.value.toLocaleString("fr-FR")}
                </p>
                <p className="text-xs text-muted-foreground mt-0.5">{e.sub}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </DashboardShell>
  );
}
