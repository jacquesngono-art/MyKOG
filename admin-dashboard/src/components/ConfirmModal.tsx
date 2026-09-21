import { XMarkIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline';

interface ConfirmModalProps {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmModal({
  open,
  title,
  message,
  confirmLabel = 'Supprimer',
  cancelLabel = 'Annuler',
  loading = false,
  onConfirm,
  onCancel,
}: ConfirmModalProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[200] flex items-center justify-center p-4" onClick={onCancel}>
      <div className="bg-surface-container-lowest w-full max-w-md rounded-2xl shadow-2xl overflow-hidden" onClick={(e) => e.stopPropagation()}>
        <div className="px-6 py-5 border-b border-border-subtle flex justify-between items-center">
          <h3 className="font-headline-sm text-headline-sm text-on-surface">{title}</h3>
          <button onClick={onCancel} className="p-1 hover:bg-surface-container-low rounded-full transition-colors">
            <XMarkIcon className="w-5 h-5 text-secondary" />
          </button>
        </div>
        <div className="px-6 py-5">
          <div className="flex items-start gap-4">
            <div className="p-2 bg-error-container text-error rounded-full shrink-0">
              <ExclamationTriangleIcon className="w-6 h-6" />
            </div>
            <p className="font-body-md text-body-md text-secondary mt-1">{message}</p>
          </div>
        </div>
        <div className="px-6 py-4 bg-surface-container-low border-t border-border-subtle flex justify-end gap-3">
          <button
            onClick={onCancel}
            disabled={loading}
            className="px-5 py-2 rounded-lg font-label-md text-label-md text-secondary hover:bg-surface-container-high transition-colors disabled:opacity-50"
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className="px-5 py-2 rounded-lg font-label-md text-label-md bg-error text-white hover:bg-opacity-90 transition-all disabled:opacity-50 flex items-center gap-2"
          >
            {loading && (
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
            )}
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
