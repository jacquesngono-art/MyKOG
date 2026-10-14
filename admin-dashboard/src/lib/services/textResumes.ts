import { api } from '../api';
import type { TextResume } from '../types';

export const textResumesService = {
  getAll: (params?: { category?: string; mois?: string; annee?: string; typeCulte?: string; sortBy?: string; order?: string }) => {
    const searchParams = new URLSearchParams();
    if (params?.category) searchParams.set('category', params.category);
    if (params?.mois) searchParams.set('mois', params.mois);
    if (params?.annee) searchParams.set('annee', params.annee);
    if (params?.typeCulte) searchParams.set('typeCulte', params.typeCulte);
    if (params?.sortBy) searchParams.set('sortBy', params.sortBy);
    if (params?.order) searchParams.set('order', params.order);
    const qs = searchParams.toString();
    return api.get<TextResume[]>(`/text-resumes${qs ? `?${qs}` : ''}`);
  },

  getById: (id: string) => api.get<TextResume>(`/text-resumes/${id}`),

  create: (formData: FormData) =>
    api.post<{ id: string; message: string; data: TextResume }>('/text-resumes', formData, true),

  update: (id: string, formData: FormData) =>
    api.put<{ id: string; message: string; data: TextResume }>(`/text-resumes/${id}`, formData, true),

  delete: (id: string) => api.delete<{ message: string }>(`/text-resumes/${id}`),

  deleteAll: () => api.delete<{ message: string; deleted: number }>('/text-resumes/all'),

  deleteByFilter: (params: { category?: string; mois?: string; annee?: string; typeCulte?: string }) => {
    const searchParams = new URLSearchParams();
    if (params.category) searchParams.set('category', params.category);
    if (params.mois) searchParams.set('mois', params.mois);
    if (params.annee) searchParams.set('annee', params.annee);
    if (params.typeCulte) searchParams.set('typeCulte', params.typeCulte);
    const qs = searchParams.toString();
    return api.delete<{ message: string; deleted: number; filters: Record<string, string> }>(`/text-resumes/batch${qs ? `?${qs}` : ''}`);
  },
};
