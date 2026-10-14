export interface Enseignement {
  id: string;
  title: string;
  speaker: string;
  description: string;
  category: string;
  duration: number;
  audioUrl: string;
  artworkUrl: string;
  tags: string[];
  playCount: number;
  rating: number;
  isNew: boolean;
  isFeatured: boolean;
  publishedAt: string;
  createdAt: string;
  updatedAt: string;
  mois: string;
  annee: string;
  typeCulte: string;
}

export interface LiveStream {
  id: string;
  title: string;
  description: string;
  pastor: string;
  thumbnailUrl: string;
  streamUrl: string;
  streamKey: string;
  rtmpUrl: string;
  hlsUrl: string;
  status: 'scheduled' | 'live' | 'ended';
  scheduledAt: string | null;
  startedAt: string | null;
  endedAt: string | null;
  viewerCount: number;
  peakViewerCount: number;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  profileImageUrl: string | null;
  favoriteTeachingIds: string[];
  downloadedTeachingIds: string[];
  recentlyPlayedIds: string[];
  notificationsEnabled: boolean;
  fcmTokens: string[];
  createdAt: string;
  updatedAt: string;
}

export interface CalendarEvent {
  id: string;
  title: string;
  description: string | null;
  startDate: string;
  endDate: string | null;
  location: string | null;
  category: string | null;
  color: string | null;
  isAllDay: boolean;
  createdBy: string | null;
  hasAlarm: boolean;
  alarmDaysBefore: number | null;
  alarmHoursBefore: number | null;
  alarmMinutesBefore: number | null;
  createdAt: string;
  updatedAt: string;
}

export interface Annonce {
  id: string;
  nom: string;
  description: string;
  dateCreation: string;
}

export interface TextResume {
  id: string;
  title: string;
  speaker: string;
  description: string;
  category: string;
  pdfUrl: string;
  coverImageUrl: string;
  tags: string[];
  viewCount: number;
  rating: number;
  isNew: boolean;
  isFeatured: boolean;
  publishedAt: string;
  createdAt: string;
  updatedAt: string;
  mois: string;
  annee: string;
  typeCulte: string;
  fileSize: number;
  pageCount: number;
}

export interface UserStats {
  totalUsers: number;
  usersWithFavorites: number;
  usersWithDownloads: number;
  totalFavorites: number;
  totalDownloads: number;
  notificationsEnabled: number;
  notificationsDisabled: number;
}

export interface ServerInfo {
  livekitUrl?: string;
  rtmpUrl?: string;
  whipUrl?: string;
  streamKey?: string;
  defaultStreamKey?: string;
  ingressId?: string;
  serverIP?: string;
  hlsUrl?: string;
  rtmpPort?: number;
  hlsPort?: number;
  hlsPath?: string;
}
