import { api } from '../api';
import type { Enseignement } from '../types';

export const enseignementsService = {
  getAll: () => api.get<Enseignement[]>('/enseignements'),

  getById: (id: string) => api.get<Enseignement>(`/enseignements/${id}`),

  create: (formData: FormData) =>
    api.post<{ id: string; message: string; data: Enseignement }>('/enseignements', formData, true),

  update: (id: string, data: Record<string, any>) =>
    api.put<{ id: string; message: string; data: Enseignement }>(`/enseignements/${id}`, data),

  updateWithImage: (id: string, formData: FormData) =>
    api.put<{ id: string; message: string; data: Enseignement }>(`/enseignements/${id}`, formData, true),

  delete: (id: string) => api.delete<{ id: string; message: string }>(`/enseignements/${id}`),

  deleteAll: () => api.delete<{ message: string; deleted: number }>('/enseignements/all'),

  deleteByFilter: (params: { category?: string; mois?: string; annee?: string; typeCulte?: string }) => {
    const searchParams = new URLSearchParams();
    if (params.category) searchParams.set('category', params.category);
    if (params.mois) searchParams.set('mois', params.mois);
    if (params.annee) searchParams.set('annee', params.annee);
    if (params.typeCulte) searchParams.set('typeCulte', params.typeCulte);
    const qs = searchParams.toString();
    return api.delete<{ message: string; deleted: number; filters: Record<string, string> }>(`/enseignements/batch${qs ? `?${qs}` : ''}`);
  },
};
