import { useState, useEffect, useMemo } from 'react';
import {
  PlusIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ClockIcon,
  MapPinIcon,
  XMarkIcon,
  MagnifyingGlassIcon,
} from '@heroicons/react/24/outline';
import { calendarService } from '../../lib/services/calendar';
import type { CalendarEvent } from '../../lib/types';
import Pagination from '../../components/Pagination';
import { useSearch } from '../../contexts/SearchContext';

const ITEMS_PER_PAGE = 8;

export default function CalendarPage() {
  const { query } = useSearch();
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [currentMonth, setCurrentMonth] = useState(new Date().getMonth());
  const [currentYear, setCurrentYear] = useState(new Date().getFullYear());
  const [form, setForm] = useState({ title: '', description: '', startDate: '', endDate: '', location: '', category: '' });
  const [saving, setSaving] = useState(false);
  const [page, setPage] = useState(1);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    loadEvents();
  }, []);

  async function loadEvents() {
    try {
      const data = await calendarService.getAll();
      setEvents(data);
    } catch (err) {
      console.error('Erreur chargement calendrier:', err);
    } finally {
      setLoading(false);
    }
  }

  const filtered = useMemo(() => {
    if (!query.trim()) return events;
    const q = query.toLowerCase();
    return events.filter(
      (e) =>
        e.title.toLowerCase().includes(q) ||
        (e.description || '').toLowerCase().includes(q) ||
        (e.location || '').toLowerCase().includes(q) ||
        (e.category || '').toLowerCase().includes(q)
    );
  }, [events, query]);

  useEffect(() => { setPage(1); }, [query]);

  const monthEvents = filtered.filter(e => {
    const d = new Date(e.startDate);
    return d.getMonth() === currentMonth && d.getFullYear() === currentYear;
  });

  const upcoming = useMemo(
    () =>
      [...filtered]
        .filter(e => new Date(e.startDate) > new Date())
        .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime()),
    [filtered]
  );

  const upcomingPages = Math.max(1, Math.ceil(upcoming.length / ITEMS_PER_PAGE));
  const paginatedUpcoming = upcoming.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE);

  const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
  const firstDayOfWeek = new Date(currentYear, currentMonth, 1).getDay();
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);

  function prevMonth() {
    if (currentMonth === 0) { setCurrentMonth(11); setCurrentYear(y => y - 1); }
    else setCurrentMonth(m => m - 1);
  }
  function nextMonth() {
    if (currentMonth === 11) { setCurrentMonth(0); setCurrentYear(y => y + 1); }
    else setCurrentMonth(m => m + 1);
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!form.title.trim()) errs.title = 'Le titre est requis';
    if (form.title.length > 200) errs.title = 'Le titre ne peut pas dépasser 200 caractères';
    if (!form.startDate) errs.startDate = 'La date de début est requise';
    if (form.startDate && form.endDate && new Date(form.endDate) <= new Date(form.startDate)) {
      errs.endDate = 'La date de fin doit être postérieure à la date de début';
    }
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    setSaving(true);
    setErrors({});
    try {
      await calendarService.create({
        title: form.title.trim(),
        description: form.description.trim(),
        startDate: form.startDate,
        endDate: form.endDate || undefined,
        location: form.location,
        category: form.category,
      });
      setModalOpen(false);
      setForm({ title: '', description: '', startDate: '', endDate: '', location: '', category: '' });
      await loadEvents();
    } catch (err: any) {
      const msg = err?.response?.data?.error || err?.message || 'Erreur lors de la création';
      setErrors({ form: msg });
    } finally {
      setSaving(false);
    }
  }

  const monthName = new Date(currentYear, currentMonth).toLocaleString('fr', { month: 'long' });

  return (
    <>
      <div className="flex justify-between items-end">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-surface">Calendrier</h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">Gestion des services, événements et réunions.</p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => setModalOpen(true)} className="bg-primary hover:bg-primary/80 text-white px-6 py-2.5 rounded-lg font-label-md text-label-md flex items-center gap-2 transition-all shadow-md active:scale-95">
            <PlusIcon className="w-5 h-5" /> Créer un Événement
          </button>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-gutter">
        <div className="col-span-12 lg:col-span-8 bg-white rounded-xl shadow-sm border border-border-subtle overflow-hidden flex flex-col h-[700px]">
          <div className="p-6 border-b border-border-subtle flex justify-between items-center">
            <div className="flex items-center gap-4">
              <h3 className="font-headline-sm text-headline-sm capitalize">{monthName} {currentYear}</h3>
              <div className="flex bg-surface-container-low rounded-lg p-1">
                <button onClick={prevMonth} className="p-1 hover:bg-white rounded transition-all"><ChevronLeftIcon className="w-5 h-5" /></button>
                <button onClick={nextMonth} className="p-1 hover:bg-white rounded transition-all"><ChevronRightIcon className="w-5 h-5" /></button>
              </div>
            </div>
            <div className="flex items-center gap-3">
              {query && (
                <span className="font-label-sm text-label-sm text-secondary italic">
                  Filtré
                </span>
              )}
              <span className="font-label-sm text-label-sm text-secondary">{filtered.length} événement(s)</span>
            </div>
          </div>

          <div className="flex-1 overflow-auto custom-scrollbar">
            <div className="calendar-grid border-b border-border-subtle bg-surface-container-low">
              {['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'].map((d) => (
                <div key={d} className="p-3 text-center font-label-md text-label-md text-secondary uppercase tracking-wider">{d}</div>
              ))}
            </div>
            <div className="calendar-grid bg-white min-h-[600px]">
              {Array.from({ length: firstDayOfWeek }).map((_, i) => (
                <div key={`empty-${i}`} className="border-r border-b border-border-subtle p-2 min-h-[120px] bg-surface-container-lowest/50" />
              ))}
              {days.map((day) => {
                const dayEvents = monthEvents.filter(e => new Date(e.startDate).getDate() === day);
                const isToday = day === new Date().getDate() && currentMonth === new Date().getMonth() && currentYear === new Date().getFullYear();
                return (
                  <div key={day} className={`border-r border-b border-border-subtle p-2 min-h-[120px] hover:bg-surface-container-low transition-colors ${isToday ? 'bg-primary-fixed/20' : ''}`}>
                    <span className={`font-label-md text-label-md ${isToday ? 'font-bold text-primary' : ''} text-on-surface`}>{day}</span>
                    <div className="mt-2 space-y-1">
                      {dayEvents.map((e) => (
                        <div key={e.id} className="bg-primary/20 text-primary border-l-2 border-primary px-2 py-1 rounded text-[10px] font-bold truncate">{e.title}</div>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        <div className="col-span-12 lg:col-span-4 space-y-gutter">
          <div className="bg-white rounded-xl shadow-sm border border-border-subtle p-6">
            <h4 className="font-headline-sm text-headline-sm mb-6 flex items-center justify-between">
              À venir
              <span className="bg-surface-container-high text-secondary text-xs px-2 py-1 rounded-full">{upcoming.length}</span>
            </h4>
            {loading ? (
              <div className="text-center text-secondary py-4">Chargement...</div>
            ) : paginatedUpcoming.length === 0 ? (
              <div className="text-center text-secondary py-4">
                {query ? 'Aucun résultat' : 'Aucun événement à venir'}
              </div>
            ) : (
              <>
                <div className="space-y-4">
                  {paginatedUpcoming.map((ev) => {
                    const d = new Date(ev.startDate);
                    return (
                      <div key={ev.id} className="flex gap-4 p-3 rounded-lg hover:bg-surface-container-low transition-all cursor-pointer border border-transparent hover:border-border-subtle">
                        <div className="bg-primary-fixed text-primary w-12 h-12 rounded-lg flex flex-col items-center justify-center shrink-0">
                          <span className="text-[10px] font-bold uppercase leading-none">{d.toLocaleString('fr', { month: 'short' })}</span>
                          <span className="text-xl font-bold">{d.getDate()}</span>
                        </div>
                        <div className="flex-1 overflow-hidden">
                          <h5 className="font-label-md text-label-md text-on-surface truncate">{ev.title}</h5>
                          <p className="font-body-md text-body-md text-secondary flex items-center gap-1">
                            <ClockIcon className="w-3.5 h-3.5" /> {d.toLocaleTimeString('fr', { hour: '2-digit', minute: '2-digit' })}
                          </p>
                          {ev.location && (
                            <div className="mt-1 flex gap-2">
                              <span className="text-[10px] text-secondary"><MapPinIcon className="w-3 h-3 inline" /> {ev.location}</span>
                            </div>
                          )}
                          {ev.category && (
                            <span className="inline-block mt-1 bg-primary-fixed/50 text-primary px-2 py-0.5 rounded-full text-[10px] font-bold">
                              {ev.category}
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
                <Pagination currentPage={page} totalPages={upcomingPages} onPageChange={setPage} />
              </>
            )}
          </div>
        </div>
      </div>

      {modalOpen && (
        <div className="fixed inset-0 z-[60] bg-on-background/40 backdrop-blur-sm flex items-center justify-center" onClick={() => { setModalOpen(false); setErrors({}); }}>
          <div className="w-full max-w-xl bg-white rounded-xl shadow-2xl overflow-hidden" onClick={(e) => e.stopPropagation()}>
            <div className="p-6 border-b border-border-subtle flex justify-between items-center bg-surface-bright">
              <div>
                <h3 className="font-headline-sm text-headline-sm text-on-surface">Créer un Événement</h3>
                <p className="font-body-md text-body-md text-secondary">Remplissez les détails du nouvel événement.</p>
              </div>
              <button onClick={() => setModalOpen(false)} className="text-secondary hover:text-on-surface transition-colors"><XMarkIcon className="w-5 h-5" /></button>
            </div>
            <form className="p-6 space-y-5" onSubmit={handleCreate}>
              <div className="space-y-1">
                <label className="font-label-md text-label-md text-secondary">Titre</label>
                <input value={form.title} onChange={e => { setForm(f => ({ ...f, title: e.target.value })); if (errors.title) setErrors(e => ({ ...e, title: '' })); }} className={`w-full rounded-lg border py-2.5 font-body-md text-body-md ${errors.title ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:border-primary focus:ring-2 focus:ring-primary/20'}`} placeholder="Titre de l'événement" maxLength={200} />
                {errors.title && <p className="text-label-sm text-error">{errors.title}</p>}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="font-label-md text-label-md text-secondary">Début</label>
                  <input value={form.startDate} onChange={e => { setForm(f => ({ ...f, startDate: e.target.value })); if (errors.startDate) setErrors(e => ({ ...e, startDate: '' })); }} className={`w-full rounded-lg border py-2.5 font-body-md text-body-md ${errors.startDate ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:border-primary focus:ring-2 focus:ring-primary/20'}`} type="datetime-local" />
                  {errors.startDate && <p className="text-label-sm text-error">{errors.startDate}</p>}
                </div>
                <div className="space-y-1">
                  <label className="font-label-md text-label-md text-secondary">Fin</label>
                  <input value={form.endDate} onChange={e => { setForm(f => ({ ...f, endDate: e.target.value })); if (errors.endDate) setErrors(e => ({ ...e, endDate: '' })); }} className={`w-full rounded-lg border py-2.5 font-body-md text-body-md ${errors.endDate ? 'border-error ring-2 ring-error/20' : 'border-border-subtle focus:border-primary focus:ring-2 focus:ring-primary/20'}`} type="datetime-local" />
                  {errors.endDate && <p className="text-label-sm text-error">{errors.endDate}</p>}
                </div>
              </div>
              <div className="space-y-1">
                <label className="font-label-md text-label-md text-secondary">Lieu</label>
                <div className="relative">
                  <MapPinIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-outline" />
                  <input value={form.location} onChange={e => setForm(f => ({ ...f, location: e.target.value }))} className="w-full rounded-lg border-border-subtle pl-10 focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all font-body-md text-body-md py-2.5" placeholder="Lieu ou lien" />
                </div>
              </div>
              <div className="space-y-1">
                <label className="font-label-md text-label-md text-secondary">Catégorie</label>
                <select value={form.category} onChange={e => setForm(f => ({ ...f, category: e.target.value }))} className="w-full rounded-lg border-border-subtle focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all font-body-md text-body-md py-2.5">
                  <option value="">Sélectionner...</option>
                  <option>Service</option>
                  <option>Réunion</option>
                  <option>Jeunesse</option>
                  <option>Événement spécial</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="font-label-md text-label-md text-secondary">Description</label>
                <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="w-full rounded-lg border-border-subtle focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all font-body-md text-body-md" placeholder="Description..." rows={3} maxLength={2000} />
              </div>
              {errors.form && (
                <div className="p-3 rounded-lg bg-error/10 border border-error text-error text-body-md">{errors.form}</div>
              )}
              <div className="pt-4 flex gap-3">
                <button onClick={() => setModalOpen(false)} className="flex-1 py-2.5 rounded-lg border border-border-subtle font-label-md text-label-md text-secondary hover:bg-surface-container-low transition-colors" type="button">Annuler</button>
                <button type="submit" disabled={saving} className="flex-1 py-2.5 rounded-lg bg-primary text-white font-label-md text-label-md shadow-md hover:bg-primary/80 transition-all active:scale-95 disabled:opacity-50">
                  {saving ? 'Création...' : 'Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
