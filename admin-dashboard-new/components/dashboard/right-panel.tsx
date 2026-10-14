"use client";

import { useEffect, useState } from "react";
import { Activity, Clock, Users, Radio, Eye, Wifi, WifiOff, Database } from "lucide-react";
import { cn } from "@/lib/utils";
import { livesService } from "@/lib/services/lives";
import { usersService } from "@/lib/services/users";
import { storageService, formatBytes, type StorageStats } from "@/lib/services/storage";
import type { LiveStream, User } from "@/lib/types";

function timeAgo(dateStr?: string | null) {
  if (!dateStr) return "";
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "à l'instant";
  if (mins < 60) return `il y a ${mins} min`;
  const h = Math.floor(mins / 60);
  if (h < 24) return `il y a ${h} h`;
  return `il y a ${Math.floor(h / 24)} j`;
}

export function RightPanel() {
  const [apiOnline, setApiOnline] = useState<boolean | null>(null);
  const [activeLive, setActiveLive] = useState<LiveStream | null>(null);
  const [recentUsers, setRecentUsers] = useState<User[]>([]);
  const [totalUsers, setTotalUsers] = useState(0);
  const [storage, setStorage] = useState<StorageStats | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const live = await livesService.getActiveSafe().catch(() => null);
        setActiveLive(live);
        const users = await usersService.getAll();
        setApiOnline(true);
        setTotalUsers(users.length);
        setRecentUsers(
          [...users]
            .sort(
              (a, b) =>
                new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
            )
            .slice(0, 5)
        );
      } catch {
        setApiOnline(false);
      }
      storageService.getStats().then(setStorage).catch(() => setStorage(null));
    };
    load();
    const id = setInterval(load, 15000);
    return () => clearInterval(id);
  }, []);

  return (
    <aside className="w-[280px] h-screen bg-card border-l border-border flex flex-col shrink-0 overflow-hidden">
      {/* API Status */}
      <div className="p-5 border-b border-border">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-medium text-foreground">État du serveur</h3>
          <span
            className={cn(
              "flex items-center gap-1.5 text-xs font-medium",
              apiOnline === false ? "text-destructive" : "text-success"
            )}
          >
            <span
              className={cn(
                "w-2 h-2 rounded-full animate-pulse",
                apiOnline === false ? "bg-destructive" : "bg-success"
              )}
            />
            {apiOnline === null ? "…" : apiOnline ? "En ligne" : "Hors ligne"}
          </span>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="p-3 rounded-xl bg-muted/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1">
              API
            </p>
            <p className="text-lg font-semibold text-foreground flex items-center gap-2">
              {apiOnline === false ? (
                <WifiOff className="w-4 h-4 text-destructive" />
              ) : (
                <Wifi className="w-4 h-4 text-success" />
              )}
              {apiOnline === false ? "Down" : "OK"}
            </p>
          </div>
          <div className="p-3 rounded-xl bg-muted/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1">
              Utilisateurs
            </p>
            <p className="text-lg font-semibold text-foreground">{totalUsers}</p>
          </div>
        </div>
      </div>

      {/* Live en cours */}
      <div className="p-5 border-b border-border">
        <h3 className="text-sm font-medium text-foreground mb-4 flex items-center gap-2">
          <Radio className="w-4 h-4 text-muted-foreground" />
          Live en cours
        </h3>
        {activeLive ? (
          <div className="p-3 rounded-xl bg-destructive/5 border border-destructive/20">
            <div className="flex items-center gap-2 mb-2">
              <span className="w-2 h-2 bg-destructive rounded-full animate-pulse" />
              <span className="text-[10px] font-bold text-destructive uppercase tracking-wider">
                En direct
              </span>
            </div>
            <p className="text-sm font-medium text-foreground truncate">
              {activeLive.title}
            </p>
            <p className="text-xs text-muted-foreground">{activeLive.pastor}</p>
            <p className="text-xs text-muted-foreground mt-2 flex items-center gap-1">
              <Eye className="w-3 h-3" />
              {activeLive.viewerCount || 0} viewer(s)
            </p>
          </div>
        ) : (
          <p className="text-xs text-muted-foreground">Aucun live en cours</p>
        )}
      </div>

      {/* Stockage AWS S3 */}
      {storage?.configured && (
        <div className="p-5 border-b border-border">
          <h3 className="text-sm font-medium text-foreground mb-4 flex items-center gap-2">
            <Database className="w-4 h-4 text-muted-foreground" />
            Stockage AWS S3
          </h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs">
              <span className="text-muted-foreground">{storage.bucket}</span>
              <span className="font-medium text-foreground">
                {formatBytes(storage.totalBytes)} / {storage.quotaGB} Go
              </span>
            </div>
            <div className="w-full h-2 rounded-full bg-muted overflow-hidden">
              <div
                className={cn(
                  "h-full rounded-full transition-all",
                  (storage.usagePercent || 0) > 80
                    ? "bg-destructive"
                    : (storage.usagePercent || 0) > 50
                      ? "bg-warning"
                      : "bg-success"
                )}
                style={{ width: `${Math.min(100, storage.usagePercent || 0)}%` }}
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="p-2.5 rounded-lg bg-muted/50">
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider">
                  Utilisé
                </p>
                <p className="text-sm font-semibold text-foreground">
                  {formatBytes(storage.totalBytes)}
                </p>
              </div>
              <div className="p-2.5 rounded-lg bg-muted/50">
                <p className="text-[10px] text-muted-foreground uppercase tracking-wider">
                  Restant*
                </p>
                <p className="text-sm font-semibold text-success">
                  {formatBytes(storage.remainingBytes)}
                </p>
              </div>
            </div>
            <p className="text-[10px] text-muted-foreground">
              *Référence Free Tier {storage.quotaGB} Go — S3 facture à l'usage
              réel ({storage.objectCount} objet(s)).
            </p>
          </div>
        </div>
      )}

      {/* Derniers utilisateurs */}
      <div className="p-5 flex-1 overflow-y-auto">
        <h3 className="text-sm font-medium text-foreground mb-4 flex items-center gap-2">
          <Users className="w-4 h-4 text-muted-foreground" />
          Derniers inscrits
        </h3>
        <div className="space-y-2">
          {recentUsers.map((u) => (
            <div
              key={u.id}
              className="flex items-center gap-3 p-2 -mx-2 rounded-lg hover:bg-muted/60 transition-colors"
            >
              <div className="w-9 h-9 rounded-full bg-accent/20 flex items-center justify-center text-sm font-medium text-accent-foreground overflow-hidden">
                {u.profileImageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={u.profileImageUrl}
                    alt={u.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  (u.name || "U")[0].toUpperCase()
                )}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">
                  {u.name}
                </p>
                <p className="text-xs text-muted-foreground flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {timeAgo(u.createdAt)}
                </p>
              </div>
            </div>
          ))}
          {recentUsers.length === 0 && (
            <p className="text-xs text-muted-foreground">Aucun utilisateur</p>
          )}
        </div>
      </div>
    </aside>
  );
}
