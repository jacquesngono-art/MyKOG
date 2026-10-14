"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  BookOpen,
  FileText,
  Users,
  Radio,
  Play,
  Eye,
  ArrowRight,
  Megaphone,
  Calendar,
  Database,
} from "lucide-react";
import { statsService } from "@/lib/services/stats";
import { livesService } from "@/lib/services/lives";
import { annoncesService } from "@/lib/services/annonces";
import { storageService, formatBytes, type StorageStats } from "@/lib/services/storage";
import type { LiveStream, Annonce } from "@/lib/types";

interface DashStats {
  totalUsers: number;
  totalEnseignements: number;
  activeLives: number;
  totalPlays: number;
  totalPdfViews: number;
  totalPdfs: number;
}

export default function OverviewPage() {
  const [stats, setStats] = useState<DashStats | null>(null);
  const [activeLive, setActiveLive] = useState<LiveStream | null>(null);
  const [recentAnnonces, setRecentAnnonces] = useState<Annonce[]>([]);
  const [storage, setStorage] = useState<StorageStats | null>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    try {
      const [s, live, annonces] = await Promise.all([
        statsService.getDashboardStats(),
        livesService.getActiveSafe().catch(() => null),
        annoncesService.getAll().catch(() => []),
      ]);
      setStats(s);
      setActiveLive(live && live.id ? live : null);
      setRecentAnnonces(
        [...annonces]
          .sort(
            (a, b) =>
              new Date(b.dateCreation).getTime() -
              new Date(a.dateCreation).getTime()
          )
          .slice(0, 5)
      );
      storageService.getStats().then(setStorage).catch(() => setStorage(null));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    const id = setInterval(load, 30000);
    return () => clearInterval(id);
  }, []);

  const cards = [
    { label: "Utilisateurs", value: stats?.totalUsers ?? "—", icon: Users, href: "/users" },
    { label: "Enseignements", value: stats?.totalEnseignements ?? "—", icon: BookOpen, href: "/enseignements" },
    { label: "Lives actifs", value: stats?.activeLives ?? "—", icon: Radio, href: "/lives", accent: true },
    { label: "Écoutes totales", value: stats?.totalPlays ?? "—", icon: Play, href: "/statistiques" },
    { label: "PDF résumés", value: stats?.totalPdfs ?? "—", icon: FileText, href: "/text-resumes" },
    { label: "Vues PDF", value: stats?.totalPdfViews ?? "—", icon: Eye, href: "/statistiques" },
  ];

  return (
    <DashboardShell
      title="Vue d'ensemble"
      subtitle="Console d'administration MyKOG"
      onRefresh={load}
    >
      {/* Live banner */}
      {activeLive && (
        <Link href="/lives" className="block mb-6">
          <div className="flex items-center gap-4 p-4 rounded-2xl bg-destructive/5 border border-destructive/25 hover:bg-destructive/10 transition-colors">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-destructive opacity-75" />
              <span className="relative inline-flex rounded-full h-3 w-3 bg-destructive" />
            </span>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-foreground truncate">
                {activeLive.title}
              </p>
              <p className="text-sm text-muted-foreground">
                {activeLive.pastor} · {activeLive.viewerCount || 0} viewer(s)
              </p>
            </div>
            <Badge variant="destructive">EN DIRECT</Badge>
            <ArrowRight className="w-4 h-4 text-muted-foreground" />
          </div>
        </Link>
      )}

      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {cards.map((c) => (
          <Link key={c.label} href={c.href}>
            <Card className="hover:border-accent/50 transition-colors cursor-pointer h-full">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  {c.label}
                </CardTitle>
                <c.icon
                  className={
                    c.accent ? "w-4 h-4 text-destructive" : "w-4 h-4 text-muted-foreground"
                  }
                />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-semibold tracking-tight">
                  {loading && stats === null ? "…" : c.value}
                </p>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      {/* Stockage AWS */}
      {storage?.configured && (
        <Card className="mb-8">
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Database className="w-4 h-4 text-muted-foreground" />
              Stockage AWS S3
            </CardTitle>
            <span className="text-xs text-muted-foreground">
              {storage.bucket} · {storage.region}
            </span>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-4 mb-3">
              <div className="flex-1 h-2.5 rounded-full bg-muted overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all ${
                    (storage.usagePercent || 0) > 80
                      ? "bg-destructive"
                      : (storage.usagePercent || 0) > 50
                        ? "bg-warning"
                        : "bg-success"
                  }`}
                  style={{ width: `${Math.min(100, storage.usagePercent || 0)}%` }}
                />
              </div>
              <span className="text-sm font-medium whitespace-nowrap">
                {storage.usagePercent}%
              </span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">
                <span className="font-medium text-foreground">{formatBytes(storage.totalBytes)}</span> utilisés
                {" · "}
                <span className="font-medium text-success">{formatBytes(storage.remainingBytes)}</span> restants
                {" · quota référence "}{storage.quotaGB} Go
              </span>
              <span className="text-xs text-muted-foreground">
                {storage.objectCount} objet(s) — S3 facture à l'usage réel
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Dernières annonces */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Megaphone className="w-4 h-4 text-muted-foreground" />
              Dernières annonces
            </CardTitle>
            <Link
              href="/annonces"
              className="text-xs text-muted-foreground hover:text-foreground flex items-center gap-1"
            >
              Tout voir <ArrowRight className="w-3 h-3" />
            </Link>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentAnnonces.map((a) => (
              <div key={a.id} className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-lg bg-accent/15 flex items-center justify-center shrink-0">
                  <Megaphone className="w-4 h-4 text-accent-foreground" />
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium truncate">{a.nom}</p>
                  <p className="text-xs text-muted-foreground truncate">
                    {a.description}
                  </p>
                </div>
              </div>
            ))}
            {recentAnnonces.length === 0 && (
              <p className="text-sm text-muted-foreground">Aucune annonce</p>
            )}
          </CardContent>
        </Card>

        {/* Accès rapides */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Actions rapides</CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-3">
            {[
              { href: "/lives", label: "Gérer les lives", icon: Radio },
              { href: "/enseignements", label: "Ajouter un enseignement", icon: BookOpen },
              { href: "/notifications", label: "Envoyer une notification", icon: Megaphone },
              { href: "/calendar", label: "Calendrier", icon: Calendar },
            ].map((a) => (
              <Link
                key={a.href}
                href={a.href}
                className="flex items-center gap-3 p-3 rounded-xl bg-muted/50 hover:bg-muted transition-colors"
              >
                <a.icon className="w-4 h-4 text-accent-foreground" />
                <span className="text-sm font-medium">{a.label}</span>
              </Link>
            ))}
          </CardContent>
        </Card>
      </div>
    </DashboardShell>
  );
}
