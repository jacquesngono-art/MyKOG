import { useState, useEffect } from 'react';
import {
  PencilIcon,
  PlusIcon,
  EyeIcon,
  BoltIcon,
  TvIcon,
  ClipboardIcon,
  Cog6ToothIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { livesService } from '../../lib/services/lives';
import type { LiveStream, ServerInfo } from '../../lib/types';

const emptyForm = {
  title: '',
  pastor: '',
  description: '',
  scheduledAt: '',
  status: 'scheduled' as 'scheduled' | 'live' | 'ended',
  tags: '',
};

export default function LivesPage() {
  const [lives, setLives] = useState<LiveStream[]>([]);
  const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'live' | 'scheduled' | 'ended'>('live');
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState({ ...emptyForm });
  const [saving, setSaving] = useState(false);

  const activeLive = lives.find(l => l.status === 'live');
  const filteredLives = lives.filter(l => l.status === activeTab);

  useEffect(() => {
    loadAll();
  }, []);

  async function loadAll() {
    try {
      const [livesData, info] = await Promise.all([
        livesService.getAll(),
        livesService.getServerInfo().catch(() => null),
      ]);
      setLives(livesData);
      setServerInfo(info);
    } catch (err) {
      console.error('Erreur chargement lives:', err);
    } finally {
      setLoading(false);
    }
  }

  function openCreate() {
    setForm({ ...emptyForm });
    setEditingId(null);
    setShowModal(true);
  }

  function openEdit(live: LiveStream) {
    setForm({
      title: live.title,
      pastor: live.pastor,
      description: live.description || '',
      scheduledAt: live.scheduledAt ? live.scheduledAt.slice(0, 16) : '',
      status: live.status,
      tags: (live.tags || []).join(', '),
    });
    setEditingId(live.id);
    setShowModal(true);
  }

  async function handleSave() {
    if (!form.title.trim() || !form.pastor.trim()) return;
    setSaving(true);
    try {
      const payload = {
        title: form.title.trim(),
        pastor: form.pastor.trim(),
        description: form.description.trim(),
        scheduledAt: form.scheduledAt ? new Date(form.scheduledAt).toISOString() : null,
        status: form.status,
        tags: form.tags.split(',').map(t => t.trim()).filter(Boolean),
      };
      if (editingId) {
        await livesService.update(editingId, payload);
      } else {
        await livesService.create(payload);
      }
      setShowModal(false);
      await loadAll();
    } catch (err: any) {
      alert('Erreur: ' + err.message);
    } finally {
      setSaving(false);
    }
  }

  async function handleStatusChange(id: string, status: 'scheduled' | 'live' | 'ended') {
    try {
      await livesService.updateStatus(id, status);
      await loadAll();
    } catch (err: any) {
      alert('Erreur: ' + err.message);
    }
  }

  const statusBtn = (s: typeof activeTab) => {
    const active = s === activeTab;
    const colors: Record<string, string> = {
      scheduled: 'bg-surface-container-high text-secondary',
      live: 'bg-error text-white',
      ended: 'bg-on-background text-white',
    };
    return (
      <button onClick={() => setActiveTab(s)} className={`px-4 py-1.5 rounded-md font-label-md text-label-md transition-all ${active ? colors[s] + ' shadow-sm' : 'text-secondary'}`}>
        {s === 'live' ? 'En direct' : s === 'scheduled' ? 'Planifiés' : 'Terminés'}
      </button>
    );
  };

  return (
    <>
      <nav className="flex items-center space-x-2 text-outline mb-2">
        <span className="font-label-md text-label-md">ADMIN</span>
        <span className="text-sm">/</span>
        <span className="font-label-md text-label-md text-primary">LIVE CONTROL CENTER</span>
      </nav>

      <div className="flex justify-between items-end mb-8">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-surface">
            {activeLive ? activeLive.title : 'Contrôle des Lives'}
          </h2>
          <div className="flex items-center mt-2 space-x-4">
            {activeLive ? (
              <div className="flex items-center px-3 py-1 rounded-full bg-error-container text-error font-label-md text-label-md">
                <span className="w-2 h-2 bg-error rounded-full mr-2 stream-pulse" />EN DIRECT
              </div>
            ) : lives.filter(l => l.status === 'live').length === 0 ? (
              <span className="text-secondary font-body-md text-body-md">Aucun live en cours</span>
            ) : null}
          </div>
        </div>
        <div className="flex space-x-3">
          <button onClick={openCreate} className="bg-primary text-white px-4 py-2 rounded-lg font-label-md text-label-md flex items-center hover:bg-opacity-90 transition-colors">
            <PlusIcon className="w-5 h-5 mr-2" />Nouveau Live
          </button>
          <div className="flex p-1 bg-surface-container-high rounded-lg">
            {statusBtn('scheduled')}
            {statusBtn('live')}
            {statusBtn('ended')}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-gutter">
        <div className="col-span-12 lg:col-span-8 space-y-gutter">
          <div className="bg-black rounded-xl overflow-hidden aspect-video relative group shadow-lg">
            <div className="absolute inset-0 bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center">
              <TvIcon className="text-white/60 w-16 h-16" />
              {activeLive && (
                <div className="absolute top-4 right-4 flex space-x-2">
                  <div className="glass-card px-3 py-1.5 rounded-lg flex items-center space-x-2">
                    <EyeIcon className="w-4 h-4 text-error" />
                    <span className="text-on-surface font-label-md text-label-md">{activeLive.viewerCount}</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          <div className="bg-surface-container-lowest rounded-xl p-card-padding shadow-sm">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-headline-sm text-headline-sm text-on-surface">LiveStreams</h3>
            </div>
            {loading ? (
              <div className="text-center py-4 text-secondary">Chargement...</div>
            ) : filteredLives.length === 0 ? (
              <div className="text-center py-4 text-secondary">Aucun live {activeTab === 'live' ? 'en cours' : activeTab === 'scheduled' ? 'planifié' : 'terminé'}</div>
            ) : (
            <div className="space-y-3">
              {filteredLives.map(live => (
                <div key={live.id} className="flex items-center justify-between p-4 rounded-lg border border-border-subtle hover:bg-surface-container-low transition-colors">
                  <div className="flex-1 min-w-0">
                    <p className="font-body-md text-body-md font-semibold text-on-surface">{live.title}</p>
                    <p className="text-label-sm text-secondary">{live.pastor} • {live.viewerCount} spectateur(s)</p>
                  </div>
                  <div className="flex items-center gap-3 ml-4">
                    <span className={`px-2 py-0.5 rounded-md text-label-sm ${
                      live.status === 'live' ? 'bg-status-success/10 text-status-success' :
                      live.status === 'scheduled' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-surface-container-high text-secondary'
                    }`}>
                      {live.status === 'live' ? 'EN DIRECT' : live.status === 'scheduled' ? 'PLANIFIÉ' : 'TERMINÉ'}
                    </span>
                    <button onClick={() => openEdit(live)} className="p-1.5 rounded-lg hover:bg-surface-container-high transition-colors text-secondary" title="Modifier">
                      <PencilIcon className="w-4 h-4" />
                    </button>
                    {live.status === 'scheduled' && (
                      <button onClick={() => handleStatusChange(live.id, 'live')} className="px-3 py-1 bg-error text-white rounded-lg text-label-sm hover:bg-opacity-90">Démarrer</button>
                    )}
                    {live.status === 'live' && (
                      <button onClick={() => handleStatusChange(live.id, 'ended')} className="px-3 py-1 bg-surface-container-high text-secondary rounded-lg text-label-sm hover:bg-opacity-90">Arrêter</button>
                    )}
                  </div>
                </div>
              ))}
            </div>
            )}
          </div>


        </div>

        <div className="col-span-12 lg:col-span-4 space-y-gutter">
          <div className="bg-surface-container-lowest rounded-xl p-card-padding shadow-sm border border-primary/10">
            <h3 className="font-label-md text-label-md text-outline mb-4 uppercase">Métriques</h3>
            {activeLive ? (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-secondary font-body-md text-body-md">Spectateurs</span>
                <span className="text-on-surface font-headline-sm text-headline-sm">{activeLive.viewerCount}</span>
              </div>
              <div className="w-full bg-surface-container-low h-1.5 rounded-full overflow-hidden">
                <div className="bg-primary h-full" style={{ width: `${Math.min(100, (activeLive.viewerCount / Math.max(1, activeLive.peakViewerCount)) * 100)}%` }} />
              </div>
              <div className="grid grid-cols-2 gap-4 mt-4">
                <div>
                  <span className="block font-label-sm text-label-sm text-outline">PIC</span>
                  <span className="font-body-lg text-body-lg font-semibold">{activeLive.peakViewerCount}</span>
                </div>
                <div>
                  <span className="block font-label-sm text-label-sm text-outline">STATUT</span>
                  <span className="font-body-lg text-body-lg font-semibold capitalize">{activeLive.status}</span>
                </div>
              </div>
            </div>
            ) : (
              <div className="text-center py-4 text-secondary">Aucune métrique disponible</div>
            )}
          </div>

          {serverInfo && (
          <div className="bg-surface-container-lowest rounded-xl p-card-padding shadow-sm">
            <div className="flex items-center mb-6">
              <Cog6ToothIcon className="w-5 h-5 text-primary mr-3" />
              <h3 className="font-headline-sm text-headline-sm text-on-surface">Configuration OBS</h3>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block font-label-md text-label-md text-outline mb-2">URL RTMP</label>
                <div className="flex">
                  <input className="flex-1 bg-surface-container-low border border-border-subtle rounded-l-lg px-3 py-2 text-body-md font-mono" readOnly value={serverInfo.rtmpUrl} />
                  <button onClick={() => navigator.clipboard.writeText(serverInfo.rtmpUrl)} className="bg-surface-container-high border-y border-r border-border-subtle rounded-r-lg px-3">
                    <ClipboardIcon className="w-5 h-5 text-secondary" />
                  </button>
                </div>
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-2">STREAM KEY</label>
                <div className="flex">
                  <input className="flex-1 bg-surface-container-low border border-border-subtle rounded-l-lg px-3 py-2 text-body-md font-mono" readOnly type="password" value={serverInfo.streamKey} />
                  <button onClick={() => navigator.clipboard.writeText(serverInfo.streamKey)} className="bg-surface-container-high border-y border-r border-border-subtle rounded-r-lg px-3">
                    <ClipboardIcon className="w-5 h-5 text-secondary" />
                  </button>
                </div>
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-2">URL HLS</label>
                <div className="flex">
                  <input className="flex-1 bg-surface-container-low border border-border-subtle rounded-l-lg px-3 py-2 text-body-md font-mono" readOnly value={serverInfo.hlsUrl} />
                  <button onClick={() => navigator.clipboard.writeText(serverInfo.hlsUrl)} className="bg-surface-container-high border-y border-r border-border-subtle rounded-r-lg px-3">
                    <ClipboardIcon className="w-5 h-5 text-secondary" />
                  </button>
                </div>
              </div>
            </div>
          </div>
          )}
        </div>
      </div>

      {/* Create / Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm" onClick={() => setShowModal(false)}>
          <div className="bg-surface-container-lowest rounded-2xl shadow-xl w-full max-w-lg mx-4 p-6 border border-border-subtle" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-headline-sm text-headline-sm text-on-surface">
                {editingId ? 'Modifier le live' : 'Nouveau live'}
              </h3>
              <button onClick={() => setShowModal(false)} className="p-1.5 rounded-lg hover:bg-surface-container-high transition-colors text-secondary">
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block font-label-md text-label-md text-outline mb-1.5">Titre *</label>
                <input className="w-full bg-surface-container-low border border-border-subtle rounded-lg px-3 py-2.5 text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors"
                  placeholder="Titre du live" value={form.title}
                  onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-1.5">Pasteur / Prédicateur *</label>
                <input className="w-full bg-surface-container-low border border-border-subtle rounded-lg px-3 py-2.5 text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors"
                  placeholder="Nom du pasteur" value={form.pastor}
                  onChange={e => setForm(f => ({ ...f, pastor: e.target.value }))} />
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-1.5">Description</label>
                <textarea className="w-full bg-surface-container-low border border-border-subtle rounded-lg px-3 py-2.5 text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors resize-none"
                  rows={3} placeholder="Description du live (optionnelle)" value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-1.5">Tags (séparés par des virgules)</label>
                <input className="w-full bg-surface-container-low border border-border-subtle rounded-lg px-3 py-2.5 text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors"
                  placeholder="ex: Culte, Dimanche, Prière" value={form.tags}
                  onChange={e => setForm(f => ({ ...f, tags: e.target.value }))} />
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-1.5">Planifier le début</label>
                <input type="datetime-local" className="w-full bg-surface-container-low border border-border-subtle rounded-lg px-3 py-2.5 text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors"
                  value={form.scheduledAt}
                  onChange={e => setForm(f => ({ ...f, scheduledAt: e.target.value }))} />
              </div>
              <div>
                <label className="block font-label-md text-label-md text-outline mb-1.5">Statut</label>
                <select className="w-full bg-surface-container-low border border-border-subtle rounded-lg px-3 py-2.5 text-body-md text-on-surface focus:outline-none focus:border-primary transition-colors"
                  value={form.status}
                  onChange={e => setForm(f => ({ ...f, status: e.target.value as any }))}>
                  <option value="scheduled">Planifié</option>
                  <option value="live">En direct</option>
                  <option value="ended">Terminé</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-3 mt-8 pt-4 border-t border-border-subtle">
              <button onClick={() => setShowModal(false)} className="px-4 py-2 rounded-lg text-secondary hover:bg-surface-container-high transition-colors font-label-md text-label-md">
                Annuler
              </button>
              <button onClick={handleSave} disabled={saving || !form.title.trim() || !form.pastor.trim()}
                className="px-4 py-2 rounded-lg bg-primary text-white font-label-md text-label-md hover:bg-opacity-90 transition-colors disabled:opacity-50">
                {saving ? 'Enregistrement...' : editingId ? 'Enregistrer' : 'Créer le live'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
