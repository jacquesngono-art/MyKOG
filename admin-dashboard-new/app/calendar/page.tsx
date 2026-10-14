"use client";

import { useEffect, useMemo, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
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
  CalendarDays,
  Plus,
  Pencil,
  Trash2,
  MapPin,
  Clock,
} from "lucide-react";
import { calendarService } from "@/lib/services/calendar";
import type { CalendarEvent } from "@/lib/types";
import { format } from "date-fns";
import { fr } from "date-fns/locale/fr";

const categories = ["Culte", "Réunion", "Événement", "Formation", "Prière", "Autre"];

const colors = [
  { name: "Or", value: "#d4af37" },
  { name: "Bleu", value: "#3b82f6" },
  { name: "Vert", value: "#10b981" },
  { name: "Rouge", value: "#ef4444" },
  { name: "Violet", value: "#8b5cf6" },
  { name: "Rose", value: "#ec4899" },
];

const emptyForm = {
  title: "",
  description: "",
  startDate: "",
  startTime: "",
  endDate: "",
  endTime: "",
  location: "",
  category: "Culte",
  color: "#d4af37",
  isAllDay: false,
};

const toDateInput = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate()
  ).padStart(2, "0")}`;

const toTimeInput = (d: Date) =>
  `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;

function dateLabel(event: CalendarEvent) {
  const start = new Date(event.startDate);
  const end = event.endDate ? new Date(event.endDate) : null;
  let label = format(start, "EEEE d MMMM yyyy", { locale: fr });
  if (!event.isAllDay) label += ` à ${format(start, "HH:mm")}`;
  if (end) {
    label += ` → ${format(end, "d MMMM yyyy", { locale: fr })}`;
    if (!event.isAllDay) label += ` à ${format(end, "HH:mm")}`;
  }
  return label;
}

export default function CalendarPage() {
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editing, setEditing] = useState<CalendarEvent | null>(null);
  const [form, setForm] = useState(emptyForm);

  const load = async () => {
    try {
      const data = await calendarService.getAll();
      setEvents(
        [...data].sort(
          (a, b) =>
            new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
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

  const groups = useMemo(() => {
    const map = new Map<string, CalendarEvent[]>();
    for (const ev of events) {
      const key = format(new Date(ev.startDate), "yyyy-MM");
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(ev);
    }
    return [...map.entries()].map(([key, evs]) => ({
      key,
      label: format(new Date(evs[0].startDate), "MMMM yyyy", { locale: fr }),
      events: evs,
    }));
  }, [events]);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setDialogOpen(true);
  };

  const openEdit = (event: CalendarEvent) => {
    const start = new Date(event.startDate);
    const end = event.endDate ? new Date(event.endDate) : null;
    setEditing(event);
    setForm({
      title: event.title || "",
      description: event.description || "",
      startDate: toDateInput(start),
      startTime: event.isAllDay ? "" : toTimeInput(start),
      endDate: end ? toDateInput(end) : "",
      endTime: end && !event.isAllDay ? toTimeInput(end) : "",
      location: event.location || "",
      category: event.category || "Culte",
      color: event.color || "#d4af37",
      isAllDay: event.isAllDay || false,
    });
    setDialogOpen(true);
  };

  const save = async () => {
    if (!form.title.trim() || !form.startDate) return;
    setSaving(true);
    try {
      const startDateTime = form.isAllDay
        ? new Date(`${form.startDate}T00:00`)
        : new Date(`${form.startDate}T${form.startTime || "00:00"}`);

      const endDateTime = form.endDate
        ? form.isAllDay
          ? new Date(`${form.endDate}T23:59`)
          : new Date(
              `${form.endDate}T${form.endTime || form.startTime || "00:00"}`
            )
        : undefined;

      const payload = {
        title: form.title.trim(),
        description: form.description.trim() || undefined,
        startDate: startDateTime.toISOString(),
        endDate: endDateTime?.toISOString(),
        location: form.location.trim() || undefined,
        category: form.category || undefined,
        color: form.color,
        isAllDay: form.isAllDay,
      };

      if (editing?.id) {
        await calendarService.update(editing.id, payload);
      } else {
        await calendarService.create(payload);
      }

      setDialogOpen(false);
      setEditing(null);
      setForm(emptyForm);
      await load();
    } catch (e: any) {
      setError(e.message || "Erreur lors de la sauvegarde");
    } finally {
      setSaving(false);
    }
  };

  const remove = async (id: string) => {
    if (!confirm("Êtes-vous sûr de vouloir supprimer cet événement ?")) return;
    try {
      await calendarService.delete(id);
      await load();
    } catch (e: any) {
      setError(e.message || "Erreur lors de la suppression");
    }
  };

  return (
    <DashboardShell
      title="Calendrier"
      subtitle="Gérez le calendrier annuel de l'église"
      onRefresh={load}
      actions={
        <Button size="sm" className="gap-2" onClick={openCreate}>
          <Plus className="w-4 h-4" />
          Nouvel événement
        </Button>
      }
    >
      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <CalendarDays className="w-4 h-4 text-muted-foreground" />
            Événements ({events.length})
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Chargement…
            </p>
          ) : events.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Aucun événement dans le calendrier
            </p>
          ) : (
            groups.map((group) => (
              <div key={group.key}>
                <p className="px-4 py-2 text-[11px] font-medium uppercase tracking-wider text-muted-foreground bg-muted/50 border-y border-border first:border-t-0 capitalize">
                  {group.label}
                </p>
                {group.events.map((event) => (
                  <div
                    key={event.id}
                    className="flex items-start gap-4 px-4 py-4 border-b border-border last:border-b-0"
                  >
                    <div
                      className="w-1 self-stretch rounded-full shrink-0"
                      style={{ backgroundColor: event.color || "#d4af37" }}
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-medium text-foreground">
                          {event.title}
                        </p>
                        {event.category && (
                          <Badge
                            variant="outline"
                            className="bg-accent/15 text-accent-foreground border-accent/30"
                          >
                            {event.category}
                          </Badge>
                        )}
                        {event.isAllDay && (
                          <Badge variant="outline">Journée entière</Badge>
                        )}
                      </div>
                      {event.description && (
                        <p className="text-sm text-muted-foreground mt-0.5 line-clamp-2">
                          {event.description}
                        </p>
                      )}
                      <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground flex-wrap">
                        <span className="inline-flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5" />
                          {dateLabel(event)}
                        </span>
                        {event.location && (
                          <span className="inline-flex items-center gap-1.5">
                            <MapPin className="w-3.5 h-3.5" />
                            {event.location}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="flex gap-1 shrink-0">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => openEdit(event)}
                        title="Modifier"
                      >
                        <Pencil className="w-4 h-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => remove(event.id)}
                        title="Supprimer"
                      >
                        <Trash2 className="w-4 h-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            ))
          )}
        </CardContent>
      </Card>

      {/* Dialog création / édition */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <CalendarDays className="w-4 h-4" />
              {editing ? "Modifier l'événement" : "Nouvel événement"}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label>Titre *</Label>
              <Input
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="Ex: Culte du dimanche"
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
                rows={2}
                placeholder="Description de l'événement..."
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Date de début *</Label>
                <Input
                  type="date"
                  value={form.startDate}
                  onChange={(e) =>
                    setForm({ ...form, startDate: e.target.value })
                  }
                />
              </div>
              {!form.isAllDay && (
                <div className="space-y-2">
                  <Label>Heure de début</Label>
                  <Input
                    type="time"
                    value={form.startTime}
                    onChange={(e) =>
                      setForm({ ...form, startTime: e.target.value })
                    }
                  />
                </div>
              )}
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Date de fin</Label>
                <Input
                  type="date"
                  value={form.endDate}
                  onChange={(e) =>
                    setForm({ ...form, endDate: e.target.value })
                  }
                />
              </div>
              {!form.isAllDay && (
                <div className="space-y-2">
                  <Label>Heure de fin</Label>
                  <Input
                    type="time"
                    value={form.endTime}
                    onChange={(e) =>
                      setForm({ ...form, endTime: e.target.value })
                    }
                  />
                </div>
              )}
            </div>
            <div className="flex items-center gap-3">
              <Switch
                id="isAllDay"
                checked={form.isAllDay}
                onCheckedChange={(checked) =>
                  setForm({ ...form, isAllDay: checked })
                }
              />
              <Label htmlFor="isAllDay" className="cursor-pointer">
                Journée entière
              </Label>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Lieu</Label>
                <Input
                  value={form.location}
                  onChange={(e) =>
                    setForm({ ...form, location: e.target.value })
                  }
                  placeholder="Ex: Église KOG, Salle principale"
                />
              </div>
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
                    {categories.map((cat) => (
                      <SelectItem key={cat} value={cat}>
                        {cat}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label>Couleur</Label>
              <div className="flex gap-2">
                {colors.map((color) => (
                  <button
                    key={color.value}
                    type="button"
                    onClick={() => setForm({ ...form, color: color.value })}
                    className={`w-9 h-9 rounded-lg border-2 transition-all ${
                      form.color === color.value
                        ? "border-foreground scale-110"
                        : "border-border"
                    }`}
                    style={{ backgroundColor: color.value }}
                    title={color.name}
                  />
                ))}
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Annuler
            </Button>
            <Button
              onClick={save}
              disabled={saving || !form.title.trim() || !form.startDate}
            >
              {saving ? "Enregistrement…" : editing ? "Modifier" : "Créer"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </DashboardShell>
  );
}
