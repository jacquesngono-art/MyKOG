import { api } from '../api';

export interface StorageBreakdown {
  [prefix: string]: { bytes: number; count: number };
}

export interface StorageStats {
  provider: string;
  configured: boolean;
  bucket?: string;
  region?: string;
  objectCount?: number;
  totalBytes?: number;
  totalMB?: number;
  totalGB?: number;
  quotaGB?: number;
  quotaBytes?: number;
  remainingBytes?: number;
  remainingGB?: number;
  usagePercent?: number;
  breakdown?: StorageBreakdown;
  note?: string;
  message?: string;
}

export const storageService = {
  getStats: () => api.get<StorageStats>('/storage/stats'),
};

export function formatBytes(bytes?: number): string {
  if (bytes === undefined || bytes === null) return '—';
  if (bytes >= 1073741824) return `${(bytes / 1073741824).toFixed(2)} Go`;
  if (bytes >= 1048576) return `${(bytes / 1048576).toFixed(1)} Mo`;
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(1)} Ko`;
  return `${bytes} o`;
}
