import { api } from '../api';
import type { LiveStream, ServerInfo } from '../types';

export const livesService = {
  getAll: () => api.get<LiveStream[]>('/lives'),

  getById: (id: string) => api.get<LiveStream>(`/lives/${id}`),

  getActive: () => api.get<LiveStream>('/lives/active'),

  // /lives/active renvoie 404 quand aucun live — cette variante évite le bruit console
  getActiveSafe: async (): Promise<LiveStream | null> => {
    const lives = await api.get<LiveStream[]>('/lives');
    return lives.find((l) => l.status === 'live') || null;
  },

  getServerInfo: () => api.get<ServerInfo>('/lives/server-info'),

  create: (data: Partial<LiveStream>) =>
    api.post<{ id: string; message: string; data: LiveStream }>('/lives', data),

  update: (id: string, data: Partial<LiveStream>) =>
    api.put<{ id: string; message: string; data: LiveStream }>(`/lives/${id}`, data),

  updateStatus: (id: string, status: 'scheduled' | 'live' | 'ended') =>
    api.put<{ id: string; message: string }>(`/lives/${id}/status`, { status }),

  join: (id: string) =>
    api.post<{ id: string; viewerCount: number; peakViewerCount: number }>(`/lives/${id}/join`),

  leave: (id: string) =>
    api.post<{ id: string; viewerCount: number }>(`/lives/${id}/leave`),

  getViewers: (id: string) =>
    api.get<{ id: string; viewerCount: number; peakViewerCount: number; status: string }>(`/lives/${id}/viewers`),

  delete: (id: string) => api.delete<{ id: string; message: string }>(`/lives/${id}`),

  deleteAll: () => api.delete<{ message: string; deleted: number }>('/lives/all'),


};
