import { api } from '../api';

export const notificationsService = {
  registerToken: (userId: string, fcmToken: string) =>
    api.post<{ message: string }>('/notifications/tokens', { userId, fcmToken }),

  unregisterToken: (userId: string, fcmToken: string) =>
    api.delete<{ message: string }>('/notifications/tokens', { data: { userId, fcmToken } } as any),

  sendToAll: (title: string, body: string, data?: Record<string, string>, imageUrl?: string) =>
    api.post<{ message: string; sent: number; failed: number; total: number }>(
      '/notifications/send/all', { title, body, data, imageUrl }
    ),

  sendToUser: (userId: string, title: string, body: string, data?: Record<string, string>, imageUrl?: string) =>
    api.post<{ message: string; sent: number; failed: number }>(
      '/notifications/send/user', { userId, title, body, data, imageUrl }
    ),

  sendToTopic: (topic: string, title: string, body: string, data?: Record<string, string>, imageUrl?: string) =>
    api.post<{ message: string; messageId: string }>(
      '/notifications/send/topic', { topic, title, body, data, imageUrl }
    ),
};
