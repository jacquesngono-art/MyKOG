import { useState, useEffect, useMemo } from 'react';
import { PlusIcon, TrashIcon, XMarkIcon, CalendarDaysIcon, MegaphoneIcon, SparklesIcon } from '@heroicons/react/24/outline';
import { annoncesService } from '../../lib/services/annonces';
import type { Annonce } from '../../lib/types';
import ConfirmModal from '../../components/ConfirmModal';
import Pagination from '../../components/Pagination';
import { useSearch } from '../../contexts/SearchContext';
import { usePolling } from '../../hooks/usePolling';
import { isRecent, recordVisit } from '../../lib/utils';

const ITEMS_PER_PAGE = 8;

export default function AnnoncesPage() {
  const { query } = useSearch();
  const [annonces, setAnnonces] = useState<Annonce[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [nom, setNom] = useState('');
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<Annonce | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [page, setPage] = useState(1);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => { loadAnnonces(); }, []);
  usePolling(refreshAnnonces, 30000);
  useEffect(() => { recordVisit('annonces'); }, []);

  async function loadAnnonces() {
    try {
      const data = await annoncesService.getAll();
      setAnnonces(data);
    } catch (err) {
      console.error('Erreur chargement annonces:', err);
    } finally {
      setLoading(false);
    }
  }

  async function refreshAnnonces() {
    try {
      const data = await annoncesService.getAll();
      setAnnonces(data);
    } catch {
      // silencieux – le serveur peut être temporairement indisponible
    }
  }

  const filtered = useMemo(() => {
    if (!query.trim()) return annonces;
    const q = query.toLowerCase();
    return annonces.filter(
      (a) =>
        a.nom.toLowerCase().includes(q) ||
        a.description.toLowerCase().includes(q)
    );
  }, [annonces, query]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginated = filtered.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE);

  useEffect(() => { setPage(1); }, [query]);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!nom.trim()) errs.nom = 'Le titre est requis';
    if (nom.length > 200) errs.nom = 'Le titre ne peut pas dépasser 200 caractères';
    if (!description.trim()) errs.description = 'La description est requise';
    if (description.length > 5000) errs.description = 'La description ne peut pas dépasser 5000 caractères';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    setSaving(true);
    setErrors({});
    try {
      await annoncesService.create({ nom: nom.trim(), description: description.trim() });
      setModal(false);
      setNom('');
      setDescription('');
      await loadAnnonces();
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
      await annoncesService.delete(deleteTarget.id);
      setDeleteTarget(null);
      await loadAnnonces();
    } catch (err) {
      console.error('Erreur suppression annonce:', err);
    } finally {
      setDeleting(false);
    }
  }

  return (
    <>
      <div className="flex justify-between items-end mb-8">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-surface mb-1">Annonces</h2>
          <p className="font-body-lg text-body-lg text-secondary">Gérez les annonces de la congrégation.</p>
        </div>
        <button onClick={() => setModal(true)} className="bg-primary text-on-primary px-6 py-3 rounded-lg font-label-md text-label-md flex items-center gap-2">
          <PlusIcon className="w-5 h-5" /> Nouvelle Annonce
        </button>
      </div>

      {loading ? (
        <div className="text-center text-secondary py-8">Chargement...</div>
      ) : filtered.length === 0 ? (
        <div className="text-center text-secondary py-8">
          {query ? `Aucune annonce pour "${query}"` : 'Aucune annonce'}
        </div>
      ) : (
        <>
          <div className="flex items-center gap-2 mb-4">
            <span className="font-label-md text-label-md text-secondary">{filtered.length} annonce(s)</span>
            {query && (
              <span className="font-label-sm text-label-sm text-secondary italic">
                Filtré par &quot;{query}&quot;
              </span>
            )}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-gutter">
            {paginated.map((a) => (
              <div key={a.id} className="group bg-surface-container-lowest p-card-padding rounded-xl shadow-sm border border-border-subtle hover:shadow-md hover:border-primary/20 transition-all">
                  <div className="flex items-start justify-between gap-3 mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-tertiary-fixed text-tertiary flex items-center justify-center shrink-0">
                      <MegaphoneIcon className="w-5 h-5" />
                    </div>
                    <h3 className="font-headline-sm text-headline-sm text-on-surface">{a.nom}</h3>
                    {isRecent(a.dateCreation) && (
                      <span className="flex items-center gap-1 px-2 py-0.5 rounded-full font-label-sm text-label-sm bg-error/90 text-white">
                        <SparklesIcon className="w-3 h-3" />Nouveau
                      </span>
                    )}
                  </div>
                  <button onClick={() => setDeleteTarget(a)} className="p-1.5 hover:bg-error-container text-error rounded-lg transition-colors opacity-0 group-hover:opacity-100 shrink-0">
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </div>
                <p className="font-body-md text-body-md text-secondary line-clamp-3 mb-4">{a.description}</p>
                <div className="flex items-center justify-between pt-3 border-t border-border-subtle">
                  <span className="font-label-sm text-label-sm text-secondary flex items-center gap-1">
                    <CalendarDaysIcon className="w-3.5 h-3.5" />
                    {new Date(a.dateCreation).toLocaleDateString('fr-FR')}
                  </span>
                  <button onClick={() => setDeleteTarget(a)} className="p-1.5 hover:bg-error-container text-error rounded-lg transition-colors md:hidden">
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
          <Pagination currentPage={page} totalPages={totalPages} onPageChange={setPage} />
        </>
      )}

      <ConfirmModal
        open={!!deleteTarget}
        title="Supprimer l'annonce"
        message={`Êtes-vous sûr de vouloir supprimer "${deleteTarget?.nom}" ? Cette action est irréversible.`}
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />

      {modal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[100] flex items-center justify-center p-4" onClick={() => setModal(false)}>
          <div className="bg-surface-container-lowest w-full max-w-lg rounded-2xl shadow-2xl p-6" onClick={(e) => e.stopPropagation()}>
            <h3 className="font-headline-sm text-headline-sm mb-6">Nouvelle Annonce</h3>
            <form className="space-y-4" onSubmit={handleCreate}>
              <div>
                <input value={nom} onChange={e => { setNom(e.target.value); if (errors.nom) setErrors(e => ({ ...e, nom: '' })); }} className={`w-full px-4 py-3 rounded-lg border font-body-md ${errors.nom ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder="Titre de l'annonce" maxLength={200} />
                {errors.nom && <p className="mt-1 text-label-sm text-error">{errors.nom}</p>}
              </div>
              <div>
                <textarea value={description} onChange={e => { setDescription(e.target.value); if (errors.description) setErrors(e => ({ ...e, description: '' })); }} className={`w-full px-4 py-3 rounded-lg border font-body-md ${errors.description ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder="Description..." rows={4} maxLength={5000} />
                {errors.description && <p className="mt-1 text-label-sm text-error">{errors.description}</p>}
              </div>
              {errors.form && (
                <div className="p-3 rounded-lg bg-error/10 border border-error text-error text-body-md">{errors.form}</div>
              )}
              <div className="flex justify-end gap-4 pt-4">
                <button onClick={() => setModal(false)} className="px-6 py-2 text-secondary font-label-md hover:bg-surface-container-low rounded-lg" type="button">Annuler</button>
                <button type="submit" disabled={saving} className="bg-primary text-on-primary px-6 py-2 rounded-lg font-label-md disabled:opacity-50 flex items-center gap-2">
                  {saving && <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" /><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" /></svg>}
                  {saving ? 'Publication...' : 'Publier'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
