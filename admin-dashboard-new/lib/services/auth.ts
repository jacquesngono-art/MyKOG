import { api } from '../api';

const AUTH_KEY = 'mykog_admin_auth';

export const authService = {
  login: async (password: string) => {
    await api.post<{ success: boolean }>('/auth/login', { password });
    localStorage.setItem(AUTH_KEY, '1');
  },

  updatePassword: (currentPassword: string, newPassword: string) =>
    api.put<{ success: boolean }>('/auth/password', { currentPassword, newPassword }),

  isAuthenticated: () =>
    typeof window !== 'undefined' && localStorage.getItem(AUTH_KEY) === '1',

  logout: () => {
    localStorage.removeItem(AUTH_KEY);
  },
};
