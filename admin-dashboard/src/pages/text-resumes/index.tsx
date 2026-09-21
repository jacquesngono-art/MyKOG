import { useState, useEffect, useMemo } from 'react';
import {
  PlusCircleIcon,
  DocumentTextIcon,
  EyeIcon,
  StarIcon,
  ArchiveBoxIcon,
  UserIcon,
  CalendarDaysIcon,
  ArrowTopRightOnSquareIcon,
  TrashIcon,
  XMarkIcon,
  CloudArrowUpIcon,
  PhotoIcon,
  SparklesIcon,
  FunnelIcon,
} from '@heroicons/react/24/outline';
import { api } from '../../lib/api';
import { textResumesService } from '../../lib/services/textResumes';
import type { TextResume } from '../../lib/types';
import ConfirmModal from '../../components/ConfirmModal';
import Pagination from '../../components/Pagination';
import { useSearch } from '../../contexts/SearchContext';
import { usePolling } from '../../hooks/usePolling';
import { isRecent, recordVisit } from '../../lib/utils';

const ITEMS_PER_PAGE = 9;

export default function TextResumesPage() {
  const { query } = useSearch();
  const [pdfs, setPdfs] = useState<TextResume[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ title: '', speaker: '', category: '', description: '', typeCulte: '', mois: '', annee: '' });
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [deleteTarget, setDeleteTarget] = useState<TextResume | null>(null);
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
    if (!form.speaker.trim()) errs.speaker = 'L\'orateur est requis';
    if (!form.category) errs.category = 'La catégorie est requise';
    if (!form.mois) errs.mois = 'Le thème du mois est requis';
    if (!form.annee) errs.annee = 'L\'année est requise';
    if (form.annee && (!/^\d{4}$/.test(form.annee) || parseInt(form.annee) < 2000 || parseInt(form.annee) > 2100)) errs.annee = 'Année invalide (2000-2100)';
    if (!pdfFile) errs.pdfFile = 'Le fichier PDF est requis';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  useEffect(() => { loadPdfs(); }, []);
  usePolling(refreshPdfs, 30000);
  useEffect(() => { recordVisit('text-resumes'); }, []);

  async function loadPdfs() {
    try {
      const data = await textResumesService.getAll();
      setPdfs(data);
    } catch (err) {
      console.error('Erreur chargement textes résumés:', err);
    } finally {
      setLoading(false);
    }
  }

  async function refreshPdfs() {
    try {
      const data = await textResumesService.getAll();
      setPdfs(data);
    } catch {
      // silencieux – le serveur peut être temporairement indisponible
    }
  }

  const filtered = useMemo(() => {
    if (!query.trim()) return pdfs;
    const q = query.toLowerCase();
    return pdfs.filter(
      (p) =>
        p.title.toLowerCase().includes(q) ||
        p.speaker.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q) ||
        p.description?.toLowerCase().includes(q)
    );
  }, [pdfs, query]);

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
      fd.append('typeCulte', form.typeCulte);
      fd.append('description', form.description.trim());
      fd.append('mois', form.mois);
      fd.append('annee', form.annee);
      fd.append('pdf', pdfFile!);
      if (imageFile) fd.append('image', imageFile);
      await api.upload('/text-resumes', fd, setUploadProgress);
      setModalOpen(false);
      setForm({ title: '', speaker: '', category: '', description: '', mois: '', annee: '' });
      setPdfFile(null);
      setImageFile(null);
      setUploadProgress(0);
      setErrors({});
      await loadPdfs();
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
      await textResumesService.delete(deleteTarget.id);
      setDeleteTarget(null);
      await loadPdfs();
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
      const result = await textResumesService.deleteByFilter(filters);
      setBatchResult(result);
      setBatchConfirmOpen(false);
      setBatchModalOpen(false);
      setBatchFilters({ category: '', mois: '', annee: '', typeCulte: '' });
      await loadPdfs();
    } catch (err) {
      console.error('Erreur suppression groupée:', err);
    } finally {
      setBatchDeleting(false);
    }
  }

  const totalViews = pdfs.reduce((s, p) => s + (p.viewCount || 0), 0);

  return (
    <>
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="font-headline-lg text-headline-lg text-on-surface">Gestion des Ressources PDF</h1>
          <p className="font-body-md text-body-md text-secondary mt-1">Gérez et publiez vos textes résumés.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={() => { setBatchResult(null); setBatchModalOpen(true); }} className="bg-error/10 text-error px-6 py-3 rounded-lg font-label-md flex items-center gap-2 hover:bg-error/20 transition-all shadow-sm">
            <FunnelIcon className="w-5 h-5" />Suppression groupée
          </button>
          <button onClick={() => setModalOpen(true)} className="bg-primary text-on-primary px-6 py-3 rounded-lg font-label-md flex items-center gap-2 shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all">
            <PlusCircleIcon className="w-5 h-5" />Ajouter un PDF
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-gutter">
        {[
          { label: 'Total Documents', value: pdfs.length, icon: DocumentTextIcon, iconColor: 'bg-primary/10 text-primary' },
          { label: 'Total Vues', value: totalViews.toLocaleString(), icon: EyeIcon, iconColor: 'bg-secondary/10 text-secondary' },
          { label: 'Top Catégorie', value: 'Sagesse', icon: StarIcon, iconColor: 'bg-tertiary-container/10 text-tertiary' },
          { label: 'Stockage', value: `${(pdfs.reduce((s, p) => s + (p.fileSize || 0), 0) / 1024 / 1024).toFixed(1)} MB`, icon: ArchiveBoxIcon, iconColor: 'bg-error-container/10 text-error' },
        ].map((s) => {
          const StatIcon = s.icon;
          return (
            <div key={s.label} className="bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle hover:border-primary/30 transition-colors">
              <div className="flex justify-between items-start mb-4"><div className={`p-2 ${s.iconColor} rounded-lg`}><StatIcon className="w-5 h-5" /></div></div>
              <p className="text-secondary font-label-md text-label-md uppercase tracking-wider">{s.label}</p>
              <h3 className="font-headline-md text-headline-md mt-1">{String(s.value)}</h3>
            </div>
          );
        })}
      </div>

      {loading ? (
        <div className="text-center text-secondary py-8">Chargement...</div>
      ) : filtered.length === 0 ? (
        <div className="text-center text-secondary py-8">
          {query ? `Aucun PDF trouvé pour "${query}"` : 'Aucun PDF trouvé'}
        </div>
      ) : (
        <>
          <div className="flex items-center gap-2 mb-2">
            <span className="font-label-md text-label-md text-secondary">{filtered.length} document(s)</span>
            {query && (
              <span className="font-label-sm text-label-sm text-secondary italic">
                Filtré par &quot;{query}&quot;
              </span>
            )}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-gutter">
            {paginated.map((doc) => (
              <div key={doc.id} className="group bg-surface-container-lowest rounded-2xl border border-border-subtle overflow-hidden hover:shadow-xl transition-all duration-300">
                <div className="relative aspect-video bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center">
                  {doc.coverImageUrl ? (
                    <img src={doc.coverImageUrl} alt="" className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                  ) : (
                    <DocumentTextIcon className="w-16 h-16 text-gray-400" />
                  )}
                  <div className="absolute top-3 left-3 flex gap-1">
                    {isRecent(doc.createdAt) && (
                      <span className="flex items-center gap-1 px-2 py-1 rounded-full text-label-sm font-bold bg-error/90 text-white backdrop-blur-sm">
                        <SparklesIcon className="w-3 h-3" />Nouveau
                      </span>
                    )}
                    <span className="bg-primary/90 text-on-primary-container px-3 py-1 rounded-full text-label-sm font-bold backdrop-blur-sm">{doc.category}</span>
                  </div>
                </div>
                <div className="p-card-padding">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-headline-sm text-headline-sm text-on-surface line-clamp-1">{doc.title}</h4>
                    <div className="flex items-center gap-1 text-tertiary"><StarIcon className="w-4 h-4" /><span className="text-label-md">{doc.rating?.toFixed(1) || '0'}</span></div>
                  </div>
                  <p className="text-secondary font-body-md mb-4 flex items-center gap-2"><UserIcon className="w-[18px] h-[18px]" />{doc.speaker}</p>
                  <div className="flex items-center justify-between pt-4 border-t border-border-subtle">
                    <div className="flex gap-4 text-secondary text-label-sm">
                      <span className="flex items-center gap-1"><EyeIcon className="w-4 h-4" /> {doc.viewCount}</span>
                      <span className="flex items-center gap-1"><CalendarDaysIcon className="w-4 h-4" /> {new Date(doc.createdAt).toLocaleDateString('fr-FR')}</span>
                    </div>
                    <div className="flex gap-2">
                      {doc.pdfUrl && (
                        <a href={doc.pdfUrl} target="_blank" rel="noopener noreferrer" className="p-2 text-secondary hover:text-primary hover:bg-primary/5 rounded-lg transition-colors"><ArrowTopRightOnSquareIcon className="w-5 h-5" /></a>
                      )}
                      <button onClick={() => setDeleteTarget(doc)} className="p-2 text-secondary hover:text-error hover:bg-error/5 rounded-lg transition-colors"><TrashIcon className="w-5 h-5" /></button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
          <Pagination currentPage={page} totalPages={totalPages} onPageChange={setPage} />
        </>
      )}

      <ConfirmModal
        open={!!deleteTarget}
        title="Supprimer le PDF"
        message={`Êtes-vous sûr de vouloir supprimer "${deleteTarget?.title}" ? Cette action est irréversible.`}
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />

      <ConfirmModal
        open={batchConfirmOpen}
        title="Confirmer la suppression groupée"
        message={`Êtes-vous sûr de vouloir supprimer tous les textes résumés correspondant aux filtres sélectionnés ? Cette action est irréversible.`}
        loading={batchDeleting}
        onConfirm={handleBatchDelete}
        onCancel={() => setBatchConfirmOpen(false)}
      />

      {batchModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[100] flex items-center justify-center p-4" onClick={() => { setBatchModalOpen(false); setBatchResult(null); }}>
          <div className="bg-surface-container-lowest w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden" onClick={(e) => e.stopPropagation()}>
            <div className="p-6 border-b border-border-subtle flex justify-between items-center">
              <h3 className="font-headline-sm text-headline-sm text-on-surface">Suppression groupée</h3>
              <button onClick={() => { setBatchModalOpen(false); setBatchResult(null); }} className="p-2 hover:bg-surface-container-low rounded-full transition-colors"><XMarkIcon className="w-5 h-5" /></button>
            </div>
            <div className="p-6 space-y-5">
              {batchResult ? (
                <div className={`p-4 rounded-lg ${batchResult.deleted > 0 ? 'bg-status-success/10 text-status-success' : 'text-secondary bg-surface-container-low'}`}>
                  <p className="font-body-md text-body-md">{batchResult.message}</p>
                </div>
              ) : (
                <>
                  <p className="font-body-md text-body-md text-secondary">Sélectionnez au moins un filtre pour supprimer les textes résumés correspondants.</p>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <label className="font-label-md text-label-md text-secondary">CATÉGORIE</label>
                      <select value={batchFilters.category} onChange={e => setBatchFilters(f => ({ ...f, category: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2">
                        <option value="">Toutes</option>
                        <option>Foi & Miracles</option><option>Sagesse</option><option>Mariage</option><option>Leadership</option><option>Jeunesse</option>
                      </select>
                    </div>
                    <div className="space-y-2">
                      <label className="font-label-md text-label-md text-secondary">TYPE DE CULTE</label>
                      <select value={batchFilters.typeCulte} onChange={e => setBatchFilters(f => ({ ...f, typeCulte: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2">
                        <option value="">Tous</option>
                        <option value="Culte d'Impact">Culte d'Impact</option>
                        <option value="Culte Prophétique">Culte Prophétique</option>
                        <option value="Culte d'Enseignement">Culte d'Enseignement</option>
                        <option value="Conférence">Conférence</option>
                        <option value="Séminaire">Séminaire</option>
                      </select>
                    </div>
                    <div className="space-y-2">
                      <label className="font-label-md text-label-md text-secondary">THÈME DU MOIS / SAISON</label>
                      <input value={batchFilters.mois} onChange={e => setBatchFilters(f => ({ ...f, mois: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2" placeholder="Ex: Mois de la Restauration" />
                    </div>
                    <div className="space-y-2">
                      <label className="font-label-md text-label-md text-secondary">ANNÉE</label>
                      <input type="number" value={batchFilters.annee} onChange={e => setBatchFilters(f => ({ ...f, annee: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2" placeholder="Ex: 2024" min="2000" max="2100" />
                    </div>
                  </div>
                </>
              )}
            </div>
            <div className="p-6 bg-surface-container-low border-t border-border-subtle flex justify-end gap-4">
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
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm" onClick={() => { setModalOpen(false); setErrors({}); }}>
          <div className="bg-surface-container-lowest w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden" onClick={(e) => e.stopPropagation()}>
            <div className="p-6 border-b border-border-subtle flex justify-between items-center bg-surface-bright">
              <h3 className="font-headline-sm text-headline-sm">Nouvelle Ressource PDF</h3>
              <button onClick={() => setModalOpen(false)} className="p-2 hover:bg-surface-container-low rounded-full transition-colors"><XMarkIcon className="w-5 h-5" /></button>
            </div>
            <form className="p-6 space-y-6 overflow-y-auto max-h-[819px]" onSubmit={handleCreate}>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Titre</label>
                  <input value={form.title} onChange={e => { setForm(f => ({ ...f, title: e.target.value })); if (errors.title) setErrors(e => ({ ...e, title: '' })); }} className={`w-full bg-white border rounded-lg px-4 py-2 ${errors.title ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder="Titre..." maxLength={200} />
                  {errors.title && <p className="text-label-sm text-error">{errors.title}</p>}
                </div>
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Orateur</label>
                  <input value={form.speaker} onChange={e => { setForm(f => ({ ...f, speaker: e.target.value })); if (errors.speaker) setErrors(e => ({ ...e, speaker: '' })); }} className={`w-full bg-white border rounded-lg px-4 py-2 ${errors.speaker ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder="Nom de l'orateur..." maxLength={200} />
                  {errors.speaker && <p className="text-label-sm text-error">{errors.speaker}</p>}
                </div>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Catégorie</label>
                  <select value={form.category} onChange={e => { setForm(f => ({ ...f, category: e.target.value })); if (errors.category) setErrors(e => ({ ...e, category: '' })); }} className={`w-full bg-white border rounded-lg px-4 py-2 ${errors.category ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`}>
                    <option value="">Sélectionner...</option>
                    <option>Foi & Miracles</option><option>Sagesse</option><option>Mariage</option><option>Leadership</option><option>Jeunesse</option>
                  </select>
                  {errors.category && <p className="text-label-sm text-error">{errors.category}</p>}
                </div>
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Type de Culte</label>
                  <select value={form.typeCulte} onChange={e => setForm(f => ({ ...f, typeCulte: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2">
                    <option value="">Sélectionner...</option>
                    <option value="Culte d'Impact">Culte d'Impact</option>
                    <option value="Culte Prophétique">Culte Prophétique</option>
                    <option value="Culte d'Enseignement">Culte d'Enseignement</option>
                    <option value="Conférence">Conférence</option>
                    <option value="Séminaire">Séminaire</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Thème du mois / Saison</label>
                  <input value={form.mois} onChange={e => setForm(f => ({ ...f, mois: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2" placeholder="Ex: Mois de la Restauration" />
                </div>
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Année</label>
                  <input type="number" value={form.annee} onChange={e => { setForm(f => ({ ...f, annee: e.target.value })); if (errors.annee) setErrors(e => ({ ...e, annee: '' })); }} className={`w-full bg-white border rounded-lg px-4 py-2 ${errors.annee ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder={String(new Date().getFullYear())} min="2000" max="2100" />
                  {errors.annee && <p className="text-label-sm text-error">{errors.annee}</p>}
                </div>
              </div>
              <div className="space-y-2">
                <label className="font-label-md text-label-md text-secondary">Description</label>
                <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="w-full bg-white border border-border-subtle rounded-lg px-4 py-2" placeholder="Description..." rows={3} maxLength={2000} />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Fichier PDF</label>
                  <div className={`border-2 border-dashed rounded-xl p-6 flex flex-col items-center justify-center transition-colors cursor-pointer ${errors.pdfFile ? 'border-error bg-error/5' : 'border-border-subtle bg-surface-container-low/50 hover:bg-surface-container-low'}`} onClick={() => document.getElementById('pdf-upload')?.click()}>
                    {pdfFile ? (
                      <div className="text-center">
                        <DocumentTextIcon className="w-10 h-10 text-primary mb-2 mx-auto" />
                        <p className="text-body-md text-secondary">{pdfFile.name}</p>
                      </div>
                    ) : (
                      <><CloudArrowUpIcon className="w-10 h-10 text-primary mb-2" /><p className="text-body-md text-secondary">Cliquez pour téléverser</p></>
                    )}
                    <input type="file" accept=".pdf" onChange={e => { setPdfFile(e.target.files?.[0] || null); if (errors.pdfFile) setErrors(e => ({ ...e, pdfFile: '' })); }} className="hidden" id="pdf-upload" />
                  </div>
                  {errors.pdfFile && <p className="text-label-sm text-error">{errors.pdfFile}</p>}
                </div>
                <div className="space-y-2">
                  <label className="font-label-md text-label-md text-secondary">Image de Couverture</label>
                  <div className="border-2 border-dashed border-border-subtle rounded-xl p-6 flex flex-col items-center justify-center bg-surface-container-low/50 hover:bg-surface-container-low transition-colors cursor-pointer" onClick={() => document.getElementById('cover-upload')?.click()}>
                    {imageFile ? (
                      <div className="text-center w-full">
                        <img src={URL.createObjectURL(imageFile)} alt="Preview" className="max-h-32 mx-auto rounded-lg object-contain" />
                        <p className="text-body-md text-secondary mt-2">{imageFile.name}</p>
                      </div>
                    ) : (
                      <><PhotoIcon className="w-10 h-10 text-primary mb-2" /><p className="text-body-md text-secondary">Téléverser une image</p></>
                    )}
                    <input type="file" accept="image/*" onChange={e => setImageFile(e.target.files?.[0] || null)} className="hidden" id="cover-upload" />
                  </div>
                </div>
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
              <div className="pt-6 flex justify-end gap-4">
                <button onClick={() => setModalOpen(false)} className="px-6 py-2 text-secondary font-label-md hover:bg-surface-container-low rounded-lg transition-colors" type="button">Annuler</button>
                <button type="submit" disabled={saving} className="bg-primary text-on-primary px-8 py-2 rounded-lg font-label-md shadow-md hover:shadow-lg transition-all disabled:opacity-50 flex items-center gap-2">
                  {saving ? (
                    <><svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" /><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" /></svg>{uploadProgress}%</>
                  ) : 'Publier'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
