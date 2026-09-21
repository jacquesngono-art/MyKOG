import { useState, useEffect, useMemo } from 'react';
import {
  PlusIcon,
  MusicalNoteIcon,
  PencilIcon,
  ChartBarIcon,
  TrashIcon,
  XMarkIcon,
  PhotoIcon,
  CloudArrowUpIcon,
  ClockIcon,
  QueueListIcon,
  PlayIcon,
  CalendarDaysIcon,
  MagnifyingGlassIcon,
  SparklesIcon,
  FunnelIcon,
} from '@heroicons/react/24/outline';
import { api } from '../../lib/api';
import { enseignementsService } from '../../lib/services/enseignements';
import type { Enseignement } from '../../lib/types';
import ConfirmModal from '../../components/ConfirmModal';
import Pagination from '../../components/Pagination';
import { useSearch } from '../../contexts/SearchContext';
import { usePolling } from '../../hooks/usePolling';
import { isRecent, recordVisit } from '../../lib/utils';

const ITEMS_PER_PAGE = 8;

export default function EnseignementsPage() {
  const { query } = useSearch();
  const [teachings, setTeachings] = useState<Enseignement[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ title: '', speaker: '', category: '', description: '', typeCulte: '', mois: '', annee: '' });
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [deleteTarget, setDeleteTarget] = useState<Enseignement | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [page, setPage] = useState(1);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [batchModalOpen, setBatchModalOpen] = useState(false);
  const [batchFilters, setBatchFilters] = useState({ category: '', mois: '', annee: '', typeCulte: '' });
  const [batchDeleting, setBatchDeleting] = useState(false);
  const [batchConfirmOpen, setBatchConfirmOpen] = useState(false);
  const [batchResult, setBatchResult] = useState<{ message: string; deleted: number } | null>(null);

  function validateForm() {
    const errs: Record<string, string> = {};
    if (!form.title.trim()) errs.title = 'Le titre est requis';
    if (!form.speaker.trim()) errs.speaker = 'L\'intervenant est requis';
    if (!form.category) errs.category = 'La catégorie est requise';
    if (!form.typeCulte) errs.typeCulte = 'Le type de culte est requis';
    if (!form.mois) errs.mois = 'Le thème du mois est requis';
    if (!form.annee) errs.annee = 'L\'année est requise';
    if (form.annee && (!/^\d{4}$/.test(form.annee) || parseInt(form.annee) < 2000 || parseInt(form.annee) > 2100)) errs.annee = 'Année invalide (2000-2100)';
    if (!imageFile) errs.imageFile = 'L\'image de couverture est requise';
    if (!audioFile) errs.audioFile = 'Le fichier audio est requis';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  useEffect(() => { loadTeachings(); }, []);
  usePolling(refreshTeachings, 30000);
  useEffect(() => { recordVisit('enseignements'); }, []);

  async function loadTeachings() {
    try {
      const data = await enseignementsService.getAll();
      setTeachings(data);
    } catch (err) {
      console.error('Erreur chargement enseignements:', err);
    } finally {
      setLoading(false);
    }
  }

  async function refreshTeachings() {
    try {
      const data = await enseignementsService.getAll();
      setTeachings(data);
    } catch {
      // silencieux – le serveur peut être temporairement indisponible
    }
  }

  const filtered = useMemo(() => {
    if (!query.trim()) return teachings;
    const q = query.toLowerCase();
    return teachings.filter(
      (t) =>
        t.title.toLowerCase().includes(q) ||
        t.speaker.toLowerCase().includes(q) ||
        t.category.toLowerCase().includes(q) ||
        t.description?.toLowerCase().includes(q)
    );
  }, [teachings, query]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginated = filtered.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE);

  useEffect(() => { setPage(1); }, [query]);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!validateForm()) return;
    setSaving(true);
    setUploadProgress(0);
    try {
      const fd = new FormData();
      fd.append('title', form.title.trim());
      fd.append('speaker', form.speaker.trim());
      fd.append('category', form.category);
      fd.append('description', form.description.trim());
      fd.append('typeCulte', form.typeCulte);
      fd.append('mois', form.mois);
      fd.append('annee', form.annee);
      fd.append('image', imageFile!);
      fd.append('audio', audioFile!);
      await api.upload('/enseignements', fd, setUploadProgress);
      setModalOpen(false);
      setForm({ title: '', speaker: '', category: '', description: '', typeCulte: '', mois: '', annee: '' });
      setAudioFile(null);
      setImageFile(null);
      setUploadProgress(0);
      setErrors({});
      await loadTeachings();
    } catch (err: any) {
      const msg = err?.response?.data?.error || err?.message || 'Erreur lors de la création';
      setErrors({ form: msg });
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await enseignementsService.delete(deleteTarget.id);
      setDeleteTarget(null);
      await loadTeachings();
    } catch (err) {
      console.error('Erreur suppression:', err);
    } finally {
      setDeleting(false);
    }
  }

  async function handleBatchDelete() {
    const filters: Record<string, string> = {};
    if (batchFilters.category) filters.category = batchFilters.category;
    if (batchFilters.mois) filters.mois = batchFilters.mois;
    if (batchFilters.annee) filters.annee = batchFilters.annee;
    if (batchFilters.typeCulte) filters.typeCulte = batchFilters.typeCulte;
    if (Object.keys(filters).length === 0) return;
    setBatchDeleting(true);
    try {
      const result = await enseignementsService.deleteByFilter(filters);
      setBatchResult(result);
      setBatchConfirmOpen(false);
      setBatchModalOpen(false);
      setBatchFilters({ category: '', mois: '', annee: '', typeCulte: '' });
      await loadTeachings();
    } catch (err) {
      console.error('Erreur suppression groupée:', err);
    } finally {
      setBatchDeleting(false);
    }
  }

  const totalPlays = teachings.reduce((sum, t) => sum + (t.playCount || 0), 0);
  const avgDuration = teachings.length
    ? Math.round(teachings.reduce((sum, t) => sum + (t.duration || 0), 0) / teachings.length / 60)
    : 0;

  return (
    <>
      <div className="flex justify-between items-end mb-8">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-surface mb-1">Gestion des Enseignements</h2>
          <p className="font-body-lg text-body-lg text-secondary">Catalogue et organisation des ressources théologiques.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={() => { setBatchResult(null); setBatchModalOpen(true); }} className="bg-error/10 text-error px-6 py-3 rounded-lg font-label-md text-label-md flex items-center gap-2 hover:bg-error/20 transition-all shadow-sm">
            <FunnelIcon className="w-5 h-5" />Suppression groupée
          </button>
          <button onClick={() => setModalOpen(true)} className="bg-primary text-on-primary px-6 py-3 rounded-lg font-label-md text-label-md flex items-center gap-2 hover:bg-opacity-90 transition-all shadow-sm">
            <PlusIcon className="w-5 h-5" />Ajouter un Enseignement
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-gutter mb-8">
        <div className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle flex items-center justify-between">
          <div><p className="font-label-sm text-label-sm text-secondary mb-1">TOTAL</p><p className="font-headline-sm text-headline-sm text-on-surface">{teachings.length}</p></div>
          <span className="p-3 bg-primary-fixed text-primary rounded-lg"><MusicalNoteIcon className="w-6 h-6" /></span>
        </div>
        <div className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle flex items-center justify-between">
          <div><p className="font-label-sm text-label-sm text-secondary mb-1">ÉCOUTES TOTALES</p><p className="font-headline-sm text-headline-sm text-on-surface">{totalPlays.toLocaleString()}</p></div>
          <span className="p-3 bg-green-100 text-status-success rounded-lg"><ChartBarIcon className="w-6 h-6" /></span>
        </div>
        <div className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle flex items-center justify-between">
          <div><p className="font-label-sm text-label-sm text-secondary mb-1">PUBLIÉS</p><p className="font-headline-sm text-headline-sm text-on-surface">{teachings.filter(t => t.isNew).length}</p></div>
          <span className="p-3 bg-yellow-100 text-status-scheduled rounded-lg"><CloudArrowUpIcon className="w-6 h-6" /></span>
        </div>
        <div className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle flex items-center justify-between">
          <div><p className="font-label-sm text-label-sm text-secondary mb-1">DURÉE MOYENNE</p><p className="font-headline-sm text-headline-sm text-on-surface">{avgDuration}m</p></div>
          <span className="p-3 bg-tertiary-fixed text-tertiary rounded-lg"><ClockIcon className="w-6 h-6" /></span>
        </div>
      </div>

      <div className="bg-surface-container-lowest border border-border-subtle rounded-xl shadow-sm">
        <div className="p-4 border-b border-border-subtle flex items-center gap-4">
          <span className="font-label-md text-label-md text-secondary">{filtered.length} enseignement(s)</span>
          {query && (
            <span className="font-label-sm text-label-sm text-secondary italic">
              Filtré par &quot;{query}&quot;
            </span>
          )}
          <div className="ml-auto flex items-center gap-2">
            <MagnifyingGlassIcon className="w-5 h-5 text-secondary" />
            <QueueListIcon className="w-5 h-5 text-secondary" />
          </div>
        </div>

        {loading ? (
          <div className="p-8 text-center text-secondary">Chargement...</div>
        ) : filtered.length === 0 ? (
          <div className="p-8 text-center text-secondary">
            {query ? `Aucun résultat pour "${query}"` : 'Aucun enseignement trouvé'}
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-gutter p-6">
              {paginated.map((t) => (
                <div key={t.id} className="group bg-surface-container-low rounded-xl border border-border-subtle overflow-hidden hover:shadow-lg transition-all duration-200">
                  <div className="relative aspect-video bg-gradient-to-br from-primary-fixed/30 to-surface-container-high flex items-center justify-center overflow-hidden">
                    {t.artworkUrl ? (
                      <img src={t.artworkUrl} alt="" className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                    ) : (
                      <MusicalNoteIcon className="w-12 h-12 text-outline" />
                    )}
                    <div className="absolute top-2 left-2 flex gap-1">
                      {isRecent(t.createdAt) && (
                        <span className="flex items-center gap-1 px-2 py-0.5 rounded-full font-label-sm text-label-sm bg-error/90 text-white backdrop-blur-sm">
                          <SparklesIcon className="w-3 h-3" />Nouveau
                        </span>
                      )}
                      <span className={`flex items-center gap-1 px-2 py-0.5 rounded-full font-label-sm text-label-sm backdrop-blur-sm ${t.isNew ? 'bg-status-success/90 text-white' : 'bg-surface-container-lowest/80 text-secondary'}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${t.isNew ? 'bg-white' : 'bg-secondary'}`} />
                        {t.isNew ? 'Publié' : 'Brouillon'}
                      </span>
                    </div>
                  </div>
                  <div className="p-4">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <h4 className="font-headline-sm text-headline-sm text-on-surface line-clamp-1 flex-1">{t.title}</h4>
                      <span className="bg-primary-fixed text-primary px-2 py-0.5 rounded-full font-label-sm text-label-sm shrink-0">{t.category}</span>
                    </div>
                    <p className="font-body-md text-body-md text-secondary mb-3">{t.speaker}</p>
                    <div className="flex items-center justify-between pt-3 border-t border-border-subtle">
                      <div className="flex items-center gap-3 text-label-sm text-secondary">
                        <span className="flex items-center gap-1"><PlayIcon className="w-3.5 h-3.5" />{t.playCount ?? 0}</span>
                        <span className="flex items-center gap-1"><CalendarDaysIcon className="w-3.5 h-3.5" />{new Date(t.createdAt).toLocaleDateString('fr-FR')}</span>
                      </div>
                      <div className="flex gap-1">
                        <button className="p-1.5 hover:bg-surface-container-high rounded-lg transition-colors" title="Modifier"><PencilIcon className="w-4 h-4 text-secondary" /></button>
                        <button onClick={() => setDeleteTarget(t)} className="p-1.5 hover:bg-error-container text-error rounded-lg transition-colors" title="Supprimer"><TrashIcon className="w-4 h-4" /></button>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
            <Pagination currentPage={page} totalPages={totalPages} onPageChange={setPage} />
          </>
        )}
      </div>

      <ConfirmModal
        open={!!deleteTarget}
        title="Supprimer l'enseignement"
        message={`Êtes-vous sûr de vouloir supprimer "${deleteTarget?.title}" ? Cette action est irréversible.`}
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />

      <ConfirmModal
        open={batchConfirmOpen}
        title="Confirmer la suppression groupée"
        message={`Êtes-vous sûr de vouloir supprimer tous les enseignements correspondant aux filtres sélectionnés ? Cette action est irréversible.`}
        loading={batchDeleting}
        onConfirm={handleBatchDelete}
        onCancel={() => setBatchConfirmOpen(false)}
      />

      {batchModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[100] flex items-center justify-center p-4" onClick={() => { setBatchModalOpen(false); setBatchResult(null); }}>
          <div className="bg-surface-container-lowest w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden" onClick={(e) => e.stopPropagation()}>
            <div className="px-8 py-6 border-b border-border-subtle flex justify-between items-center">
              <h3 className="font-headline-sm text-headline-sm text-on-surface">Suppression groupée</h3>
              <button onClick={() => { setBatchModalOpen(false); setBatchResult(null); }} className="p-2 hover:bg-surface-container-low rounded-full transition-colors"><XMarkIcon className="w-5 h-5" /></button>
            </div>
            <div className="px-8 py-6 space-y-5">
              {batchResult ? (
                <div className={`p-4 rounded-lg ${batchResult.deleted > 0 ? 'bg-status-success/10 text-status-success' : 'text-secondary bg-surface-container-low'}`}>
                  <p className="font-body-md text-body-md">{batchResult.message}</p>
                </div>
              ) : (
                <>
                  <p className="font-body-md text-body-md text-secondary">Sélectionnez au moins un filtre pour supprimer les enseignements correspondants.</p>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block font-label-md text-label-md text-secondary mb-2">CATÉGORIE</label>
                      <select value={batchFilters.category} onChange={e => setBatchFilters(f => ({ ...f, category: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md">
                        <option value="">Toutes</option>
                        <option>Foundations</option><option>Leadership</option><option>Worship</option><option>Spiritual Growth</option><option>Mariage</option><option>Jeunesse</option>
                      </select>
                    </div>
                    <div>
                      <label className="block font-label-md text-label-md text-secondary mb-2">TYPE DE CULTE</label>
                      <select value={batchFilters.typeCulte} onChange={e => setBatchFilters(f => ({ ...f, typeCulte: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md">
                        <option value="">Tous</option>
                        <option value="Culte d'Impact">Culte d'Impact</option>
                        <option value="Culte Prophétique">Culte Prophétique</option>
                        <option value="Culte d'Enseignement">Culte d'Enseignement</option>
                        <option value="Conférence">Conférence</option>
                        <option value="Séminaire">Séminaire</option>
                      </select>
                    </div>
                    <div>
                      <label className="block font-label-md text-label-md text-secondary mb-2">MOIS</label>
                      <select value={batchFilters.mois} onChange={e => setBatchFilters(f => ({ ...f, mois: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md">
                        <option value="">Tous</option>
                        {Array.from({ length: 12 }, (_, i) => (<option key={i + 1} value={i + 1}>{new Date(0, i).toLocaleString('fr', { month: 'long' })}</option>))}
                      </select>
                    </div>
                    <div>
                      <label className="block font-label-md text-label-md text-secondary mb-2">ANNÉE</label>
                      <input type="number" value={batchFilters.annee} onChange={e => setBatchFilters(f => ({ ...f, annee: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md" placeholder="Ex: 2024" min="2000" max="2100" />
                    </div>
                  </div>
                </>
              )}
            </div>
            <div className="px-8 py-6 bg-surface-container-low border-t border-border-subtle flex justify-end gap-4">
              <button onClick={() => { setBatchModalOpen(false); setBatchResult(null); }} className="px-6 py-2 rounded-lg font-label-md text-label-md text-on-surface-variant hover:bg-surface-container-high transition-colors">Fermer</button>
              {!batchResult && (
                <button
                  onClick={() => {
                    const hasFilter = batchFilters.category || batchFilters.mois || batchFilters.annee || batchFilters.typeCulte;
                    if (!hasFilter) return;
                    setBatchConfirmOpen(true);
                  }}
                  className="bg-error text-white px-6 py-2 rounded-lg font-label-md text-label-md hover:bg-opacity-90 transition-all flex items-center gap-2"
                >
                  <TrashIcon className="w-4 h-4" />Supprimer
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {modalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[100] flex items-center justify-center p-4" onClick={() => { setModalOpen(false); setErrors({}); }}>
          <div className="bg-surface-container-lowest w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col" onClick={(e) => e.stopPropagation()}>
            <div className="px-8 py-6 border-b border-border-subtle flex justify-between items-center">
              <h3 className="font-headline-sm text-headline-sm text-on-surface">Ajouter un Enseignement</h3>
              <button onClick={() => setModalOpen(false)} className="p-2 hover:bg-surface-container-low rounded-full transition-colors"><XMarkIcon className="w-5 h-5" /></button>
            </div>
            <div className="px-8 py-6 overflow-y-auto">
              <form className="space-y-6" onSubmit={handleCreate}>
                <div>
                  <label className="block font-label-md text-label-md text-secondary mb-2">TITRE</label>
                    <input value={form.title} onChange={e => { setForm(f => ({ ...f, title: e.target.value })); if (errors.title) setErrors(e => ({ ...e, title: '' })); }} className={`w-full px-4 py-3 rounded-lg border transition-all font-body-md text-body-md ${errors.title ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:ring-2 focus:ring-primary'}`} placeholder="Titre de l'enseignement" maxLength={200} />
                  {errors.title && <p className="mt-1 text-label-sm text-error">{errors.title}</p>}
                </div>
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label className="block font-label-md text-label-md text-secondary mb-2">THÈME DU MOIS / SAISON</label>
                    <input value={form.mois} onChange={e => setForm(f => ({ ...f, mois: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md" placeholder="Ex: Mois de la Restauration" />
                  </div>
                  <div>
                    <label className="block font-label-md text-label-md text-secondary mb-2">ANNÉE</label>
                    <input type="number" value={form.annee} onChange={e => setForm(f => ({ ...f, annee: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md" placeholder={String(new Date().getFullYear())} />
                  </div>
                </div>
                <div>
                  <label className="block font-label-md text-label-md text-secondary mb-2">CATÉGORIE</label>
                  <select value={form.category} onChange={e => { setForm(f => ({ ...f, category: e.target.value })); if (errors.category) setErrors(e => ({ ...e, category: '' })); }} className={`w-full px-4 py-3 rounded-lg border transition-all font-body-md text-body-md ${errors.category ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:ring-2 focus:ring-primary'}`}>
                    <option value="">Sélectionner...</option>
                    <option>Foundations</option><option>Leadership</option><option>Worship</option><option>Spiritual Growth</option><option>Mariage</option><option>Jeunesse</option>
                  </select>
                  {errors.category && <p className="mt-1 text-label-sm text-error">{errors.category}</p>}
                </div>
                <div>
                  <label className="block font-label-md text-label-md text-secondary mb-2">IMAGE DE COUVERTURE</label>
                  <div className={`border-2 border-dashed rounded-xl p-6 text-center transition-colors cursor-pointer relative ${errors.imageFile ? 'border-error bg-error/5' : 'border-border-subtle hover:border-primary'}`} onClick={() => document.getElementById('image-upload')?.click()}>
                    {imageFile ? (
                      <div className="relative">
                        <img src={URL.createObjectURL(imageFile)} alt="Preview" className="max-h-40 mx-auto rounded-lg object-contain" />
                        <p className="font-label-sm text-label-sm text-secondary mt-2">{imageFile.name}</p>
                      </div>
                    ) : (
                      <><PhotoIcon className="w-10 h-10 text-outline mx-auto mb-2" /><p className="font-body-md text-body-md text-on-surface">Cliquez pour télécharger</p></>
                    )}
                    <input type="file" accept="image/*" onChange={e => { setImageFile(e.target.files?.[0] || null); if (errors.imageFile) setErrors(e => ({ ...e, imageFile: '' })); }} className="hidden" id="image-upload" />
                  </div>
                  {errors.imageFile && <p className="mt-1 text-label-sm text-error">{errors.imageFile}</p>}
                </div>
                <div>
                  <label className="block font-label-md text-label-md text-secondary mb-2">FICHIER AUDIO (MP3)</label>
                  <div className={`rounded-xl p-4 border ${errors.audioFile ? 'border-error bg-error/5' : 'border-border-subtle bg-surface-container-low'}`}>
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 bg-primary-container text-on-primary-container rounded-full flex items-center justify-center"><CloudArrowUpIcon className="w-5 h-5" /></div>
                      <div className="flex-1 min-w-0">
                        <p className="font-body-md text-body-md text-on-surface truncate">{audioFile ? audioFile.name : 'Upload MP3'}</p>
                      </div>
                      <input type="file" accept="audio/*" onChange={e => { setAudioFile(e.target.files?.[0] || null); if (errors.audioFile) setErrors(e => ({ ...e, audioFile: '' })); }} className="hidden" id="audio-upload" />
                      <button type="button" onClick={() => document.getElementById('audio-upload')?.click()} className="text-primary font-label-md hover:underline shrink-0">Parcourir</button>
                    </div>
                    {audioFile && (
                      <div className="mt-3 pt-3 border-t border-border-subtle">
                        <audio controls className="w-full h-10" src={URL.createObjectURL(audioFile)}>Votre navigateur ne supporte pas l'audio.</audio>
                      </div>
                    )}
                  </div>
                  {errors.audioFile && <p className="mt-1 text-label-sm text-error">{errors.audioFile}</p>}
                </div>
                <div className="grid grid-cols-3 gap-6">
                  <div>
                    <label className="block font-label-md text-label-md text-secondary mb-2">TYPE DE CULTE</label>
                    <select value={form.typeCulte} onChange={e => { setForm(f => ({ ...f, typeCulte: e.target.value })); if (errors.typeCulte) setErrors(e => ({ ...e, typeCulte: '' })); }} className={`w-full px-4 py-3 rounded-lg border transition-all font-body-md text-body-md ${errors.typeCulte ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:ring-2 focus:ring-primary'}`}>
                      <option value="">Sélectionner...</option>
                        <option value="Culte d'Impact">Culte d'Impact</option>
                        <option value="Culte Prophétique">Culte Prophétique</option>
                        <option value="Culte d'Enseignement">Culte d'Enseignement</option>
                        <option value="Conférence">Conférence</option>
                        <option value="Séminaire">Séminaire</option>
                      </select>
                    </div>
                    <div>
                      <label className="block font-label-md text-label-md text-secondary mb-2">MOIS</label>
                      <select value={form.mois} onChange={e => { setForm(f => ({ ...f, mois: e.target.value })); if (errors.mois) setErrors(e => ({ ...e, mois: '' })); }} className={`w-full px-4 py-3 rounded-lg border transition-all font-body-md text-body-md ${errors.mois ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:ring-2 focus:ring-primary'}`}>
                      <option value="">Sélectionner...</option>
                      {Array.from({ length: 12 }, (_, i) => (<option key={i + 1} value={i + 1}>{new Date(0, i).toLocaleString('fr', { month: 'long' })}</option>))}
                    </select>
                    {errors.mois && <p className="mt-1 text-label-sm text-error">{errors.mois}</p>}
                  </div>
                  <div>
                    <label className="block font-label-md text-label-md text-secondary mb-2">ANNÉE</label>
                    <input type="number" value={form.annee} onChange={e => { setForm(f => ({ ...f, annee: e.target.value })); if (errors.annee) setErrors(e => ({ ...e, annee: '' })); }} className={`w-full px-4 py-3 rounded-lg border transition-all font-body-md text-body-md ${errors.annee ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:ring-2 focus:ring-primary'}`} placeholder={String(new Date().getFullYear())} min="2000" max="2100" />
                    {errors.annee && <p className="mt-1 text-label-sm text-error">{errors.annee}</p>}
                  </div>
                </div>
                <div>
                  <label className="block font-label-md text-label-md text-secondary mb-2">DESCRIPTION</label>
                  <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="w-full px-4 py-3 rounded-lg border border-border-subtle focus:ring-2 focus:ring-primary transition-all font-body-md text-body-md" placeholder="Résumé du contenu..." rows={3} maxLength={2000} />
                </div>
                {errors.form && (
                  <div className="p-3 rounded-lg bg-error/10 border border-error text-error text-body-md">
                    {errors.form}
                  </div>
                )}
                {saving && (
                  <div>
                    <div className="flex justify-between text-label-sm text-secondary mb-1">
                      <span>Téléversement...</span>
                      <span>{uploadProgress}%</span>
                    </div>
                    <div className="w-full bg-surface-container-high h-2 rounded-full overflow-hidden">
                      <div className="bg-primary h-full rounded-full transition-all duration-300" style={{ width: `${uploadProgress}%` }} />
                    </div>
                  </div>
                )}
              </form>
            </div>
            <div className="px-8 py-6 bg-surface-container-low border-t border-border-subtle flex justify-end gap-4">
              <button onClick={() => setModalOpen(false)} className="px-6 py-2 rounded-lg font-label-md text-label-md text-on-surface-variant hover:bg-surface-container-high transition-colors">Annuler</button>
              <button onClick={handleCreate} disabled={saving} className="bg-primary text-on-primary px-8 py-2 rounded-lg font-label-md text-label-md shadow-sm hover:opacity-90 transition-all disabled:opacity-50 flex items-center gap-2">
                {saving ? (
                  <><svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" /><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" /></svg>{uploadProgress}%</>
                ) : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
