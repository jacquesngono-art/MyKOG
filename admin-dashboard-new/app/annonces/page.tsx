"use client";

import { useEffect, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Megaphone, Plus, Trash2 } from "lucide-react";
import { annoncesService } from "@/lib/services/annonces";
import type { Annonce } from "@/lib/types";
import { format } from "date-fns";
import { fr } from "date-fns/locale/fr";

type ConfirmState = { kind: "one"; item: Annonce } | { kind: "all" } | null;

export default function AnnoncesPage() {
  const [annonces, setAnnonces] = useState<Annonce[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [form, setForm] = useState({ nom: "", description: "" });

  const [confirm, setConfirm] = useState<ConfirmState>(null);
  const [deleting, setDeleting] = useState(false);

  const load = async () => {
    try {
      const data = await annoncesService.getAll();
      setAnnonces(
        [...data].sort(
          (a, b) =>
            new Date(b.dateCreation).getTime() -
            new Date(a.dateCreation).getTime()
        )
      );
      setError(null);
    } catch (e: any) {
      setError(e.message || "Erreur lors du chargement");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const openCreate = () => {
    setForm({ nom: "", description: "" });
    setFormError(null);
    setDialogOpen(true);
  };

  const submit = async () => {
    if (!form.nom.trim() || !form.description.trim()) {
      setFormError("Le nom et la description sont requis");
      return;
    }
    setSaving(true);
    setFormError(null);
    try {
      await annoncesService.create({
        nom: form.nom.trim(),
        description: form.description.trim(),
      });
      setDialogOpen(false);
      setForm({ nom: "", description: "" });
      await load();
    } catch (e: any) {
      setFormError(e.message || "Erreur lors de la création");
    } finally {
      setSaving(false);
    }
  };

  const runDelete = async () => {
    if (!confirm) return;
    setDeleting(true);
    try {
      if (confirm.kind === "one") {
        await annoncesService.delete(confirm.item.id);
      } else {
        await annoncesService.deleteAll();
      }
      setConfirm(null);
      await load();
    } catch (e: any) {
      setError(e.message || "Erreur lors de la suppression");
      setConfirm(null);
    } finally {
      setDeleting(false);
    }
  };

  const formatDate = (value?: string) => {
    if (!value) return null;
    try {
      const d = new Date(value);
      if (isNaN(d.getTime())) return "Date invalide";
      return `Créée le ${format(d, "dd MMMM yyyy à HH:mm", { locale: fr })}`;
    } catch {
      return "Date invalide";
    }
  };

  return (
    <DashboardShell
      title="Annonces"
      subtitle="Créer et gérer les annonces"
      onRefresh={load}
      actions={
        <div className="flex items-center gap-2">
          {annonces.length > 0 && (
            <Button
              variant="outline"
              size="sm"
              className="gap-2 text-destructive border-destructive/30 hover:bg-destructive/10 hover:text-destructive"
              onClick={() => setConfirm({ kind: "all" })}
            >
              <Trash2 className="w-4 h-4" />
              Tout supprimer
            </Button>
          )}
          <Button size="sm" className="gap-2" onClick={openCreate}>
            <Plus className="w-4 h-4" />
            Nouvelle annonce
          </Button>
        </div>
      }
    >
      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium">
            Annonces publiées ({annonces.length})
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <div className="p-6 space-y-4">
              {[0, 1, 2].map((i) => (
                <div key={i} className="flex items-start gap-4">
                  <Skeleton className="w-10 h-10 rounded-lg shrink-0" />
                  <div className="flex-1 space-y-2">
                    <Skeleton className="h-5 w-1/3" />
                    <Skeleton className="h-4 w-2/3" />
                  </div>
                </div>
              ))}
            </div>
          ) : annonces.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Aucune annonce publiée pour le moment.
            </p>
          ) : (
            <div className="divide-y divide-border">
              {annonces.map((annonce) => (
                <div
                  key={annonce.id}
                  className="p-5 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-start gap-4">
                    <div className="w-10 h-10 rounded-lg bg-accent/15 flex items-center justify-center shrink-0">
                      <Megaphone className="w-5 h-5 text-accent-foreground" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <h3 className="font-semibold text-foreground mb-1">
                            {annonce.nom}
                          </h3>
                          <p className="text-sm text-muted-foreground whitespace-pre-wrap mb-2">
                            {annonce.description}
                          </p>
                          {formatDate(annonce.dateCreation) && (
                            <p className="text-xs text-muted-foreground">
                              {formatDate(annonce.dateCreation)}
                            </p>
                          )}
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="shrink-0"
                          onClick={() => setConfirm({ kind: "one", item: annonce })}
                          title="Supprimer"
                        >
                          <Trash2 className="w-4 h-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Dialog création */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Megaphone className="w-4 h-4" />
              Nouvelle annonce
            </DialogTitle>
          </DialogHeader>

          {formError && (
            <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
              {formError}
            </div>
          )}

          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label>Nom *</Label>
              <Input
                value={form.nom}
                onChange={(e) => setForm({ ...form, nom: e.target.value })}
                placeholder="Titre de l'annonce"
              />
            </div>
            <div className="space-y-2">
              <Label>Description *</Label>
              <Textarea
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
                rows={6}
                placeholder="Description détaillée de l'annonce…"
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Annuler
            </Button>
            <Button
              onClick={submit}
              disabled={saving || !form.nom.trim() || !form.description.trim()}
            >
              {saving ? "Publication…" : "Publier"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmation de suppression */}
      <AlertDialog open={!!confirm} onOpenChange={(o) => !o && setConfirm(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {confirm?.kind === "all"
                ? "Supprimer toutes les annonces ?"
                : "Supprimer cette annonce ?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {confirm?.kind === "all"
                ? `Cette action supprimera définitivement les ${annonces.length} annonces.`
                : `« ${confirm?.kind === "one" ? confirm.item.nom : ""} » sera définitivement supprimée.`}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Annuler</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => {
                e.preventDefault();
                runDelete();
              }}
              disabled={deleting}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleting ? "Suppression…" : "Supprimer"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </DashboardShell>
  );
}
