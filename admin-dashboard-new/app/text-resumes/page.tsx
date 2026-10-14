"use client";

import { useEffect, useRef, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
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
  DialogDescription,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  FileText,
  Plus,
  Trash2,
  Pencil,
  Eye,
  Image as ImageIcon,
  FilterX,
  List,
  LayoutGrid,
  MoreVertical,
} from "lucide-react";
import { textResumesService } from "@/lib/services/textResumes";
import type { TextResume } from "@/lib/types";
import { format } from "date-fns";
import { fr } from "date-fns/locale/fr";
import { toast } from "sonner";

const CATEGORIES = ["Enseignement", "Foi", "Prière", "Amour", "Espérance"];
const TYPES_CULTE = [
  "Culte de Louange",
  "Culte de Prière",
  "Culte d'Impact",
  "Culte Prophétique",
  "Culte d'Enseignement",
  "Étude Biblique",
  "Conférence",
  "Séminaire",
  "Autre",
];
const MOIS_LABELS = [
  "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
  "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
];
const SORT_OPTIONS = [
  { value: "publishedAt", label: "Date de publication" },
  { value: "viewCount", label: "Vues" },
  { value: "title", label: "Titre" },
  { value: "speaker", label: "Orateur" },
];
const CURRENT_YEAR = new Date().getFullYear();
const ANNEES = Array.from({ length: 6 }, (_, i) => String(CURRENT_YEAR - i));

interface Filters {
  category: string;
  mois: string;
  annee: string;
  typeCulte: string;
  sortBy: string;
  order: string;
}

const DEFAULT_FILTERS: Filters = {
  category: "All",
  mois: "All",
  annee: "All",
  typeCulte: "All",
  sortBy: "publishedAt",
  order: "desc",
};

const emptyForm = {
  title: "",
  speaker: "",
  description: "",
  category: "Enseignement",
  tags: "",
  mois: String(new Date().getMonth() + 1),
  annee: String(CURRENT_YEAR),
  typeCulte: "Culte de Louange",
};

type ConfirmState =
  | { kind: "one"; item: TextResume }
  | { kind: "all" }
  | { kind: "filtered" }
  | null;

function PdfFirstPage({
  url,
  title,
  className,
}: {
  url: string;
  title: string;
  className: string;
}) {
  return (
    <iframe
      src={`${url}#page=1&toolbar=0&navpanes=0&scrollbar=0&view=FitH`}
      title={`Aperçu — ${title}`}
      className={`pointer-events-none bg-muted/50 ${className}`}
      loading="lazy"
      tabIndex={-1}
    />
  );
}

export default function TextResumesPage() {
  const [items, setItems] = useState<TextResume[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<Filters>(DEFAULT_FILTERS);
  const [viewMode, setViewMode] = useState<"list" | "grid">("grid");

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<TextResume | null>(null);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

  const [confirm, setConfirm] = useState<ConfirmState>(null);
  const [deleting, setDeleting] = useState(false);

  const hasActiveFilters =
    filters.category !== "All" ||
    filters.mois !== "All" ||
    filters.annee !== "All" ||
    filters.typeCulte !== "All";

  const activeFilterParams = () => ({
    category: filters.category !== "All" ? filters.category : undefined,
    mois: filters.mois !== "All" ? filters.mois : undefined,
    annee: filters.annee !== "All" ? filters.annee : undefined,
    typeCulte: filters.typeCulte !== "All" ? filters.typeCulte : undefined,
  });

  const load = async () => {
    try {
      const data = await textResumesService.getAll({
        ...activeFilterParams(),
        sortBy: filters.sortBy,
        order: filters.order,
      });
      setItems(data);
      setError(null);
    } catch (e: any) {
      setError(e.message || "Erreur de chargement");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setLoading(true);
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters]);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setPdfFile(null);
    setImageFile(null);
    setFormError(null);
    setDialogOpen(true);
  };

  const openEdit = (item: TextResume) => {
    setEditing(item);
    setForm({
      title: item.title || "",
      speaker: item.speaker || "",
      description: item.description || "",
      category: item.category || "Enseignement",
      tags: item.tags?.join(", ") || "",
      mois: String(item.mois || new Date().getMonth() + 1),
      annee: String(item.annee || CURRENT_YEAR),
      typeCulte: item.typeCulte || "Culte de Louange",
    });
    setPdfFile(null);
    setImageFile(null);
    setFormError(null);
    setDialogOpen(true);
  };

  const submit = async () => {
    if (!form.title.trim() || !form.speaker.trim()) {
      setFormError("Le titre et l'orateur sont requis");
      return;
    }
    if (!editing && !pdfFile) {
      setFormError("Veuillez sélectionner un fichier PDF");
      return;
    }
    setSaving(true);
    setFormError(null);
    try {
      const fd = new FormData();
      fd.append("title", form.title.trim());
      fd.append("speaker", form.speaker.trim());
      fd.append("description", form.description.trim());
      fd.append("category", form.category);
      fd.append("tags", form.tags);
      fd.append("mois", form.mois);
      fd.append("annee", form.annee);
      fd.append("typeCulte", form.typeCulte);
      if (pdfFile) fd.append("pdf", pdfFile);
      if (imageFile) fd.append("image", imageFile);

      if (editing) {
        await textResumesService.update(editing.id, fd);
        toast.success(`« ${form.title.trim()} » modifié`);
      } else {
        await textResumesService.create(fd);
        toast.success(`« ${form.title.trim()} » publié`);
      }
      setDialogOpen(false);
      await load();
    } catch (e: any) {
      setFormError(e.message || "Erreur lors de l'enregistrement");
    } finally {
      setSaving(false);
    }
  };

  const runDelete = async () => {
    if (!confirm) return;
    setDeleting(true);
    try {
      if (confirm.kind === "one") {
        await textResumesService.delete(confirm.item.id);
        toast.success(`« ${confirm.item.title} » supprimé`, {
          description: "Le texte résumé et ses fichiers ont été supprimés.",
        });
      } else if (confirm.kind === "all") {
        await textResumesService.deleteAll();
        toast.success(`${items.length} texte(s) résumé(s) supprimé(s)`, {
          description: "Tous les textes résumés ont été supprimés.",
        });
      } else {
        await textResumesService.deleteByFilter(activeFilterParams());
        toast.success(`${items.length} texte(s) résumé(s) supprimé(s)`, {
          description: "Les textes résumés filtrés ont été supprimés.",
        });
      }
      setConfirm(null);
      await load();
    } catch (e: any) {
      toast.error("Échec de la suppression", {
        description: e.message || "Une erreur est survenue.",
      });
      setError(e.message || "Erreur lors de la suppression");
      setConfirm(null);
    } finally {
      setDeleting(false);
    }
  };

  const formatSize = (bytes?: number) =>
    bytes ? `${(bytes / 1024 / 1024).toFixed(2)} MB` : null;

  return (
    <DashboardShell
      title="Textes Résumés"
      subtitle="Gérez les textes résumés (PDF) de vos enseignements"
      onRefresh={load}
      actions={
        <div className="flex items-center gap-2">
          {items.length > 0 && (
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
            Nouveau texte résumé
          </Button>
        </div>
      }
    >
      {/* Filtres */}
      <Card className="mb-6">
        <CardHeader className="flex flex-row items-center justify-between pb-3">
          <CardTitle className="text-sm font-medium">Filtres & tri</CardTitle>
          {hasActiveFilters && (
            <Button
              variant="ghost"
              size="sm"
              className="gap-1.5 text-muted-foreground"
              onClick={() => setFilters(DEFAULT_FILTERS)}
            >
              <FilterX className="w-3.5 h-3.5" />
              Réinitialiser
            </Button>
          )}
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">Catégorie</Label>
              <Select
                value={filters.category}
                onValueChange={(v) => setFilters({ ...filters, category: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="All">Toutes</SelectItem>
                  {CATEGORIES.map((c) => (
                    <SelectItem key={c} value={c}>{c}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">Mois</Label>
              <Select
                value={filters.mois}
                onValueChange={(v) => setFilters({ ...filters, mois: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="All">Tous</SelectItem>
                  {MOIS_LABELS.map((m, i) => (
                    <SelectItem key={m} value={String(i + 1)}>{m}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">Année</Label>
              <Select
                value={filters.annee}
                onValueChange={(v) => setFilters({ ...filters, annee: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="All">Toutes</SelectItem>
                  {ANNEES.map((a) => (
                    <SelectItem key={a} value={a}>{a}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">Type de culte</Label>
              <Select
                value={filters.typeCulte}
                onValueChange={(v) => setFilters({ ...filters, typeCulte: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="All">Tous</SelectItem>
                  {TYPES_CULTE.map((t) => (
                    <SelectItem key={t} value={t}>{t}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">Trier par</Label>
              <Select
                value={filters.sortBy}
                onValueChange={(v) => setFilters({ ...filters, sortBy: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {SORT_OPTIONS.map((o) => (
                    <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">Ordre</Label>
              <Select
                value={filters.order}
                onValueChange={(v) => setFilters({ ...filters, order: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="desc">Décroissant</SelectItem>
                  <SelectItem value="asc">Croissant</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          {hasActiveFilters && items.length > 0 && (
            <div className="flex justify-end">
              <Button
                variant="ghost"
                size="sm"
                className="gap-1.5 text-destructive hover:bg-destructive/10 hover:text-destructive"
                onClick={() => setConfirm({ kind: "filtered" })}
              >
                <Trash2 className="w-3.5 h-3.5" />
                Supprimer les {items.length} résultat(s) filtré(s)
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}

      {/* Liste */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-sm font-medium">
            Textes résumés publiés ({items.length})
          </CardTitle>
          <div className="flex items-center bg-muted/50 border border-border rounded-lg p-1">
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
        </CardHeader>
        <CardContent className={viewMode === "list" ? "p-0" : ""}>
          {loading ? (
            <div className="p-6 space-y-4">
              {[0, 1, 2].map((i) => (
                <div key={i} className="flex items-start gap-4">
                  <Skeleton className="w-20 h-20 rounded-lg shrink-0" />
                  <div className="flex-1 space-y-2">
                    <Skeleton className="h-5 w-1/3" />
                    <Skeleton className="h-4 w-1/4" />
                    <Skeleton className="h-4 w-2/3" />
                  </div>
                </div>
              ))}
            </div>
          ) : items.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              {hasActiveFilters
                ? "Aucun texte résumé ne correspond aux filtres."
                : "Aucun texte résumé publié pour le moment."}
            </p>
          ) : viewMode === "grid" ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 p-4">
              {items.map((item) => (
                <div
                  key={item.id}
                  className="rounded-xl border border-border bg-card overflow-hidden hover:border-accent/40 transition-colors flex flex-col"
                >
                  <div className="relative">
                    {item.pdfUrl ? (
                      <PdfFirstPage
                        url={item.pdfUrl}
                        title={item.title}
                        className="w-full h-44"
                      />
                    ) : item.coverImageUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={item.coverImageUrl}
                        alt={item.title}
                        className="w-full h-44 object-cover"
                      />
                    ) : (
                      <div className="w-full h-44 bg-muted/50 flex items-center justify-center">
                        <FileText className="w-9 h-9 text-muted-foreground" />
                      </div>
                    )}
                    {item.pdfUrl && (
                      <a
                        href={item.pdfUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="absolute bottom-3 left-3 w-9 h-9 rounded-full bg-background/90 border border-border flex items-center justify-center hover:bg-background transition-colors"
                        title="Voir le PDF"
                      >
                        <Eye className="w-4 h-4 text-foreground" />
                      </a>
                    )}
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-background/90 border border-border flex items-center justify-center hover:bg-background transition-colors">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => openEdit(item)}>
                          <Pencil className="w-4 h-4" /> Modifier
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-destructive focus:text-destructive"
                          onClick={() => setConfirm({ kind: "one", item })}
                        >
                          <Trash2 className="w-4 h-4" /> Supprimer
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  <div className="p-4 space-y-2 flex-1 flex flex-col">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-semibold text-sm line-clamp-2">
                        {item.title}
                      </h3>
                      {item.isNew && (
                        <Badge
                          variant="outline"
                          className="bg-success/10 text-success border-success/30 text-[10px]"
                        >
                          Nouveau
                        </Badge>
                      )}
                      {item.isFeatured && (
                        <Badge
                          variant="outline"
                          className="bg-warning/15 text-warning border-warning/30 text-[10px]"
                        >
                          Mis en avant
                        </Badge>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {item.speaker}
                    </p>
                    {item.description && (
                      <p className="text-xs text-muted-foreground line-clamp-2">
                        {item.description}
                      </p>
                    )}
                    <div className="flex flex-wrap gap-1.5">
                      {item.category && (
                        <Badge variant="outline" className="text-[10px] bg-muted/60">
                          {item.category}
                        </Badge>
                      )}
                      {item.typeCulte && (
                        <Badge variant="outline" className="text-[10px] bg-muted/60">
                          {item.typeCulte}
                        </Badge>
                      )}
                      {formatSize(item.fileSize) && (
                        <Badge variant="outline" className="text-[10px] bg-muted/60">
                          {formatSize(item.fileSize)}
                        </Badge>
                      )}
                    </div>
                    <div className="flex items-center justify-between text-[11px] text-muted-foreground pt-1 mt-auto">
                      <span className="inline-flex items-center gap-1">
                        <Eye className="w-3 h-3" /> {item.viewCount ?? 0} vue(s)
                      </span>
                      <span>
                        {item.publishedAt
                          ? format(new Date(item.publishedAt), "dd MMM yyyy", {
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
            <div className="divide-y divide-border">
              {items.map((item) => (
                <div key={item.id} className="p-5 hover:bg-muted/50 transition-colors">
                  <div className="flex items-start gap-4">
                    {item.pdfUrl ? (
                      <PdfFirstPage
                        url={item.pdfUrl}
                        title={item.title}
                        className="w-20 h-20 rounded-lg border border-border shrink-0"
                      />
                    ) : item.coverImageUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={item.coverImageUrl}
                        alt={item.title}
                        className="w-20 h-20 object-cover rounded-lg border border-border shrink-0"
                      />
                    ) : (
                      <div className="w-20 h-20 rounded-lg bg-muted/60 border border-border shrink-0 flex items-center justify-center">
                        <FileText className="w-7 h-7 text-muted-foreground" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <div className="flex items-center gap-2 flex-wrap mb-1">
                            <h3 className="font-semibold text-foreground truncate">
                              {item.title}
                            </h3>
                            {item.isNew && (
                              <Badge
                                variant="outline"
                                className="bg-success/10 text-success border-success/30 text-[10px]"
                              >
                                Nouveau
                              </Badge>
                            )}
                            {item.isFeatured && (
                              <Badge
                                variant="outline"
                                className="bg-warning/15 text-warning border-warning/30 text-[10px]"
                              >
                                Mis en avant
                              </Badge>
                            )}
                          </div>
                          <p className="text-sm text-muted-foreground mb-1.5">
                            <span className="font-medium text-foreground/80">Orateur :</span>{" "}
                            {item.speaker}
                          </p>
                          {item.description && (
                            <p className="text-sm text-muted-foreground mb-2 line-clamp-2">
                              {item.description}
                            </p>
                          )}
                          <div className="flex flex-wrap gap-1.5 mb-2">
                            {item.category && (
                              <Badge variant="outline" className="text-[10px] bg-muted/60">
                                {item.category}
                              </Badge>
                            )}
                            {item.typeCulte && (
                              <Badge variant="outline" className="text-[10px] bg-muted/60">
                                {item.typeCulte}
                              </Badge>
                            )}
                            {formatSize(item.fileSize) && (
                              <Badge variant="outline" className="text-[10px] bg-muted/60">
                                {formatSize(item.fileSize)}
                              </Badge>
                            )}
                            <Badge
                              variant="outline"
                              className="text-[10px] bg-accent/15 text-accent-foreground border-accent/30 gap-1"
                            >
                              <Eye className="w-3 h-3" />
                              {item.viewCount ?? 0} vue(s)
                            </Badge>
                          </div>
                          {item.publishedAt && (
                            <p className="text-xs text-muted-foreground">
                              Publié le{" "}
                              {format(new Date(item.publishedAt), "dd MMM yyyy", {
                                locale: fr,
                              })}
                            </p>
                          )}
                        </div>
                        <div className="flex items-center gap-1 shrink-0">
                          {item.pdfUrl && (
                            <Button variant="outline" size="sm" asChild className="gap-1.5">
                              <a
                                href={item.pdfUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                              >
                                <FileText className="w-3.5 h-3.5" />
                                Voir PDF
                              </a>
                            </Button>
                          )}
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => openEdit(item)}
                            title="Modifier"
                          >
                            <Pencil className="w-4 h-4 text-muted-foreground" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setConfirm({ kind: "one", item })}
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4 text-destructive" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Dialog création / édition */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="sm:max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <FileText className="w-4 h-4" />
              {editing ? "Modifier le texte résumé" : "Nouveau texte résumé"}
            </DialogTitle>
            <DialogDescription>
              {editing
                ? "Laissez les fichiers vides pour conserver les fichiers actuels."
                : "Le fichier PDF est requis, l'image de couverture est optionnelle."}
            </DialogDescription>
          </DialogHeader>

          {formError && (
            <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
              {formError}
            </div>
          )}

          <div className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Titre *</Label>
                <Input
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  placeholder="Titre du texte résumé"
                />
              </div>
              <div className="space-y-2">
                <Label>Orateur *</Label>
                <Input
                  value={form.speaker}
                  onChange={(e) => setForm({ ...form, speaker: e.target.value })}
                  placeholder="Nom de l'orateur"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                rows={3}
                placeholder="Description du texte résumé…"
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Catégorie *</Label>
                <Select
                  value={form.category}
                  onValueChange={(v) => setForm({ ...form, category: v })}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {CATEGORIES.map((c) => (
                      <SelectItem key={c} value={c}>{c}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Mois</Label>
                <Select
                  value={form.mois}
                  onValueChange={(v) => setForm({ ...form, mois: v })}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {MOIS_LABELS.map((m, i) => (
                      <SelectItem key={m} value={String(i + 1)}>{m}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Année</Label>
                <Input
                  type="number"
                  min={2000}
                  max={2100}
                  value={form.annee}
                  onChange={(e) => setForm({ ...form, annee: e.target.value })}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Type de culte</Label>
              <Select
                value={form.typeCulte}
                onValueChange={(v) => setForm({ ...form, typeCulte: v })}
              >
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {TYPES_CULTE.map((t) => (
                    <SelectItem key={t} value={t}>{t}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Tags (séparés par des virgules)</Label>
              <Input
                value={form.tags}
                onChange={(e) => setForm({ ...form, tags: e.target.value })}
                placeholder="foi, prière, amour"
              />
            </div>

            <div className="space-y-2">
              <Label>Fichier PDF {!editing && "*"}</Label>
              <Input
                ref={pdfInputRef}
                type="file"
                accept=".pdf,application/pdf"
                onChange={(e) => setPdfFile(e.target.files?.[0] || null)}
              />
              {pdfFile && (
                <p className="text-xs text-muted-foreground">
                  Fichier sélectionné : {pdfFile.name} (
                  {(pdfFile.size / 1024 / 1024).toFixed(2)} MB)
                </p>
              )}
              {editing?.pdfUrl && !pdfFile && (
                <p className="text-xs text-muted-foreground">
                  PDF actuel :{" "}
                  <a
                    href={editing.pdfUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="underline hover:text-foreground"
                  >
                    Voir le PDF
                  </a>
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label>Image de couverture (optionnel)</Label>
              <Input
                ref={imageInputRef}
                type="file"
                accept="image/*"
                onChange={(e) => setImageFile(e.target.files?.[0] || null)}
              />
              {imageFile && (
                <p className="text-xs text-muted-foreground flex items-center gap-1.5">
                  <ImageIcon className="w-3.5 h-3.5" />
                  Image sélectionnée : {imageFile.name}
                </p>
              )}
              {editing?.coverImageUrl && !imageFile && (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={editing.coverImageUrl}
                  alt="Couverture actuelle"
                  className="h-24 w-auto rounded-lg border border-border"
                />
              )}
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Annuler
            </Button>
            <Button
              onClick={submit}
              disabled={
                saving ||
                !form.title.trim() ||
                !form.speaker.trim() ||
                (!editing && !pdfFile)
              }
            >
              {saving
                ? "Enregistrement…"
                : editing
                  ? "Modifier"
                  : "Créer"}
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
                ? "Supprimer tous les textes résumés ?"
                : confirm?.kind === "filtered"
                  ? "Supprimer les résultats filtrés ?"
                  : "Supprimer ce texte résumé ?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {confirm?.kind === "all"
                ? `Cette action supprimera définitivement les ${items.length} textes résumés ainsi que leurs fichiers.`
                : confirm?.kind === "filtered"
                  ? `Cette action supprimera définitivement les ${items.length} textes résumés correspondant aux filtres actifs.`
                  : `« ${confirm?.kind === "one" ? confirm.item.title : ""} » sera définitivement supprimé.`}
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
