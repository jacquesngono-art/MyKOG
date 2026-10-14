"use client";

import { useEffect, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Progress } from "@/components/ui/progress";
import {
  BookOpen,
  ImageIcon,
  Music,
  Pencil,
  Loader2,
} from "lucide-react";
import { enseignementsService } from "@/lib/services/enseignements";
import { api } from "@/lib/api";
import type { Enseignement } from "@/lib/types";

// Liste canonique partagée avec l'app desktop (onglets Bibliothèque) et les résumés
export const TYPE_CULTE_OPTIONS = [
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

export const CATEGORY_OPTIONS = [
  "Enseignement",
  "Guerre Spirituelle",
  "Foi",
  "Prière",
  "Amour",
  "Espérance",
  "Autre",
];

export const MOIS_OPTIONS = [
  { value: "1", label: "Janvier" },
  { value: "2", label: "Février" },
  { value: "3", label: "Mars" },
  { value: "4", label: "Avril" },
  { value: "5", label: "Mai" },
  { value: "6", label: "Juin" },
  { value: "7", label: "Juillet" },
  { value: "8", label: "Août" },
  { value: "9", label: "Septembre" },
  { value: "10", label: "Octobre" },
  { value: "11", label: "Novembre" },
  { value: "12", label: "Décembre" },
];

/** Zone de dépôt de fichier (image / audio) */
function FileDrop({
  id,
  label,
  required,
  accept,
  file,
  previewUrl,
  icon,
  hint,
  onFile,
}: {
  id: string;
  label: string;
  required?: boolean;
  accept: string;
  file: File | null;
  previewUrl?: string | null;
  icon: React.ReactNode;
  hint?: string;
  onFile: (f: File | null) => void;
}) {
  return (
    <div className="space-y-2">
      <Label>
        {label} {required && "*"}
      </Label>
      <div className="flex justify-center px-4 pt-4 pb-4 border-2 border-dashed border-border rounded-xl hover:border-accent/60 transition-colors">
        <div className="space-y-1 text-center">
          <input
            type="file"
            accept={accept}
            className="hidden"
            id={id}
            onChange={(e) => onFile(e.target.files?.[0] || null)}
          />
          <label htmlFor={id} className="cursor-pointer">
            {previewUrl ? (
              <div className="space-y-2">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={previewUrl}
                  alt="Aperçu"
                  className="mx-auto h-28 w-28 object-cover rounded-lg"
                />
                <p className="text-xs text-muted-foreground">
                  Cliquez pour changer le fichier
                </p>
              </div>
            ) : (
              <>
                <div className="mx-auto w-11 h-11 rounded-xl bg-muted/60 flex items-center justify-center text-muted-foreground">
                  {icon}
                </div>
                <p className="text-sm text-accent-foreground font-medium mt-2">
                  Cliquez pour uploader
                </p>
              </>
            )}
            {file && (
              <p className="text-xs text-muted-foreground mt-1 max-w-[220px] truncate">
                {file.name}
              </p>
            )}
          </label>
        </div>
      </div>
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
    </div>
  );
}

interface CreateFormState {
  title: string;
  speaker: string;
  description: string;
  category: string;
  duration: string;
  mois: string;
  annee: string;
  typeCulte: string;
  tags: string;
  isNew: boolean;
  isFeatured: boolean;
  publishedAt: string;
}

const defaultCreateForm = (): CreateFormState => ({
  title: "",
  speaker: "",
  description: "",
  category: "Enseignement",
  duration: "",
  mois: String(new Date().getMonth() + 1),
  annee: String(new Date().getFullYear()),
  typeCulte: "Culte de Louange",
  tags: "",
  isNew: true,
  isFeatured: false,
  publishedAt: "",
});

export function EnseignementCreateDialog({
  open,
  onOpenChange,
  onCreated,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCreated: () => void;
}) {
  const [form, setForm] = useState<CreateFormState>(defaultCreateForm);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [detecting, setDetecting] = useState(false);
  const [saving, setSaving] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  // Preview locale de l'image sélectionnée
  useEffect(() => {
    if (!imageFile) {
      setImagePreview(null);
      return;
    }
    const url = URL.createObjectURL(imageFile);
    setImagePreview(url);
    return () => URL.revokeObjectURL(url);
  }, [imageFile]);

  // Durée calculée automatiquement depuis les métadonnées du média (audio/vidéo)
  useEffect(() => {
    if (!audioFile) return;
    const url = URL.createObjectURL(audioFile);
    const media = document.createElement(
      audioFile.type.startsWith("video/") ? "video" : "audio"
    );
    media.preload = "metadata";
    media.src = url;
    setDetecting(true);
    const done = (dur?: number) => {
      setDetecting(false);
      setForm((f) => ({
        ...f,
        duration: dur && dur > 0 ? String(Math.round(dur)) : "",
      }));
    };
    const onLoaded = () => done(media.duration);
    const onError = () => done();
    media.addEventListener("loadedmetadata", onLoaded);
    media.addEventListener("error", onError);
    // Certains formats (.mov, .mkv) ne sont pas lisibles par le navigateur
    const failSafe = setTimeout(() => done(), 8000);
    return () => {
      media.removeEventListener("loadedmetadata", onLoaded);
      media.removeEventListener("error", onError);
      clearTimeout(failSafe);
      URL.revokeObjectURL(url);
    };
  }, [audioFile]);

  const reset = () => {
    setForm(defaultCreateForm());
    setImageFile(null);
    setAudioFile(null);
    setProgress(0);
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!imageFile || !audioFile) {
      setError("Veuillez sélectionner une image et un fichier audio");
      return;
    }

    setSaving(true);
    setProgress(0);
    try {
      const fd = new FormData();
      fd.append("title", form.title.trim());
      fd.append("speaker", form.speaker.trim());
      fd.append("description", form.description.trim());
      fd.append("category", form.category.trim());
      if (form.duration) fd.append("duration", form.duration);
      fd.append("mois", form.mois);
      fd.append("annee", form.annee);
      fd.append("typeCulte", form.typeCulte);
      fd.append("tags", form.tags);
      fd.append("isNew", String(form.isNew));
      fd.append("isFeatured", String(form.isFeatured));
      if (form.publishedAt)
        fd.append("publishedAt", new Date(form.publishedAt).toISOString());
      fd.append("image", imageFile);
      fd.append("audio", audioFile);

      // api.upload = XHR avec progression réelle (les audios sont volumineux)
      await api.upload("/enseignements", fd, setProgress);

      reset();
      onOpenChange(false);
      onCreated();
    } catch (err: any) {
      setError(err.message || "Erreur lors de la création");
    } finally {
      setSaving(false);
    }
  };

  const canSubmit =
    !!form.title.trim() &&
    !!form.speaker.trim() &&
    !!form.category.trim() &&
    !!imageFile &&
    !!audioFile;

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => {
        if (!saving) {
          onOpenChange(o);
          if (!o) reset();
        }
      }}
    >
      <DialogContent className="sm:max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <BookOpen className="w-4 h-4" /> Nouvel enseignement
          </DialogTitle>
          <DialogDescription>
            Publier un enseignement avec image de couverture et fichier audio.
          </DialogDescription>
        </DialogHeader>

        {error && (
          <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 py-2">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Titre *</Label>
              <Input
                required
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="Titre de l'enseignement"
              />
            </div>
            <div className="space-y-2">
              <Label>Orateur *</Label>
              <Input
                required
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
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              rows={3}
              placeholder="Description de l'enseignement..."
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label>Catégorie *</Label>
              <Select
                value={form.category}
                onValueChange={(v) => setForm({ ...form, category: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORY_OPTIONS.map((c) => (
                    <SelectItem key={c} value={c}>
                      {c}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Durée</Label>
              <div className="h-9 px-3 rounded-lg bg-muted/50 border border-border flex items-center text-sm">
                {form.duration ? (
                  <span className="font-medium">
                    {Math.floor(Number(form.duration) / 60)}:
                    {String(Number(form.duration) % 60).padStart(2, "0")} min
                  </span>
                ) : (
                  <span className="text-muted-foreground">
                    {!audioFile ? "—" : detecting ? "Détection…" : "Non détectée"}
                  </span>
                )}
              </div>
            </div>
            <div className="space-y-2">
              <Label>Type de culte</Label>
              <Select
                value={form.typeCulte}
                onValueChange={(v) => setForm({ ...form, typeCulte: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TYPE_CULTE_OPTIONS.map((t) => (
                    <SelectItem key={t} value={t}>
                      {t}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label>Mois</Label>
              <Select
                value={form.mois}
                onValueChange={(v) => setForm({ ...form, mois: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
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
              <Input
                type="number"
                min={2000}
                max={2100}
                value={form.annee}
                onChange={(e) => setForm({ ...form, annee: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label>Date de publication</Label>
              <Input
                type="datetime-local"
                value={form.publishedAt}
                onChange={(e) =>
                  setForm({ ...form, publishedAt: e.target.value })
                }
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Tags (séparés par des virgules)</Label>
            <Input
              value={form.tags}
              onChange={(e) => setForm({ ...form, tags: e.target.value })}
              placeholder="foi, prière, enseignement"
            />
          </div>

          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <Switch
                id="create-isnew"
                checked={form.isNew}
                onCheckedChange={(v) => setForm({ ...form, isNew: v })}
              />
              <Label htmlFor="create-isnew" className="font-normal">
                Marquer comme nouveau
              </Label>
            </div>
            <div className="flex items-center gap-2">
              <Switch
                id="create-featured"
                checked={form.isFeatured}
                onCheckedChange={(v) => setForm({ ...form, isFeatured: v })}
              />
              <Label htmlFor="create-featured" className="font-normal">
                Mettre en avant
              </Label>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <FileDrop
              id="create-image-upload"
              label="Image de couverture"
              required
              accept="image/*"
              file={imageFile}
              previewUrl={imagePreview}
              icon={<ImageIcon className="w-5 h-5" />}
              onFile={setImageFile}
            />
            <FileDrop
              id="create-audio-upload"
              label="Fichier audio / vidéo"
              required
              accept="audio/*,video/*"
              file={audioFile}
              icon={<Music className="w-5 h-5" />}
              hint="La durée est détectée automatiquement."
              onFile={setAudioFile}
            />
          </div>

          {saving && (
            <div className="space-y-1.5">
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>Envoi des fichiers…</span>
                <span>{progress}%</span>
              </div>
              <Progress value={progress} />
            </div>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={saving}
              onClick={() => onOpenChange(false)}
            >
              Annuler
            </Button>
            <Button type="submit" disabled={saving || !canSubmit}>
              {saving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Publication {progress}%
                </>
              ) : (
                "Publier"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

interface EditFormState {
  title: string;
  speaker: string;
  description: string;
  category: string;
  typeCulte: string;
  mois: string;
  annee: string;
  tags: string;
  isNew: boolean;
  isFeatured: boolean;
}

export function EnseignementEditDialog({
  enseignement,
  onClose,
  onSaved,
}: {
  enseignement: Enseignement | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<EditFormState>({
    title: "",
    speaker: "",
    description: "",
    category: "Enseignement",
    typeCulte: "Culte de Louange",
    mois: String(new Date().getMonth() + 1),
    annee: String(new Date().getFullYear()),
    tags: "",
    isNew: false,
    isFeatured: false,
  });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Réinitialiser le formulaire à chaque ouverture / changement de cible
  useEffect(() => {
    if (enseignement) {
      setForm({
        title: enseignement.title || "",
        speaker: enseignement.speaker || "",
        description: enseignement.description || "",
        category: enseignement.category || "Enseignement",
        typeCulte: enseignement.typeCulte || "Culte de Louange",
        mois: String(enseignement.mois || new Date().getMonth() + 1),
        annee: String(enseignement.annee || new Date().getFullYear()),
        tags: (enseignement.tags || []).join(", "),
        isNew: !!enseignement.isNew,
        isFeatured: !!enseignement.isFeatured,
      });
      setImageFile(null);
      setImagePreview(enseignement.artworkUrl || null);
      setError(null);
    }
  }, [enseignement]);

  const handleImageChange = (f: File | null) => {
    setImageFile(f);
    if (!f) {
      setImagePreview(enseignement?.artworkUrl || null);
      return;
    }
    const reader = new FileReader();
    reader.onloadend = () => setImagePreview(reader.result as string);
    reader.readAsDataURL(f);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!enseignement?.id) return;
    setSaving(true);
    setError(null);
    try {
      // Métadonnées en JSON — les booléens doivent rester de vrais booléens
      // (en multipart, "false" serait stocké comme chaîne truthy).
      await enseignementsService.update(enseignement.id, {
        title: form.title.trim(),
        speaker: form.speaker.trim(),
        description: form.description.trim(),
        category: form.category.trim(),
        typeCulte: form.typeCulte,
        mois: form.mois,
        annee: form.annee,
        tags: form.tags
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
        isNew: form.isNew,
        isFeatured: form.isFeatured,
      });

      // Nouvelle image éventuelle via multipart
      if (imageFile) {
        const fd = new FormData();
        fd.append("image", imageFile);
        await enseignementsService.updateWithImage(enseignement.id, fd);
      }

      onSaved();
    } catch (err: any) {
      setError(err.message || "Erreur lors de la mise à jour");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog
      open={!!enseignement}
      onOpenChange={(o) => {
        if (!o && !saving) onClose();
      }}
    >
      <DialogContent className="sm:max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Pencil className="w-4 h-4" /> Modifier l'enseignement
          </DialogTitle>
          <DialogDescription>
            {enseignement?.title || "Mettre à jour les informations"}
          </DialogDescription>
        </DialogHeader>

        {error && (
          <div className="p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 py-2">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Titre *</Label>
              <Input
                required
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label>Orateur / Prédicateur *</Label>
              <Input
                required
                value={form.speaker}
                onChange={(e) => setForm({ ...form, speaker: e.target.value })}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Description</Label>
            <Textarea
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              rows={3}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Catégorie</Label>
              <Select
                value={form.category}
                onValueChange={(v) => setForm({ ...form, category: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORY_OPTIONS.map((c) => (
                    <SelectItem key={c} value={c}>
                      {c}
                    </SelectItem>
                  ))}
                  {form.category && !CATEGORY_OPTIONS.includes(form.category) && (
                    <SelectItem value={form.category}>{form.category}</SelectItem>
                  )}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Type de culte</Label>
              <Select
                value={form.typeCulte}
                onValueChange={(v) => setForm({ ...form, typeCulte: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TYPE_CULTE_OPTIONS.map((t) => (
                    <SelectItem key={t} value={t}>
                      {t}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Mois</Label>
              <Select
                value={form.mois}
                onValueChange={(v) => setForm({ ...form, mois: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
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
            <Label>Tags (séparés par des virgules)</Label>
            <Input
              value={form.tags}
              onChange={(e) => setForm({ ...form, tags: e.target.value })}
              placeholder="foi, prière, enseignement"
            />
          </div>

          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <Switch
                id="edit-isnew"
                checked={form.isNew}
                onCheckedChange={(v) => setForm({ ...form, isNew: v })}
              />
              <Label htmlFor="edit-isnew" className="font-normal">
                Marquer comme nouveau
              </Label>
            </div>
            <div className="flex items-center gap-2">
              <Switch
                id="edit-featured"
                checked={form.isFeatured}
                onCheckedChange={(v) => setForm({ ...form, isFeatured: v })}
              />
              <Label htmlFor="edit-featured" className="font-normal">
                Mettre en avant
              </Label>
            </div>
          </div>

          <FileDrop
            id="edit-image-upload"
            label="Image de couverture"
            accept="image/*"
            file={imageFile}
            previewUrl={imagePreview}
            icon={<ImageIcon className="w-5 h-5" />}
            hint="Laisser vide pour conserver l'image actuelle"
            onFile={handleImageChange}
          />

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={saving}
              onClick={onClose}
            >
              Annuler
            </Button>
            <Button type="submit" disabled={saving || !form.title.trim() || !form.speaker.trim()}>
              {saving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Enregistrement…
                </>
              ) : (
                "Enregistrer les modifications"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
