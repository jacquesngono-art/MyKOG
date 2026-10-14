const NEW_ITEM_DAYS = 3;
const STORAGE_PREFIX = 'mykog_last_visit_';

export function isRecent(dateStr: string, days: number = NEW_ITEM_DAYS): boolean {
  const created = new Date(dateStr).getTime();
  const now = Date.now();
  const diff = now - created;
  return diff >= 0 && diff < days * 24 * 60 * 60 * 1000;
}

export function recordVisit(page: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORAGE_PREFIX + page, String(Date.now()));
}

export function getLastVisit(page: string): number {
  if (typeof window === 'undefined') return 0;
  const val = localStorage.getItem(STORAGE_PREFIX + page);
  return val ? parseInt(val, 10) : 0;
}

export function isNewSinceLastVisit(dateStr: string, page: string): boolean {
  const created = new Date(dateStr).getTime();
  const lastVisit = getLastVisit(page);
  return lastVisit === 0 || created > lastVisit;
}
