"use client";

import { useEffect, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Radio,
  Plus,
  Copy,
  Check,
  Eye,
  Trash2,
  Play,
  Square,
  KeyRound,
  Server,
} from "lucide-react";
import { livesService } from "@/lib/services/lives";
import type { LiveStream, ServerInfo } from "@/lib/types";
import { format } from "date-fns";
import { fr } from "date-fns/locale/fr";

const statusBadge: Record<string, { label: string; className: string }> = {
  live: { label: "En direct", className: "bg-destructive/15 text-destructive border-destructive/30" },
  scheduled: { label: "Programmé", className: "bg-warning/20 text-warning border-warning/30" },
  ended: { label: "Terminé", className: "bg-muted text-muted-foreground border-border" },
};

function CopyField({ label, value, mono = true }: { label: string; value: string; mono?: boolean }) {
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
        <code
          className={`flex-1 px-3 py-2 rounded-lg bg-muted/60 border border-border text-sm truncate ${
            mono ? "font-mono" : ""
          }`}
        >
          {value}
        </code>
        <Button variant="outline" size="sm" onClick={copy} className="gap-1.5 shrink-0">
          {copied ? <Check className="w-3.5 h-3.5 text-success" /> : <Copy className="w-3.5 h-3.5" />}
          {copied ? "Copié" : "Copier"}
        </Button>
      </div>
    </div>
  );
}

export default function LivesPage() {
  const [lives, setLives] = useState<LiveStream[]>([]);
  const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    title: "",
    pastor: "",
    description: "",
    scheduledAt: "",
    status: "scheduled" as "scheduled" | "live" | "ended",
    tags: "",
  });

  const load = async () => {
    try {
      const [l, info] = await Promise.all([
        livesService.getAll(),
        livesService.getServerInfo().catch(() => null),
      ]);
      setLives(l);
      setServerInfo(info);
      setError(null);
    } catch (e: any) {
      setError(e.message || "Erreur de chargement");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    const id = setInterval(load, 15000);
    return () => clearInterval(id);
  }, []);

  const createLive = async () => {
    if (!form.title.trim() || !form.pastor.trim()) return;
    setSaving(true);
    try {
      await livesService.create({
        title: form.title.trim(),
        pastor: form.pastor.trim(),
        description: form.description.trim() || undefined,
        scheduledAt: form.scheduledAt || undefined,
        status: form.status,
        tags: form.tags.split(",").map((t) => t.trim()).filter(Boolean),
      } as Partial<LiveStream>);
      setDialogOpen(false);
      setForm({ title: "", pastor: "", description: "", scheduledAt: "", status: "scheduled", tags: "" });
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  const setStatus = async (id: string, status: "live" | "ended") => {
    try {
      await livesService.updateStatus(id, status);
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  };

  const remove = async (id: string) => {
    if (!confirm("Supprimer ce live et ses commentaires ?")) return;
    try {
      await livesService.delete(id);
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  };

  const rtmpUrl = (serverInfo as any)?.rtmpUrl || "rtmp://185.98.128.123:1935/live";
  const streamKey = (serverInfo as any)?.streamKey || "—";

  return (
    <DashboardShell
      title="Lives"
      subtitle="Diffusion en direct & configuration OBS"
      onRefresh={load}
      actions={
        <Button size="sm" className="gap-2" onClick={() => setDialogOpen(true)}>
          <Plus className="w-4 h-4" />
          Nouveau live
        </Button>
      }
    >
      {/* Config OBS permanente */}
      <Card className="mb-6 border-accent/40">
        <CardHeader>
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <Radio className="w-4 h-4 text-accent-foreground" />
            Configuration OBS — permanente
            <Badge variant="outline" className="ml-auto text-[10px] border-success/40 text-success">
              À configurer une seule fois
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <CopyField label="Serveur (Server)" value={rtmpUrl} />
          <CopyField label="Clé de stream (Stream Key)" value={streamKey} />
          <div className="md:col-span-2 flex items-center gap-2 text-xs text-muted-foreground">
            <Server className="w-3.5 h-3.5" />
            <span>
              OBS → Paramètres → Stream → Service « Custom… ». Le live démarre et s'arrête
              automatiquement avec OBS.
            </span>
          </div>
        </CardContent>
      </Card>

      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}

      {/* Liste des lives */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium">
            Lives ({lives.length})
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <p className="p-8 text-center text-sm text-muted-foreground">Chargement…</p>
          ) : lives.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Aucun live. Démarrez OBS pour créer un live automatiquement, ou créez-en un manuellement.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Titre</TableHead>
                  <TableHead>Pasteur</TableHead>
                  <TableHead>Statut</TableHead>
                  <TableHead className="text-center">Viewers</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {lives.map((live) => {
                  const st = statusBadge[live.status] || statusBadge.scheduled;
                  return (
                    <TableRow key={live.id}>
                      <TableCell className="font-medium max-w-[220px] truncate">
                        {live.title}
                      </TableCell>
                      <TableCell className="text-muted-foreground">{live.pastor}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className={st.className}>
                          {live.status === "live" && (
                            <span className="w-1.5 h-1.5 rounded-full bg-destructive animate-pulse mr-1.5" />
                          )}
                          {st.label}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-center">
                        <span className="inline-flex items-center gap-1 text-sm">
                          <Eye className="w-3.5 h-3.5 text-muted-foreground" />
                          {live.viewerCount || 0}
                        </span>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {live.startedAt || live.scheduledAt
                          ? format(
                              new Date(live.startedAt || live.scheduledAt!),
                              "dd MMM HH:mm",
                              { locale: fr }
                            )
                          : "—"}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          {live.status !== "live" && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setStatus(live.id, "live")}
                              title="Démarrer"
                            >
                              <Play className="w-4 h-4 text-success" />
                            </Button>
                          )}
                          {live.status === "live" && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setStatus(live.id, "ended")}
                              title="Terminer"
                            >
                              <Square className="w-4 h-4 text-warning" />
                            </Button>
                          )}
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => remove(live.id)}
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4 text-destructive" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Dialog création */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <KeyRound className="w-4 h-4" /> Nouveau live
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Titre *</Label>
                <Input
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  placeholder="Culte du dimanche"
                />
              </div>
              <div className="space-y-2">
                <Label>Pasteur *</Label>
                <Input
                  value={form.pastor}
                  onChange={(e) => setForm({ ...form, pastor: e.target.value })}
                  placeholder="Pasteur…"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                rows={2}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Date programmée</Label>
                <Input
                  type="datetime-local"
                  value={form.scheduledAt}
                  onChange={(e) => setForm({ ...form, scheduledAt: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label>Statut</Label>
                <Select
                  value={form.status}
                  onValueChange={(v) =>
                    setForm({ ...form, status: v as typeof form.status })
                  }
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="scheduled">Programmé</SelectItem>
                    <SelectItem value="live">En direct</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label>Tags (virgules)</Label>
              <Input
                value={form.tags}
                onChange={(e) => setForm({ ...form, tags: e.target.value })}
                placeholder="culte, prière"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Annuler
            </Button>
            <Button onClick={createLive} disabled={saving || !form.title.trim() || !form.pastor.trim()}>
              {saving ? "Création…" : "Créer"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </DashboardShell>
  );
}
