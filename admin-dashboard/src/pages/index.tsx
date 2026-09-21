import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  PlusCircleIcon,
  SignalIcon,
  UserGroupIcon,
  ArrowTrendingUpIcon,
  PlayCircleIcon,
  BookOpenIcon,
  ArrowDownTrayIcon,
  TvIcon,
  ArrowRightIcon,
  ChartBarSquareIcon,
  CheckBadgeIcon,
  PlayIcon,
  MicrophoneIcon,
  FlagIcon,
  DocumentTextIcon,
  EllipsisVerticalIcon,
  SparklesIcon,
} from '@heroicons/react/24/outline';
import { statsService } from '../lib/services/stats';
import { enseignementsService } from '../lib/services/enseignements';
import { annoncesService } from '../lib/services/annonces';
import { usePolling } from '../hooks/usePolling';
import { isRecent } from '../lib/utils';

interface DashStats {
  totalUsers: number;
  totalEnseignements: number;
  activeLives: number;
  totalPlays: number;
  totalPdfViews: number;
  totalPdfs: number;
}

const defaultStats: DashStats = {
  totalUsers: 0,
  totalEnseignements: 0,
  activeLives: 0,
  totalPlays: 0,
  totalPdfViews: 0,
  totalPdfs: 0,
};

export default function DashboardPage() {
  const [stats, setStats] = useState<DashStats>(defaultStats);
  const [recentItems, setRecentItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboard();
  }, []);
  usePolling(refreshDashboard, 30000);

  async function loadDashboard() {
    try {
      const [dashStats, enseignements, annonces] = await Promise.all([
        statsService.getDashboardStats(),
        enseignementsService.getAll(),
        annoncesService.getAll(),
      ]);
      setStats(dashStats);

      const items = [
        ...enseignements.slice(0, 3).map((e: any) => ({
          title: e.title,
          subtitle: `Ajouté le ${new Date(e.createdAt).toLocaleDateString('fr-FR')}`,
          category: e.category,
          speaker: e.speaker,
          status: e.isNew ? 'Publié' : 'Brouillon',
          statusColor: 'text-status-success',
          dotColor: 'bg-status-success',
          icon: MicrophoneIcon,
          iconBg: 'bg-primary-fixed text-primary',
          createdAt: e.createdAt,
        })),
        ...annonces.slice(0, 2).map((a: any) => ({
          title: a.nom,
          subtitle: `Annonce • ${new Date(a.dateCreation).toLocaleDateString('fr-FR')}`,
          category: 'Annonce',
          speaker: 'Admin',
          status: 'Publié',
          statusColor: 'text-status-success',
          dotColor: 'bg-status-success',
          icon: FlagIcon,
          iconBg: 'bg-tertiary-fixed text-tertiary',
          createdAt: a.dateCreation,
        })),
      ];
      setRecentItems(items);
    } catch (err) {
      console.error('Erreur chargement dashboard:', err);
    } finally {
      setLoading(false);
    }
  }

  async function refreshDashboard() {
    try {
      const [dashStats, enseignements, annonces] = await Promise.all([
        statsService.getDashboardStats(),
        enseignementsService.getAll(),
        annoncesService.getAll(),
      ]);
      setStats(dashStats);
      setRecentItems([
        ...enseignements.slice(0, 3).map((e: any) => ({
          title: e.title,
          subtitle: `Ajouté le ${new Date(e.createdAt).toLocaleDateString('fr-FR')}`,
          category: e.category,
          speaker: e.speaker,
          status: e.isNew ? 'Publié' : 'Brouillon',
          statusColor: 'text-status-success',
          dotColor: 'bg-status-success',
          icon: MicrophoneIcon,
          iconBg: 'bg-primary-fixed text-primary',
          createdAt: e.createdAt,
        })),
        ...annonces.slice(0, 2).map((a: any) => ({
          title: a.nom,
          subtitle: `Annonce • ${new Date(a.dateCreation).toLocaleDateString('fr-FR')}`,
          category: 'Annonce',
          speaker: 'Admin',
          status: 'Publié',
          statusColor: 'text-status-success',
          dotColor: 'bg-status-success',
          icon: FlagIcon,
          iconBg: 'bg-tertiary-fixed text-tertiary',
          createdAt: a.dateCreation,
        })),
      ]);
    } catch {
      // silencieux – le serveur peut être temporairement indisponible
    }
  }

  const statCards = [
    { label: 'Total Users', value: stats.totalUsers.toLocaleString(), change: '', icon: UserGroupIcon, iconBg: 'bg-secondary-container text-secondary', changeClass: 'text-status-success' },
    { label: 'Active Lives', value: String(stats.activeLives), badge: 'LIVE', icon: PlayCircleIcon, iconBg: 'bg-tertiary-fixed text-tertiary', changeClass: 'text-status-live' },
    { label: 'Teachings', value: stats.totalEnseignements.toLocaleString(), icon: BookOpenIcon, iconBg: 'bg-secondary-container text-secondary' },
    { label: 'PDF Downloads', value: stats.totalPdfViews.toLocaleString(), suffix: `${stats.totalPdfs} docs`, icon: ArrowDownTrayIcon, iconBg: 'bg-secondary-container text-secondary', changeClass: 'text-primary' },
  ];

  return (
    <>
      <div className="flex justify-between items-end">
        <div>
          <h1 className="font-headline-lg text-headline-lg text-on-background mb-1">
            Paix sur vous, Admin
          </h1>
          <p className="font-body-lg text-body-lg text-secondary">
            Aperçu de l'impact du ministère pour cette semaine.
          </p>
        </div>
        <div className="flex space-x-3">
          <Link href="/calendar" className="flex items-center px-5 py-2.5 bg-secondary text-white rounded-lg font-label-md text-label-md transition-transform hover:scale-[1.02] active:scale-[0.98]">
            <PlusCircleIcon className="w-5 h-5 mr-2" />Nouvel Événement
          </Link>
          <Link href="/lives" className="flex items-center px-5 py-2.5 bg-primary text-white rounded-lg font-label-md text-label-md transition-transform hover:scale-[1.02] active:scale-[0.98]">
            <SignalIcon className="w-5 h-5 mr-2" />Démarrer un Live
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-gutter">
        <div className="col-span-12 lg:col-span-8 grid grid-cols-4 gap-gutter">
          {statCards.map((s) => {
            const Icon = s.icon;
            return (
              <div key={s.label} className="col-span-2 md:col-span-1 bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-transparent hover:border-primary/20 transition-all group">
                <div className="flex justify-between items-start mb-4">
                  <span className={`p-2 ${s.iconBg} rounded-lg group-hover:bg-primary group-hover:text-white transition-colors`}>
                    <Icon className="w-5 h-5" />
                  </span>
                  {s.change && (
                    <span className={`${s.changeClass} flex items-center font-label-sm text-label-sm`}>
                      <ArrowTrendingUpIcon className="w-3.5 h-3.5 mr-1" />{s.change}
                    </span>
                  )}
                  {s.badge && (
                    <span className={`${s.changeClass} flex items-center font-label-sm text-label-sm`}>
                      <span className="w-2 h-2 rounded-full bg-current mr-1 animate-pulse" />{s.badge}
                    </span>
                  )}
                  {s.suffix && (
                    <span className={`${s.changeClass} flex items-center font-label-sm text-label-sm`}>{s.suffix}</span>
                  )}
                </div>
                <p className="font-label-md text-label-md text-secondary mb-1">{s.label}</p>
                <h3 className="font-headline-md text-headline-md font-bold">{s.value}</h3>
              </div>
            );
          })}

          <div className="col-span-4 bg-surface-container-lowest rounded-xl shadow-sm overflow-hidden flex flex-col md:flex-row h-64 border border-transparent hover:shadow-md transition-all">
            <div className="w-full md:w-1/2 relative bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center">
              <TvIcon className="w-20 h-20 text-white/20" />
              {stats.activeLives > 0 && (
                <div className="absolute top-4 left-4 bg-status-live text-white px-3 py-1 rounded-full text-label-sm font-bold flex items-center shadow-lg">
                  <span className="w-2 h-2 bg-white rounded-full mr-2 animate-pulse" />LIVE NOW
                </div>
              )}
            </div>
            <div className="w-full md:w-1/2 p-card-padding flex flex-col justify-between">
              <div>
                <span className="bg-primary-fixed text-on-primary-fixed px-2 py-0.5 rounded text-label-sm mb-3 inline-block uppercase tracking-wider">Sunday Service</span>
                <h4 className="font-headline-sm text-headline-sm mb-2">MyKOG Terminal</h4>
                <p className="text-body-md text-secondary line-clamp-2">
                  {stats.activeLives > 0 ? `${stats.activeLives} live(s) en cours` : 'Aucun live actif pour le moment'}
                </p>
              </div>
              <div className="flex items-center justify-between border-t border-border-subtle pt-4 mt-4">
                <Link href="/lives" className="text-primary font-label-md text-label-md flex items-center hover:underline">
                  Studio <ArrowRightIcon className="w-4 h-4 ml-1" />
                </Link>
              </div>
            </div>
          </div>
        </div>

        <div className="col-span-12 lg:col-span-4 space-y-gutter">
          <div className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm">
            <div className="flex justify-between items-center mb-6">
              <h4 className="font-label-md text-label-md uppercase text-secondary tracking-widest">Métriques en temps réel</h4>
              <ChartBarSquareIcon className="w-5 h-5 text-outline" />
            </div>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-body-md text-secondary">Total Utilisateurs</span>
                <span className="font-bold">{stats.totalUsers.toLocaleString()}</span>
              </div>
              <div className="w-full bg-surface-container-low h-1 rounded-full overflow-hidden">
                <div className="bg-primary h-full w-[70%]" />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-body-md text-secondary">Total Écoutes</span>
                <span className="font-bold">{stats.totalPlays.toLocaleString()}</span>
              </div>
              <div className="w-full bg-surface-container-low h-1 rounded-full overflow-hidden">
                <div className="bg-tertiary h-full w-[85%]" />
              </div>
            </div>
          </div>

          <div className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-dashed border-primary/30">
            <div className="flex items-center mb-4">
              <CheckBadgeIcon className="w-5 h-5 text-primary mr-2" />
              <h4 className="font-label-md text-label-md font-bold">Dernier Enseignement</h4>
            </div>
            <p className="text-[12px] text-secondary">{stats.totalEnseignements} enseignement(s) disponibles</p>
          </div>
        </div>

        <div className="col-span-12">
          <div className="bg-surface-container-lowest rounded-xl shadow-sm overflow-hidden">
            <div className="px-card-padding py-4 border-b border-border-subtle flex justify-between items-center">
              <h3 className="font-headline-sm text-headline-sm">Enseignements & Annonces récents</h3>
            </div>
            {loading ? (
              <div className="p-8 text-center text-secondary">Chargement...</div>
            ) : recentItems.length === 0 ? (
              <div className="p-8 text-center text-secondary">Aucun élément récent</div>
            ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-surface-container-low border-b border-border-subtle">
                  <tr>
                    <th className="px-card-padding py-3 font-label-md text-label-md text-secondary uppercase">Ressource</th>
                    <th className="px-card-padding py-3 font-label-md text-label-md text-secondary uppercase">Catégorie</th>
                    <th className="px-card-padding py-3 font-label-md text-label-md text-secondary uppercase">Intervenant</th>
                    <th className="px-card-padding py-3 font-label-md text-label-md text-secondary uppercase">Statut</th>
                    <th className="px-card-padding py-3 font-label-md text-label-md text-secondary uppercase text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-subtle">
                  {recentItems.map((act, i) => {
                    const Icon = act.icon;
                    return (
                      <tr key={i} className="hover:bg-surface-container-low/50 transition-colors">
                        <td className="px-card-padding py-4">
                          <div className="flex items-center">
                            <div className={`p-2 ${act.iconBg} rounded mr-3`}><Icon className="w-5 h-5" /></div>
                            <div>
                              <p className="font-bold text-on-surface flex items-center gap-2">
                                {act.title}
                                {isRecent(act.createdAt) && (
                                  <span className="flex items-center gap-1 px-1.5 py-0.5 rounded-full font-label-sm text-label-sm bg-error/90 text-white">
                                    <SparklesIcon className="w-2.5 h-2.5" />Nouveau
                                  </span>
                                )}
                              </p>
                              <p className="text-label-sm text-secondary">{act.subtitle}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-card-padding py-4">
                          <span className="bg-secondary-container text-on-secondary-container px-2 py-1 rounded-full text-label-sm">{act.category}</span>
                        </td>
                        <td className="px-card-padding py-4 text-body-md">{act.speaker}</td>
                        <td className="px-card-padding py-4">
                          <span className={`flex items-center ${act.statusColor} font-label-md`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${act.dotColor} mr-2`} />{act.status}
                          </span>
                        </td>
                        <td className="px-card-padding py-4 text-right">
                          <button className="text-outline hover:text-primary transition-colors">
                            <EllipsisVerticalIcon className="w-5 h-5" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
