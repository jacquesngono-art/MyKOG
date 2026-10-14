"use client";

import { useEffect, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import {
  Server,
  Check,
  Copy,
  RefreshCw,
  Wifi,
  WifiOff,
  Bell,
  Database,
  Info,
  Loader2,
  Cloud,
  ShieldCheck,
} from "lucide-react";
import { storageService, formatBytes, type StorageStats } from "@/lib/services/storage";
import { authService } from "@/lib/services/auth";
import { toast } from "sonner";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api";

type Health = {
  status: "idle" | "checking" | "online" | "offline";
  latencyMs?: number;
  httpStatus?: number;
  checkedAt?: Date;
  error?: string;
};

function CopyValue({ label, value }: { label: string; value: string }) {
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {}
  };
  return (
    <div>
      <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1.5">
        {label}
      </p>
      <div className="flex items-center gap-2">
        <code className="flex-1 px-3 py-2 rounded-lg bg-muted/60 border border-border text-sm font-mono truncate">
          {value}
        </code>
        <Button
          variant="outline"
          size="sm"
          onClick={copy}
          className="gap-1.5 shrink-0"
        >
          {copied ? (
            <Check className="w-3.5 h-3.5 text-success" />
          ) : (
            <Copy className="w-3.5 h-3.5" />
          )}
          {copied ? "Copié" : "Copier"}
        </Button>
      </div>
    </div>
  );
}

function PasswordCard() {
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    setError(null);
    if (!currentPassword || !newPassword) {
      setError("Tous les champs sont requis");
      return;
    }
    if (newPassword !== confirmPassword) {
      setError("Les nouveaux mots de passe ne correspondent pas");
      return;
    }
    setSaving(true);
    try {
      await authService.updatePassword(currentPassword, newPassword);
      toast.success("Mot de passe mis à jour");
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (e: any) {
      setError(e.message || "Erreur lors de la mise à jour");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm font-medium flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-accent-foreground" />
          Sécurité
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-muted-foreground">
          Le mot de passe est stocké dans Firebase. Il remplace le mot de passe
          par défaut dès la première modification.
        </p>
        <div className="space-y-2">
          <Label>Mot de passe actuel</Label>
          <Input
            type="password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label>Nouveau mot de passe</Label>
          <Input
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
          />
        </div>
        <div className="space-y-2">
          <Label>Confirmer le nouveau mot de passe</Label>
          <Input
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
          />
        </div>
        {error && (
          <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
            {error}
          </div>
        )}
        <Button
          onClick={submit}
          disabled={saving || !currentPassword || !newPassword || !confirmPassword}
          className="gap-2"
        >
          {saving && <Loader2 className="w-4 h-4 animate-spin" />}
          Mettre à jour le mot de passe
        </Button>
      </CardContent>
    </Card>
  );
}

export default function SettingsPage() {
  const [health, setHealth] = useState<Health>({ status: "idle" });
  const [storage, setStorage] = useState<StorageStats | null>(null);

  const checkHealth = async () => {
    setHealth({ status: "checking" });
    const started = performance.now();
    const ctrl = new AbortController();
    const id = setTimeout(() => ctrl.abort(), 10000);
    try {
      const res = await fetch(`${API_BASE}/lives`, { signal: ctrl.signal });
      clearTimeout(id);
      setHealth({
        status: res.ok ? "online" : "offline",
        latencyMs: Math.round(performance.now() - started),
        httpStatus: res.status,
        checkedAt: new Date(),
        error: res.ok ? undefined : `HTTP ${res.status}`,
      });
    } catch (e: any) {
      clearTimeout(id);
      setHealth({
        status: "offline",
        latencyMs: Math.round(performance.now() - started),
        checkedAt: new Date(),
        error:
          e.name === "AbortError"
            ? "Délai dépassé (10 s)"
            : "API injoignable (réseau / CORS)",
      });
    }
  };

  useEffect(() => {
    checkHealth();
    storageService.getStats().then(setStorage).catch(() => setStorage(null));
  }, []);

  const healthBadge =
    health.status === "online" ? (
      <Badge
        variant="outline"
        className="gap-1.5 border-success/40 text-success"
      >
        <Wifi className="w-3 h-3" />
        En ligne
      </Badge>
    ) : health.status === "offline" ? (
      <Badge
        variant="outline"
        className="gap-1.5 border-destructive/40 text-destructive"
      >
        <WifiOff className="w-3 h-3" />
        Hors ligne
      </Badge>
    ) : (
      <Badge variant="outline" className="gap-1.5 text-muted-foreground">
        <Loader2 className="w-3 h-3 animate-spin" />
        Vérification…
      </Badge>
    );

  return (
    <DashboardShell
      title="Paramètres"
      subtitle="Configuration et état de l'API"
      onRefresh={checkHealth}
    >
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 max-w-5xl">
        {/* API */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Server className="w-4 h-4 text-accent-foreground" />
              API Backend
              <span className="ml-auto">{healthBadge}</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <CopyValue label="URL de base (NEXT_PUBLIC_API_URL)" value={API_BASE} />

            <Separator />

            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">
                Santé de l'API{" "}
                <code className="text-xs font-mono">GET /lives</code>
              </span>
              <div className="flex items-center gap-3">
                {health.latencyMs !== undefined && (
                  <span className="text-xs text-muted-foreground tabular-nums">
                    {health.latencyMs} ms
                    {health.httpStatus ? ` · HTTP ${health.httpStatus}` : ""}
                  </span>
                )}
                <Button
                  variant="outline"
                  size="sm"
                  className="gap-1.5"
                  onClick={checkHealth}
                  disabled={health.status === "checking"}
                >
                  <RefreshCw
                    className={`w-3.5 h-3.5 ${
                      health.status === "checking" ? "animate-spin" : ""
                    }`}
                  />
                  Vérifier
                </Button>
              </div>
            </div>

            {health.error && (
              <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
                {health.error}
              </div>
            )}

            {health.checkedAt && (
              <p className="text-xs text-muted-foreground">
                Dernière vérification :{" "}
                {health.checkedAt.toLocaleTimeString("fr-FR")}
              </p>
            )}
          </CardContent>
        </Card>

        {/* Sécurité */}
        <PasswordCard />

        {/* Notifications */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Bell className="w-4 h-4 text-accent-foreground" />
              Notifications push
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm text-muted-foreground">
            <p>
              Les notifications sont envoyées via{" "}
              <span className="font-medium text-foreground">
                Firebase Cloud Messaging (FCM)
              </span>{" "}
              depuis le backend. Les tokens des appareils sont enregistrés sur{" "}
              <code className="text-xs font-mono">/notifications/tokens</code>.
            </p>
            <p>
              Envoi depuis la page{" "}
              <code className="text-xs font-mono">/notifications</code> — à tous
              les utilisateurs, à un utilisateur précis ou à un topic FCM.
            </p>
          </CardContent>
        </Card>

        {/* Stockage AWS S3 */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Cloud className="w-4 h-4 text-accent-foreground" />
              Stockage AWS S3
              {storage?.configured && (
                <Badge variant="outline" className="ml-auto border-success/40 text-success">
                  {storage.provider?.toUpperCase()} · {storage.region}
                </Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {storage?.configured ? (
              <>
                <div>
                  <div className="flex items-center justify-between text-sm mb-2">
                    <span className="text-muted-foreground">
                      Bucket <code className="text-xs font-mono">{storage.bucket}</code>
                    </span>
                    <span className="font-medium">
                      {formatBytes(storage.totalBytes)} / {storage.quotaGB} Go
                    </span>
                  </div>
                  <div className="w-full h-2.5 rounded-full bg-muted overflow-hidden">
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
                  <div className="flex items-center justify-between text-xs text-muted-foreground mt-1.5">
                    <span>{storage.usagePercent}% utilisé</span>
                    <span>{storage.objectCount} objet(s)</span>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="p-3 rounded-xl bg-muted/50">
                    <p className="text-[10px] text-muted-foreground uppercase tracking-wider mb-1">
                      Mémoire occupée
                    </p>
                    <p className="text-lg font-semibold text-foreground">
                      {formatBytes(storage.totalBytes)}
                    </p>
                  </div>
                  <div className="p-3 rounded-xl bg-muted/50">
                    <p className="text-[10px] text-muted-foreground uppercase tracking-wider mb-1">
                      Mémoire restante*
                    </p>
                    <p className="text-lg font-semibold text-success">
                      {formatBytes(storage.remainingBytes)}
                    </p>
                  </div>
                </div>

                {storage.breakdown && Object.keys(storage.breakdown).length > 0 && (
                  <>
                    <Separator />
                    <div className="space-y-2">
                      <p className="text-[11px] text-muted-foreground uppercase tracking-wider">
                        Répartition
                      </p>
                      {Object.entries(storage.breakdown).map(([prefix, b]) => (
                        <div key={prefix} className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground font-mono text-xs">
                            {prefix}/
                          </span>
                          <span className="font-medium">
                            {formatBytes(b.bytes)}
                            <span className="text-xs text-muted-foreground ml-2">
                              ({b.count} fich.)
                            </span>
                          </span>
                        </div>
                      ))}
                    </div>
                  </>
                )}

                <p className="text-[11px] text-muted-foreground">
                  *Référence {storage.quotaGB} Go (AWS Free Tier). S3 n'a pas de
                  limite fixe — la facturation dépend de l'usage réel.
                </p>
              </>
            ) : (
              <p className="text-sm text-muted-foreground">
                {storage?.message ||
                  "Statistiques de stockage indisponibles (endpoint /storage/stats injoignable)."}
              </p>
            )}
          </CardContent>
        </Card>

        {/* Application */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Info className="w-4 h-4 text-accent-foreground" />
              Application
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-0 text-sm">
            {[
              { k: "Console", v: "MyKOG Admin Dashboard" },
              { k: "Framework", v: "Next.js 16 · React 19" },
              {
                k: "Environnement",
                v: process.env.NODE_ENV || "development",
              },
              { k: "Timeout requêtes", v: "30 s" },
            ].map((row, i, arr) => (
              <div key={row.k}>
                <div className="flex items-center justify-between py-2.5">
                  <span className="text-muted-foreground">{row.k}</span>
                  <span className="font-medium">{row.v}</span>
                </div>
                {i < arr.length - 1 && <Separator />}
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </DashboardShell>
  );
}
