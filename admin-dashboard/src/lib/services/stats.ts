import { api } from '../api';
import type { UserStats } from '../types';

export const statsService = {
  getUserStats: () => api.get<UserStats>('/users/stats'),

  getDashboardStats: async () => {
    const [users, enseignements, lives, textResumes] = await Promise.all([
      api.get<any[]>('/users'),
      api.get<any[]>('/enseignements'),
      api.get<any[]>('/lives'),
      api.get<any[]>('/text-resumes'),
    ]);

    const activeLives = lives.filter((l: any) => l.status === 'live');
    const totalPlays = enseignements.reduce((sum: number, e: any) => sum + (e.playCount || 0), 0);
    const totalViews = textResumes.reduce((sum: number, t: any) => sum + (t.viewCount || 0), 0);

    return {
      totalUsers: users.length,
      totalEnseignements: enseignements.length,
      activeLives: activeLives.length,
      totalPlays,
      totalPdfViews: totalViews,
      totalPdfs: textResumes.length,
    };
  },
};
