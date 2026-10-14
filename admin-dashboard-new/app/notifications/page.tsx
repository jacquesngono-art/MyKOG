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
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Bell,
  Send,
  Users,
  User as UserIcon,
  Hash,
  Plus,
  Trash2,
  CheckCircle2,
  XCircle,
  Loader2,
} from "lucide-react";
import { notificationsService } from "@/lib/services/notifications";
import { usersService } from "@/lib/services/users";
import type { User } from "@/lib/types";

type Target = "all" | "user" | "topic";

interface DataPair {
  key: string;
  value: string;
}

interface Result {
  ok: boolean;
  message: string;
}

const NOTIF_TYPES = [
  { value: "general", label: "Général" },
  { value: "calendar", label: "Calendrier" },
  { value: "teaching", label: "Enseignement" },
  { value: "live", label: "Live" },
  { value: "annonce", label: "Annonce" },
];

const TOPIC_SUGGESTIONS = ["all", "enseignements", "lives", "annonces", "calendar"];

export default function NotificationsPage() {
  const [target, setTarget] = useState<Target>("all");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [notifType, setNotifType] = useState("general");
  const [dataPairs, setDataPairs] = useState<DataPair[]>([]);
  const [userId, setUserId] = useState("");
  const [topic, setTopic] = useState("");

  const [users, setUsers] = useState<User[]>([]);
  const [usersError, setUsersError] = useState(false);
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<Result | null>(null);

  useEffect(() => {
    usersService
      .getAll()
      .then(setUsers)
      .catch(() => setUsersError(true));
  }, []);

  const buildData = (): Record<string, string> | undefined => {
    const data: Record<string, string> = { type: notifType };
    for (const p of dataPairs) {
      const k = p.key.trim();
      if (k) data[k] = p.value;
    }
    return data;
  };

  const resetForm = () => {
    setTitle("");
    setBody("");
    setImageUrl("");
    setNotifType("general");
    setDataPairs([]);
  };

  const send = async () => {
    if (!title.trim() || !body.trim()) return;
    if (target === "user" && !userId.trim()) return;
    if (target === "topic" && !topic.trim()) return;

    setSending(true);
    setResult(null);
    const data = buildData();
    const img = imageUrl.trim() || undefined;

    try {
      if (target === "all") {
        const r = await notificationsService.sendToAll(
          title.trim(),
          body.trim(),
          data,
          img
        );
        setResult({
          ok: true,
          message: `Notification envoyée : ${r.sent} utilisateur(s) notifié(s), ${r.failed} échec(s) sur ${r.total}.`,
        });
        resetForm();
      } else if (target === "user") {
        const r = await notificationsService.sendToUser(
          userId.trim(),
          title.trim(),
          body.trim(),
          data,
          img
        );
        setResult({
          ok: true,
          message: `Notification envoyée : ${r.sent} appareil(s) atteint(s), ${r.failed} échec(s).`,
        });
        resetForm();
      } else {
        const r = await notificationsService.sendToTopic(
          topic.trim(),
          title.trim(),
          body.trim(),
          data,
          img
        );
        setResult({
          ok: true,
          message: `Notification envoyée au topic « ${topic.trim()} » (messageId : ${r.messageId}).`,
        });
        resetForm();
      }
    } catch (e: any) {
      setResult({
        ok: false,
        message: e.message || "Erreur lors de l'envoi de la notification",
      });
    } finally {
      setSending(false);
    }
  };

  const canSend =
    title.trim().length > 0 &&
    body.trim().length > 0 &&
    (target === "all" ||
      (target === "user" && userId.trim().length > 0) ||
      (target === "topic" && topic.trim().length > 0)) &&
    !sending;

  const selectedUser = users.find((u) => u.id === userId);

  return (
    <DashboardShell
      title="Notifications"
      subtitle="Envoyer des notifications push aux utilisateurs"
    >
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Formulaire */}
        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Bell className="w-4 h-4 text-accent-foreground" />
              Nouvelle notification
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Tabs
              value={target}
              onValueChange={(v) => {
                setTarget(v as Target);
                setResult(null);
              }}
            >
              <TabsList className="mb-5">
                <TabsTrigger value="all" className="gap-1.5">
                  <Users className="w-3.5 h-3.5" />
                  Tous les utilisateurs
                </TabsTrigger>
                <TabsTrigger value="user" className="gap-1.5">
                  <UserIcon className="w-3.5 h-3.5" />
                  Utilisateur
                </TabsTrigger>
                <TabsTrigger value="topic" className="gap-1.5">
                  <Hash className="w-3.5 h-3.5" />
                  Topic
                </TabsTrigger>
              </TabsList>

              {/* Cible : utilisateur */}
              <TabsContent value="user" className="space-y-2 mb-4">
                <Label>Destinataire *</Label>
                {usersError ? (
                  <>
                    <Input
                      value={userId}
                      onChange={(e) => setUserId(e.target.value)}
                      placeholder="ID utilisateur (liste indisponible)"
                    />
                    <p className="text-xs text-warning">
                      Impossible de charger la liste des utilisateurs — saisissez
                      l'ID manuellement.
                    </p>
                  </>
                ) : (
                  <>
                    <Select value={userId} onValueChange={setUserId}>
                      <SelectTrigger>
                        <SelectValue placeholder="Sélectionner un utilisateur…" />
                      </SelectTrigger>
                      <SelectContent>
                        {users.map((u) => (
                          <SelectItem key={u.id} value={u.id}>
                            {u.name || "Sans nom"} — {u.email}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    {selectedUser && (
                      <p className="text-xs text-muted-foreground">
                        {selectedUser.notificationsEnabled ? (
                          <span className="text-success">
                            Notifications activées
                          </span>
                        ) : (
                          <span className="text-warning">
                            Notifications désactivées pour cet utilisateur
                          </span>
                        )}{" "}
                        · {selectedUser.fcmTokens?.length ?? 0} appareil(s)
                        enregistré(s)
                      </p>
                    )}
                    {users.length === 0 && !usersError && (
                      <p className="text-xs text-muted-foreground">
                        Chargement des utilisateurs…
                      </p>
                    )}
                  </>
                )}
              </TabsContent>

              {/* Cible : topic */}
              <TabsContent value="topic" className="space-y-2 mb-4">
                <Label>Topic FCM *</Label>
                <Input
                  value={topic}
                  onChange={(e) => setTopic(e.target.value)}
                  placeholder="ex. enseignements"
                />
                <div className="flex flex-wrap gap-1.5">
                  {TOPIC_SUGGESTIONS.map((t) => (
                    <button
                      key={t}
                      type="button"
                      onClick={() => setTopic(t)}
                      className="px-2 py-0.5 text-xs rounded-full bg-muted/60 hover:bg-muted border border-border text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </TabsContent>

              <TabsContent value="all" className="mb-4">
                <p className="text-xs text-muted-foreground">
                  La notification sera envoyée à tous les utilisateurs ayant un
                  appareil enregistré (token FCM).
                </p>
              </TabsContent>

              {/* Champs communs */}
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Titre *</Label>
                    <Input
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      placeholder="Ex : Nouvel enseignement disponible"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Type de notification</Label>
                    <Select value={notifType} onValueChange={setNotifType}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {NOTIF_TYPES.map((t) => (
                          <SelectItem key={t.value} value={t.value}>
                            {t.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Message *</Label>
                  <Textarea
                    value={body}
                    onChange={(e) => setBody(e.target.value)}
                    rows={4}
                    placeholder="Ex : Découvrez notre nouvel enseignement sur la foi…"
                  />
                </div>

                <div className="space-y-2">
                  <Label>URL de l'image (optionnel)</Label>
                  <Input
                    type="url"
                    value={imageUrl}
                    onChange={(e) => setImageUrl(e.target.value)}
                    placeholder="https://example.com/image.jpg"
                  />
                </div>

                {/* Données personnalisées */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label>Données personnalisées (optionnel)</Label>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="gap-1.5 h-7 text-xs"
                      onClick={() =>
                        setDataPairs([...dataPairs, { key: "", value: "" }])
                      }
                    >
                      <Plus className="w-3 h-3" />
                      Ajouter
                    </Button>
                  </div>
                  {dataPairs.length === 0 ? (
                    <p className="text-xs text-muted-foreground">
                      Paires clé/valeur ajoutées au payload <code>data</code> de
                      la notification (ex. <code>enseignementId</code>).
                    </p>
                  ) : (
                    <div className="space-y-2">
                      {dataPairs.map((pair, i) => (
                        <div key={i} className="flex items-center gap-2">
                          <Input
                            value={pair.key}
                            onChange={(e) => {
                              const next = [...dataPairs];
                              next[i] = { ...next[i], key: e.target.value };
                              setDataPairs(next);
                            }}
                            placeholder="clé"
                            className="font-mono text-xs"
                          />
                          <Input
                            value={pair.value}
                            onChange={(e) => {
                              const next = [...dataPairs];
                              next[i] = { ...next[i], value: e.target.value };
                              setDataPairs(next);
                            }}
                            placeholder="valeur"
                            className="font-mono text-xs"
                          />
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() =>
                              setDataPairs(
                                dataPairs.filter((_, j) => j !== i)
                              )
                            }
                          >
                            <Trash2 className="w-4 h-4 text-destructive" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {result && (
                  <div
                    className={`flex items-start gap-2 p-3 rounded-xl border text-sm ${
                      result.ok
                        ? "bg-success/10 border-success/30 text-success"
                        : "bg-destructive/10 border-destructive/25 text-destructive"
                    }`}
                  >
                    {result.ok ? (
                      <CheckCircle2 className="w-4 h-4 mt-0.5 shrink-0" />
                    ) : (
                      <XCircle className="w-4 h-4 mt-0.5 shrink-0" />
                    )}
                    <span>{result.message}</span>
                  </div>
                )}

                <Button
                  onClick={send}
                  disabled={!canSend}
                  className="w-full gap-2"
                >
                  {sending ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Envoi en cours…
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4" />
                      Envoyer la notification
                    </>
                  )}
                </Button>
              </div>
            </Tabs>
          </CardContent>
        </Card>

        {/* Informations */}
        <Card className="h-fit">
          <CardHeader>
            <CardTitle className="text-sm font-medium">Informations</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm text-muted-foreground">
            <div className="flex items-start gap-2">
              <Badge
                variant="outline"
                className="mt-0.5 border-accent/40 text-accent-foreground"
              >
                1
              </Badge>
              <p>
                Les notifications sont envoyées via Firebase Cloud Messaging aux
                appareils ayant un token enregistré.
              </p>
            </div>
            <div className="flex items-start gap-2">
              <Badge
                variant="outline"
                className="mt-0.5 border-accent/40 text-accent-foreground"
              >
                2
              </Badge>
              <p>
                Le champ <code>type</code> détermine l'action effectuée lors du
                tap sur la notification dans l'application.
              </p>
            </div>
            <div className="flex items-start gap-2">
              <Badge
                variant="outline"
                className="mt-0.5 border-accent/40 text-accent-foreground"
              >
                3
              </Badge>
              <p>
                L'image est affichée dans la notification si une URL est
                fournie.
              </p>
            </div>
            <div className="flex items-start gap-2">
              <Badge
                variant="outline"
                className="mt-0.5 border-accent/40 text-accent-foreground"
              >
                4
              </Badge>
              <p>
                Des notifications automatiques sont envoyées lors de la création
                de contenu (calendrier, enseignements, annonces, lives).
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardShell>
  );
}
