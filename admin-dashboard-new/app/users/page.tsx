"use client";

import { useEffect, useState } from "react";
import { DashboardShell } from "@/components/dashboard/dashboard-shell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
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
import {
  Users,
  Heart,
  Download,
  Bell,
  Mail,
  Trash2,
  Eye,
  History,
} from "lucide-react";
import { usersService } from "@/lib/services/users";
import { enseignementsService } from "@/lib/services/enseignements";
import type { User, UserStats, Enseignement } from "@/lib/types";
import { format } from "date-fns";
import { fr } from "date-fns/locale/fr";

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [stats, setStats] = useState<UserStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<User | null>(null);
  const [teachings, setTeachings] = useState<Map<string, Enseignement>>(
    new Map()
  );
  const [deleteAllOpen, setDeleteAllOpen] = useState(false);
  const [deletingAll, setDeletingAll] = useState(false);

  const load = async () => {
    try {
      const [usersData, statsData, teachingsData] = await Promise.all([
        usersService.getAll(),
        usersService.getStats().catch(() => null),
        enseignementsService.getAll().catch(() => [] as Enseignement[]),
      ]);
      setUsers(usersData);
      setStats(statsData);
      setTeachings(new Map(teachingsData.map((t) => [t.id, t])));
      setError(null);
    } catch (e: any) {
      setError(e.message || "Erreur lors du chargement");
    } finally {
      setLoading(false);
    }
  };

  const teachLabel = (id: string) => {
    const t = teachings.get(id);
    return t ? `${t.title} — ${t.speaker}` : id;
  };

  useEffect(() => {
    load();
  }, []);

  const remove = async (id: string) => {
    if (!confirm("Supprimer cet utilisateur ?")) return;
    try {
      await usersService.delete(id);
      if (selected?.id === id) setSelected(null);
      await load();
    } catch (e: any) {
      setError(e.message || "Erreur lors de la suppression");
    }
  };

  const removeAll = async () => {
    setDeletingAll(true);
    try {
      await usersService.deleteAll();
      setSelected(null);
      await load();
    } catch (e: any) {
      setError(e.message || "Erreur lors de la suppression");
    } finally {
      setDeletingAll(false);
    }
  };

  const statCards = [
    {
      label: "Total utilisateurs",
      value: stats?.totalUsers ?? "—",
      icon: Users,
      sub: null as string | null,
    },
    {
      label: "Avec favoris",
      value: stats?.usersWithFavorites ?? "—",
      icon: Heart,
      sub: stats ? `${stats.totalFavorites} favoris au total` : null,
    },
    {
      label: "Avec téléchargements",
      value: stats?.usersWithDownloads ?? "—",
      icon: Download,
      sub: stats ? `${stats.totalDownloads} téléchargements` : null,
    },
    {
      label: "Notifications activées",
      value: stats?.notificationsEnabled ?? "—",
      icon: Bell,
      sub: stats ? `${stats.notificationsDisabled} désactivées` : null,
    },
  ];

  return (
    <DashboardShell
      title="Utilisateurs"
      subtitle="Gestion des utilisateurs de l'application"
      onRefresh={load}
      actions={
        <Button
          variant="outline"
          size="sm"
          className="gap-2 text-destructive border-destructive/30 hover:bg-destructive/10"
          onClick={() => setDeleteAllOpen(true)}
          disabled={users.length === 0}
        >
          <Trash2 className="w-4 h-4" />
          Tout supprimer
        </Button>
      }
    >
      {/* Statistiques */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {statCards.map((c) => (
          <Card key={c.label}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {c.label}
              </CardTitle>
              <c.icon className="w-4 h-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="text-3xl font-semibold tracking-tight">
                {loading && stats === null ? "…" : c.value}
              </p>
              {c.sub && (
                <p className="text-xs text-muted-foreground mt-1">{c.sub}</p>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      {error && (
        <div className="mb-4 p-3 rounded-xl bg-destructive/10 border border-destructive/25 text-destructive text-sm">
          {error}
        </div>
      )}

      {/* Liste des utilisateurs */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <Users className="w-4 h-4 text-muted-foreground" />
            Utilisateurs ({users.length})
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Chargement…
            </p>
          ) : users.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted-foreground">
              Aucun utilisateur enregistré
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Utilisateur</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead className="text-center">Favoris</TableHead>
                  <TableHead className="text-center">Téléchargements</TableHead>
                  <TableHead>Notifications</TableHead>
                  <TableHead>Inscription</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.map((user) => (
                  <TableRow
                    key={user.id}
                    className="cursor-pointer"
                    onClick={() => setSelected(user)}
                  >
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar className="h-9 w-9">
                          {user.profileImageUrl && (
                            <AvatarImage
                              src={user.profileImageUrl}
                              alt={user.name}
                            />
                          )}
                          <AvatarFallback className="bg-accent/15 text-accent-foreground text-sm font-medium">
                            {(user.name || "?").charAt(0).toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                        <div className="min-w-0">
                          <p className="text-sm font-medium truncate">
                            {user.name || "Sans nom"}
                          </p>
                          <p className="text-xs text-muted-foreground font-mono truncate max-w-[140px]">
                            {user.id}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      <span className="inline-flex items-center gap-1.5 text-sm">
                        <Mail className="w-3.5 h-3.5" />
                        {user.email || "—"}
                      </span>
                    </TableCell>
                    <TableCell className="text-center">
                      <span className="inline-flex items-center gap-1 text-sm">
                        <Heart className="w-3.5 h-3.5 text-destructive" />
                        {user.favoriteTeachingIds?.length || 0}
                      </span>
                    </TableCell>
                    <TableCell className="text-center">
                      <span className="inline-flex items-center gap-1 text-sm">
                        <Download className="w-3.5 h-3.5 text-success" />
                        {user.downloadedTeachingIds?.length || 0}
                      </span>
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant="outline"
                        className={
                          user.notificationsEnabled
                            ? "border-success/40 text-success"
                            : "text-muted-foreground"
                        }
                      >
                        {user.notificationsEnabled ? "Activées" : "Désactivées"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {user.createdAt
                        ? format(new Date(user.createdAt), "d MMM yyyy", {
                            locale: fr,
                          })
                        : "—"}
                    </TableCell>
                    <TableCell
                      className="text-right"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <div className="flex justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setSelected(user)}
                          title="Détails"
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => remove(user.id)}
                          title="Supprimer"
                        >
                          <Trash2 className="w-4 h-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Dialog détails utilisateur */}
      <Dialog open={!!selected} onOpenChange={(o) => !o && setSelected(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Détails de l'utilisateur</DialogTitle>
          </DialogHeader>
          {selected && (
            <div className="space-y-4 py-2">
              <div className="flex items-center gap-4">
                <Avatar className="h-14 w-14">
                  {selected.profileImageUrl && (
                    <AvatarImage
                      src={selected.profileImageUrl}
                      alt={selected.name}
                    />
                  )}
                  <AvatarFallback className="bg-accent/15 text-accent-foreground text-lg font-medium">
                    {(selected.name || "?").charAt(0).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                <div className="min-w-0">
                  <p className="font-semibold text-foreground">
                    {selected.name || "Sans nom"}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {selected.email || "—"}
                  </p>
                  <p className="text-xs text-muted-foreground font-mono">
                    {selected.id}
                  </p>
                </div>
                <Badge
                  variant="outline"
                  className={
                    selected.notificationsEnabled
                      ? "ml-auto border-success/40 text-success"
                      : "ml-auto text-muted-foreground"
                  }
                >
                  <Bell className="w-3 h-3 mr-1" />
                  {selected.notificationsEnabled
                    ? "Notifications activées"
                    : "Notifications désactivées"}
                </Badge>
              </div>

              <div>
                <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1.5">
                  Favoris ({selected.favoriteTeachingIds?.length || 0})
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {selected.favoriteTeachingIds?.length ? (
                    selected.favoriteTeachingIds.map((id) => (
                      <Badge
                        key={id}
                        variant="outline"
                        className="text-[10px] border-destructive/30 text-destructive"
                      >
                        {teachLabel(id)}
                      </Badge>
                    ))
                  ) : (
                    <span className="text-sm text-muted-foreground">
                      Aucun favori
                    </span>
                  )}
                </div>
              </div>

              <div>
                <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1.5">
                  Téléchargements ({selected.downloadedTeachingIds?.length || 0})
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {selected.downloadedTeachingIds?.length ? (
                    selected.downloadedTeachingIds.map((id) => (
                      <Badge
                        key={id}
                        variant="outline"
                        className="text-[10px] border-success/30 text-success"
                      >
                        {teachLabel(id)}
                      </Badge>
                    ))
                  ) : (
                    <span className="text-sm text-muted-foreground">
                      Aucun téléchargement
                    </span>
                  )}
                </div>
              </div>

              <div>
                <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1.5 flex items-center gap-1">
                  <History className="w-3 h-3" />
                  Récemment joués ({selected.recentlyPlayedIds?.length || 0})
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {selected.recentlyPlayedIds?.length ? (
                    selected.recentlyPlayedIds.slice(0, 10).map((id) => (
                      <Badge
                        key={id}
                        variant="outline"
                        className="text-[10px] bg-accent/15 text-accent-foreground border-accent/30"
                      >
                        {teachLabel(id)}
                      </Badge>
                    ))
                  ) : (
                    <span className="text-sm text-muted-foreground">Aucun</span>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 pt-2 border-t border-border">
                <div>
                  <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1">
                    Date de création
                  </p>
                  <p className="text-sm">
                    {selected.createdAt
                      ? format(
                          new Date(selected.createdAt),
                          "d MMMM yyyy à HH:mm",
                          { locale: fr }
                        )
                      : "—"}
                  </p>
                </div>
                <div>
                  <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-1">
                    Dernière mise à jour
                  </p>
                  <p className="text-sm">
                    {selected.updatedAt
                      ? format(
                          new Date(selected.updatedAt),
                          "d MMMM yyyy à HH:mm",
                          { locale: fr }
                        )
                      : "—"}
                  </p>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            {selected && (
              <Button
                variant="outline"
                className="gap-2 text-destructive border-destructive/30 hover:bg-destructive/10 mr-auto"
                onClick={() => remove(selected.id)}
              >
                <Trash2 className="w-4 h-4" />
                Supprimer
              </Button>
            )}
            <Button variant="outline" onClick={() => setSelected(null)}>
              Fermer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmation suppression totale */}
      <AlertDialog open={deleteAllOpen} onOpenChange={setDeleteAllOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Supprimer tous les utilisateurs ?</AlertDialogTitle>
            <AlertDialogDescription>
              Cette action est irréversible. Les {users.length} utilisateurs et
              leurs données (favoris, téléchargements, historique) seront
              définitivement supprimés.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Annuler</AlertDialogCancel>
            <AlertDialogAction
              onClick={removeAll}
              disabled={deletingAll}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deletingAll ? "Suppression…" : "Tout supprimer"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </DashboardShell>
  );
}
