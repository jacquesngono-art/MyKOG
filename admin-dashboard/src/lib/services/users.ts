import { api } from '../api';
import type { User, UserStats } from '../types';

export const usersService = {
  getAll: () => api.get<User[]>('/users'),

  getById: (id: string) => api.get<User>(`/users/${id}`),

  getStats: () => api.get<UserStats>('/users/stats'),

  createOrUpdate: (data: Partial<User> & { id: string; name: string; email: string }) =>
    api.post<User>('/users', data),

  update: (id: string, data: Partial<User>) =>
    api.put<User>(`/users/${id}`, data),

  delete: (id: string) => api.delete<{ message: string }>(`/users/${id}`),

  deleteAll: () => api.delete<{ message: string; deleted: number }>('/users/all'),
};
