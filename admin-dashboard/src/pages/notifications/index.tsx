import { useState } from 'react';
import { notificationsService } from '../../lib/services/notifications';

export default function NotificationsPage() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});

  async function handleSend(e: React.FormEvent) {
    e.preventDefault();
    const errs: Record<string, string> = {};
    if (!title.trim()) errs.title = 'Le titre est requis';
    if (title.length > 200) errs.title = 'Le titre ne peut pas dépasser 200 caractères';
    if (!body.trim()) errs.body = 'Le message est requis';
    if (body.length > 2000) errs.body = 'Le message ne peut pas dépasser 2000 caractères';
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    setSending(true);
    setResult(null);
    try {
      const res = await notificationsService.sendToAll(title.trim(), body.trim());
      setResult(`✅ ${res.sent} notification(s) envoyée(s)${res.failed > 0 ? `, ${res.failed} échec(s)` : ''}`);
      setTitle('');
      setBody('');
      setErrors({});
    } catch (err: any) {
      setResult(`❌ Erreur: ${err.message}`);
    } finally {
      setSending(false);
    }
  }

  return (
    <>
      <div className="mb-8">
        <h2 className="font-headline-lg text-headline-lg text-on-surface mb-1">Notifications</h2>
        <p className="font-body-lg text-body-lg text-secondary">Envoyez des notifications push aux utilisateurs.</p>
      </div>

      <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-border-subtle p-6 max-w-xl">
        <form className="space-y-4" onSubmit={handleSend}>
          <div>
            <label className="block font-label-md text-label-md text-secondary mb-2">Titre</label>
            <input value={title} onChange={(e) => { setTitle(e.target.value); if (errors.title) setErrors(e => ({ ...e, title: '' })); }} className={`w-full px-4 py-3 rounded-lg border font-body-md ${errors.title ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder="Titre de la notification" maxLength={200} />
            {errors.title && <p className="mt-1 text-label-sm text-error">{errors.title}</p>}
          </div>
          <div>
            <label className="block font-label-md text-label-md text-secondary mb-2">Message</label>
            <textarea value={body} onChange={(e) => { setBody(e.target.value); if (errors.body) setErrors(e => ({ ...e, body: '' })); }} className={`w-full px-4 py-3 rounded-lg border font-body-md ${errors.body ? 'border-error ring-2 ring-error/20' : 'border-border-subtle'}`} placeholder="Corps du message..." rows={4} maxLength={2000} />
            {errors.body && <p className="mt-1 text-label-sm text-error">{errors.body}</p>}
          </div>
          {result && (
            <div className={`p-3 rounded-lg font-body-md ${result.startsWith('✅') ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
              {result}
            </div>
          )}
          <button type="submit" disabled={sending} className="bg-primary text-on-primary px-6 py-3 rounded-lg font-label-md disabled:opacity-50">
            {sending ? 'Envoi en cours...' : 'Envoyer à tous'}
          </button>
        </form>
      </div>
    </>
  );
}
