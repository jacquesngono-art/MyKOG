import { api } from '../api';
import type { Annonce } from '../types';

export const annoncesService = {
  getAll: () => api.get<Annonce[]>('/annonces'),

  create: (data: { nom: string; description: string }) =>
    api.post<{ id: string; message: string; data: Annonce }>('/annonces', data),

  delete: (id: string) => api.delete<{ id: string; message: string }>(`/annonces/${id}`),

  deleteAll: () => api.delete<{ message: string; deleted: number }>('/annonces/all'),
};
