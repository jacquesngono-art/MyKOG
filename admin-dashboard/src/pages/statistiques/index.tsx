import { useState, useEffect } from 'react';
import {
  UserGroupIcon,
  PlayCircleIcon,
  CloudIcon,
  BookOpenIcon,
  DocumentTextIcon,
  TvIcon,
} from '@heroicons/react/24/outline';
import { statsService } from '../../lib/services/stats';

export default function StatistiquesPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  async function loadStats() {
    try {
      const data = await statsService.getDashboardStats();
      setStats(data);
    } catch (err) {
      console.error('Erreur chargement stats:', err);
    } finally {
      setLoading(false);
    }
  }

  const cards = [
    { label: 'Utilisateurs', value: stats?.totalUsers.toLocaleString() || '0', icon: UserGroupIcon, color: 'bg-primary-fixed text-primary' },
    { label: 'Enseignements', value: stats?.totalEnseignements.toLocaleString() || '0', icon: BookOpenIcon, color: 'bg-green-100 text-status-success' },
    { label: 'Écoutes', value: stats?.totalPlays.toLocaleString() || '0', icon: PlayCircleIcon, color: 'bg-tertiary-fixed text-tertiary' },
    { label: 'PDF', value: stats?.totalPdfs.toLocaleString() || '0', icon: DocumentTextIcon, color: 'bg-purple-100 text-purple-700' },
    { label: 'Vues PDF', value: stats?.totalPdfViews.toLocaleString() || '0', icon: CloudIcon, color: 'bg-blue-100 text-blue-700' },
    { label: 'Lives Actifs', value: String(stats?.activeLives || 0), icon: TvIcon, color: 'bg-error-container text-error' },
  ];

  return (
    <>
      <div className="mb-8">
        <h2 className="font-headline-lg text-headline-lg text-on-surface mb-1">Statistiques</h2>
        <p className="font-body-lg text-body-lg text-secondary">Analytiques et métriques de la plateforme.</p>
      </div>

      {loading ? (
        <div className="text-center py-12 text-secondary">Chargement...</div>
      ) : (
      <div className="grid grid-cols-1 md:grid-cols-3 gap-gutter mb-8">
        {cards.map((s) => {
          const StatIcon = s.icon;
          return (
            <div key={s.label} className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle flex items-center justify-between">
              <div>
                <p className="font-label-sm text-label-sm text-secondary mb-1">{s.label}</p>
                <p className="font-headline-sm text-headline-sm text-on-surface">{s.value}</p>
              </div>
              <span className={`p-3 ${s.color} rounded-lg`}><StatIcon className="w-6 h-6" /></span>
            </div>
          );
        })}
      </div>
      )}
    </>
  );
}
