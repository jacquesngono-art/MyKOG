"use client";

import { useEffect, useRef, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogCancel,
  AlertDialogAction,
} from "@/components/ui/alert-dialog";
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  BookOpen,
  Plus,
  Play,
  Pause,
  Pencil,
  Trash2,
  Search,
  List,
  LayoutGrid,
  ListFilter,
  Headphones,
  MoreVertical,
  Loader2,
  AlertTriangle,
} from "lucide-react";
import { enseignementsService } from "@/lib/services/enseignements";
import type { Enseignement } from "@/lib/types";
import {
  EnseignementCreateDialog,
  EnseignementEditDialog,
  MOIS_OPTIONS,
  TYPE_CULTE_OPTIONS,
} from "@/components/dashboard/enseignements-form";
import { format } from "date-fns";
import { fr } from "date-fns/locale/fr";

const ALL = "__all__";

function formatDuration(seconds: number) {
  if (!seconds) return "—";
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, "0")} min`;
}

export default function EnseignementsPage() {
  const [items, setItems] = useState<Enseignement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");

  const [createOpen, setCreateOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<Enseignement | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Enseignement | null>(null);
  const [deleteAllOpen, setDeleteAllOpen] = useState(false);
  const [filterOpen, setFilterOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const [filter, setFilter] = useState({
    category: ALL,
    mois: ALL,
    annee: ALL,
    typeCulte: ALL,
  });

  // Lecteur audio — une seule instance partagée
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [playingId, setPlayingId] = useState<string | null>(null);

  const togglePlay = (e: Enseignement) => {
    if (playingId === e.id) {
      audioRef.current?.pause();
      audioRef.current = null;
      setPlayingId(null);
      return;
    }
    audioRef.current?.pause();
    audioRef.current = null;
    if (!e.audioUrl) return;
    const audio = new Audio(e.audioUrl);
    audio.onended = () => setPlayingId(null);
    audio.onerror = () => setPlayingId(null);
    audio.play().catch(() => setPlayingId(null));
    audioRef.current = audio;
    setPlayingId(e.id);
  };

  useEffect(() => {
    return () => {
      audioRef.current?.pause();
      audioRef.current = null;
    };
  }, []);

  const load = async () => {
    try {
      const data = await enseignementsService.getAll();
      setItems(
        [...data].sort(
          (a, b) =>
            new Date(b.publishedAt || 0).getTime() -
            new Date(a.publishedAt || 0).getTime()
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

  const q = search.trim().toLowerCase();
  const filtered = q
    ? items.filter((e) =>
        [e.title, e.speaker, e.category, e.typeCulte, ...(e.tags || [])]
          .filter(Boolean)
          .some((v) => String(v).toLowerCase().includes(q))
      )
    : items;

  const categories = [...new Set(items.map((e) => e.category).filter(Boolean))];
  const annees = [...new Set(items.map((e) => String(e.annee || "")).filter(Boolean))].sort().reverse();

  const filterCount = items.filter(
    (e) =>
      (filter.category === ALL || e.category === filter.category) &&
      (filter.mois === ALL || String(e.mois) === filter.mois) &&
      (filter.annee === ALL || String(e.annee) === filter.annee) &&
      (filter.typeCulte === ALL || e.typeCulte === filter.typeCulte)
  ).length;

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await enseignementsService.delete(deleteTarget.id);
      setDeleteTarget(null);
      setNotice(`« ${deleteTarget.title} » supprimé`);
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  const confirmDeleteAll = async () => {
    setDeleting(true);
    try {
      const res = await enseignementsService.deleteAll();
      setDeleteAllOpen(false);
      setNotice(`${res.deleted ?? items.length} enseignement(s) supprimé(s)`);
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  const confirmDeleteByFilter = async () => {
    setDeleting(true);
    try {
      const res = await enseignementsService.deleteByFilter({
        category: filter.category !== ALL ? filter.category : undefined,
        mois: filter.mois !== ALL ? filter.mois : undefined,
        annee: filter.annee !== ALL ? filter.annee : undefined,
        typeCulte: filter.typeCulte !== ALL ? filter.typeCulte : undefined,
      });
      setFilterOpen(false);
      setNotice(`${res.deleted ?? filterCount} enseignement(s) supprimé(s)`);
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  const badges = (e: Enseignement) => (
    <div className="flex flex-wrap gap-1.5">
      <Badge variant="outline" className="bg-muted/60 text-muted-foreground border-border">
        {e.category}
      </Badge>
      {e.typeCulte && (
        <Badge variant="outline" className="bg-accent/15 text-accent-foreground border-accent/30">
          {e.typeCulte}
        </Badge>
      )}
      {e.isNew && (
        <Badge variant="outline" className="bg-success/15 text-success border-success/30">
          Nouveau
        </Badge>
      )}
      {e.isFeatured && (
        <Badge variant="outline" className="bg-warning/15 text-warning border-warning/30">
          Mis en avant
        </Badge>
      )}
    </div>
  );

  const playButton = (e: Enseignement) => (
    <Button
      variant="ghost"
      size="sm"
      onClick={() => togglePlay(e)}
      disabled={!e.audioUrl}
      title={playingId === e.id ? "Pause" : "Écouter"}
    >
      {playingId === e.id ? (
        <Pause className="w-4 h-4 text-accent-foreground" />
      ) : (
        <Play className="w-4 h-4 text-muted-foreground" />
      )}
    </Button>
  );

  const rowActions = (e: Enseignement) => (
    <div className="flex justify-end gap-1">
      {playButton(e)}
      <Button
        variant="ghost"
        size="sm"
        onClick={() => setEditTarget(e)}
        title="Modifier"
      >
        <Pencil className="w-4 h-4 text-muted-foreground" />
      </Button>
      <Button
        variant="ghost"
        size="sm"
        onClick={() => setDeleteTarget(e)}
        title="Supprimer"
      >
        <Trash2 className="w-4 h-4 text-destructive" />
      </Button>
    </div>
  );

  return (
    <DashboardShell
      title="Enseignements"
      subtitle="Publier des enseignements avec audio et image"
      onRefresh={load}
      actions={
        <>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="gap-2 bg-transparent">
                <Trash2 className="w-4 h-4" />
                Suppression
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={() => setFilterOpen(true)}>
                <ListFilter className="w-4 h-4" />
                Supprimer par filtre…
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                className="text-destructive focus:text-destructive"
                onClick={() => setDeleteAllOpen(true)}
              >
                <AlertTriangle className="w-4 h-4" />
                Tout supprimer…
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <Button size="sm" className="gap-2" onClick={() => setCreateOpen(true)}>
            <Plus className="w-4 h-4" />
            Nouvel enseignement
          </Button>
        </>
      }
    >
      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}
      {notice && (
        <div className="mb-4 p-3 rounded-xl bg-success/10 border border-success/25 text-success text-sm">
          {notice}
        </div>
      )}

      {/* Barre d'outils : recherche + vue */}
      <div className="flex items-center gap-3 mb-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Rechercher (titre, orateur, tag…)"
            className="pl-9"
          />
        </div>
        <div className="flex items-center bg-card border border-border rounded-lg p-1 ml-auto">
          <button
            onClick={() => setViewMode("list")}
            className={`p-1.5 rounded-md transition-colors ${
              viewMode === "list"
                ? "bg-accent/15 text-accent-foreground"
                : "text-muted-foreground hover:text-foreground"
            }`}
            title="Vue liste"
          >
            <List className="w-4 h-4" />
          </button>
          <button
            onClick={() => setViewMode("grid")}
            className={`p-1.5 rounded-md transition-colors ${
              viewMode === "grid"
                ? "bg-accent/15 text-accent-foreground"
                : "text-muted-foreground hover:text-foreground"
            }`}
            title="Vue grille"
          >
            <LayoutGrid className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Liste */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <BookOpen className="w-4 h-4 text-muted-foreground" />
            Enseignements publiés ({filtered.length})
          </CardTitle>
        </CardHeader>
        <CardContent className={viewMode === "list" ? "p-0" : ""}>
          {loading ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Chargement…
            </p>
          ) : filtered.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              {q
                ? "Aucun enseignement ne correspond à la recherche."
                : "Aucun enseignement publié pour le moment."}
            </p>
          ) : viewMode === "grid" ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filtered.map((e) => (
                <div
                  key={e.id}
                  className="rounded-xl border border-border bg-card overflow-hidden hover:border-accent/40 transition-colors"
                >
                  <div className="relative">
                    {e.artworkUrl ? (
                      /* eslint-disable-next-line @next/next/no-img-element */
                      <img
                        src={e.artworkUrl}
                        alt={e.title}
                        className="w-full h-40 object-cover"
                      />
                    ) : (
                      <div className="w-full h-40 bg-muted/50 flex items-center justify-center">
                        <BookOpen className="w-8 h-8 text-muted-foreground" />
                      </div>
                    )}
                    <button
                      onClick={() => togglePlay(e)}
                      disabled={!e.audioUrl}
                      className="absolute bottom-3 left-3 w-9 h-9 rounded-full bg-background/90 border border-border flex items-center justify-center hover:bg-background transition-colors disabled:opacity-50"
                      title={playingId === e.id ? "Pause" : "Écouter"}
                    >
                      {playingId === e.id ? (
                        <Pause className="w-4 h-4 text-accent-foreground" />
                      ) : (
                        <Play className="w-4 h-4 text-foreground" />
                      )}
                    </button>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-background/90 border border-border flex items-center justify-center hover:bg-background transition-colors">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => setEditTarget(e)}>
                          <Pencil className="w-4 h-4" /> Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-destructive focus:text-destructive"
                          onClick={() => setDeleteTarget(e)}
                        >
                          <Trash2 className="w-4 h-4" /> Supprimer
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  <div className="p-4 space-y-2">
                    <h3 className="font-semibold text-sm line-clamp-2">
                      {e.title}
                    </h3>
                    <p className="text-xs text-muted-foreground">
                      {e.speaker}
                    </p>
                    {e.description && (
                      <p className="text-xs text-muted-foreground line-clamp-2">
                        {e.description}
                      </p>
                    )}
                    {badges(e)}
                    <div className="flex items-center justify-between text-[11px] text-muted-foreground pt-1">
                      <span className="inline-flex items-center gap-1">
                        <Headphones className="w-3 h-3" /> {e.playCount || 0}
                      </span>
                      <span>
                        {e.publishedAt
                          ? format(new Date(e.publishedAt), "dd MMM yyyy", {
                              locale: fr,
                            })
                          : "—"}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[64px]"></TableHead>
                  <TableHead>Titre</TableHead>
                  <TableHead>Catégorie</TableHead>
                  <TableHead>Durée</TableHead>
                  <TableHead className="text-center">Écoutes</TableHead>
                  <TableHead>Publié le</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell>
                      {e.artworkUrl ? (
                        /* eslint-disable-next-line @next/next/no-img-element */
                        <img
                          src={e.artworkUrl}
                          alt={e.title}
                          className="w-12 h-12 rounded-lg object-cover"
                        />
                      ) : (
                        <div className="w-12 h-12 rounded-lg bg-muted/50 flex items-center justify-center">
                          <BookOpen className="w-4 h-4 text-muted-foreground" />
                        </div>
                      )}
                    </TableCell>
                    <TableCell className="max-w-[280px]">
                      <p className="font-medium truncate">{e.title}</p>
                      <p className="text-xs text-muted-foreground truncate">
                        {e.speaker}
                      </p>
                      {e.tags && e.tags.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-1">
                          {e.tags.slice(0, 3).map((t) => (
                            <span
                              key={t}
                              className="px-1.5 py-0.5 text-[10px] rounded bg-accent/15 text-accent-foreground"
                            >
                              {t}
                            </span>
                          ))}
                        </div>
                      )}
                    </TableCell>
                    <TableCell>{badges(e)}</TableCell>
                    <TableCell className="text-xs text-muted-foreground whitespace-nowrap">
                      {formatDuration(e.duration)}
                    </TableCell>
                    <TableCell className="text-center">
                      <span className="inline-flex items-center gap-1 text-sm">
                        <Headphones className="w-3.5 h-3.5 text-muted-foreground" />
                        {e.playCount || 0}
                      </span>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground whitespace-nowrap">
                      {e.publishedAt
                        ? format(new Date(e.publishedAt), "dd MMM yyyy", {
                            locale: fr,
                          })
                        : "—"}
                    </TableCell>
                    <TableCell className="text-right">{rowActions(e)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Dialog création */}
      <EnseignementCreateDialog
        open={createOpen}
        onOpenChange={setCreateOpen}
        onCreated={async () => {
          setNotice("Enseignement créé avec succès");
          await load();
        }}
      />

      {/* Dialog édition */}
      <EnseignementEditDialog
        enseignement={editTarget}
        onClose={() => setEditTarget(null)}
        onSaved={async () => {
          setEditTarget(null);
          setNotice("Enseignement mis à jour");
          await load();
        }}
      />

      {/* Confirmation suppression unitaire */}
      <AlertDialog
        open={!!deleteTarget}
        onOpenChange={(o) => !o && setDeleteTarget(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Supprimer cet enseignement ?</AlertDialogTitle>
            <AlertDialogDescription>
              « {deleteTarget?.title} » sera définitivement supprimé, ainsi que
              ses fichiers image et audio. Cette action est irréversible.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Annuler</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => {
                e.preventDefault();
                confirmDelete();
              }}
              disabled={deleting}
              className="bg-destructive text-white hover:bg-destructive/90"
            >
              {deleting ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                "Supprimer"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Confirmation suppression totale */}
      <AlertDialog open={deleteAllOpen} onOpenChange={setDeleteAllOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-destructive" />
              Supprimer tous les enseignements ?
            </AlertDialogTitle>
            <AlertDialogDescription>
              Les {items.length} enseignements et leurs fichiers (images,
              audios) seront définitivement supprimés. Cette action est
              irréversible.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Annuler</AlertDialogCancel>
            <AlertDialogAction
              onClick={(e) => {
                e.preventDefault();
                confirmDeleteAll();
              }}
              disabled={deleting}
              className="bg-destructive text-white hover:bg-destructive/90"
            >
              {deleting ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                "Tout supprimer"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Suppression par filtre */}
      <Dialog open={filterOpen} onOpenChange={setFilterOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <ListFilter className="w-4 h-4" /> Suppression par filtre
            </DialogTitle>
            <DialogDescription>
              Supprime tous les enseignements correspondant aux critères
              sélectionnés.
            </DialogDescription>
          </DialogHeader>
          <div className="grid grid-cols-2 gap-4 py-2">
            <div className="space-y-2">
              <Label>Catégorie</Label>
              <Select
                value={filter.category}
                onValueChange={(v) => setFilter({ ...filter, category: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={ALL}>Toutes</SelectItem>
                  {categories.map((c) => (
                    <SelectItem key={c} value={c}>
                      {c}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Type de culte</Label>
              <Select
                value={filter.typeCulte}
                onValueChange={(v) => setFilter({ ...filter, typeCulte: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={ALL}>Tous</SelectItem>
                  {TYPE_CULTE_OPTIONS.map((t) => (
                    <SelectItem key={t} value={t}>
                      {t}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Mois</Label>
              <Select
                value={filter.mois}
                onValueChange={(v) => setFilter({ ...filter, mois: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={ALL}>Tous</SelectItem>
                  {MOIS_OPTIONS.map((m) => (
                    <SelectItem key={m.value} value={m.value}>
                      {m.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Année</Label>
              <Select
                value={filter.annee}
                onValueChange={(v) => setFilter({ ...filter, annee: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={ALL}>Toutes</SelectItem>
                  {annees.map((a) => (
                    <SelectItem key={a} value={a}>
                      {a}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 shrink-0" />
            <span>
              {filterCount} enseignement(s) correspondent à ces filtres et
              seront supprimés définitivement.
            </span>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setFilterOpen(false)}
              disabled={deleting}
            >
              Annuler
            </Button>
            <Button
              variant="destructive"
              onClick={confirmDeleteByFilter}
              disabled={deleting || filterCount === 0}
            >
              {deleting ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Suppression…
                </>
              ) : (
                `Supprimer (${filterCount})`
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </DashboardShell>
  );
}
