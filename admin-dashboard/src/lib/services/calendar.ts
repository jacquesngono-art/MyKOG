import { api } from '../api';
import type { CalendarEvent } from '../types';

export const calendarService = {
  getAll: () => api.get<CalendarEvent[]>('/calendar'),

  getByYear: (year: number) =>
    api.get<CalendarEvent[]>(`/calendar/year/${year}`),

  getById: (id: string) => api.get<CalendarEvent>(`/calendar/${id}`),

  create: (data: {
    title: string;
    description?: string;
    startDate: string;
    endDate?: string;
    location?: string;
    category?: string;
    color?: string;
    isAllDay?: boolean;
  }) => api.post<CalendarEvent>('/calendar', data),

  update: (id: string, data: Partial<CalendarEvent>) =>
    api.put<CalendarEvent>(`/calendar/${id}`, data),

  delete: (id: string) => api.delete<{ message: string }>(`/calendar/${id}`),

  deleteAll: () => api.delete<{ message: string; deleted: number }>('/calendar/all'),
};
