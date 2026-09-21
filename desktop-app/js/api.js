const API_BASE = (() => {
  const stored = localStorage.getItem('mykog_api_base');
  if (stored) return stored;
  return 'http://185.98.128.123:3001/mykog-api/api';
})();

const API = {
  setBaseUrl(url) {
    localStorage.setItem('mykog_api_base', url);
  },

  async request(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const config = {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    };
    if (config.body && typeof config.body === 'object' && !(config.body instanceof FormData)) {
      config.body = JSON.stringify(config.body);
    }
    if (config.body instanceof FormData) {
      delete config.headers['Content-Type'];
    }
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 15000);
      config.signal = controller.signal;
      const res = await fetch(url, config);
      clearTimeout(timeout);
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || `HTTP ${res.status}`);
      }
      return res.json();
    } catch (err) {
      if (err.name === 'AbortError') throw new Error('Timeout');
      throw err;
    }
  },

  // --- Enseignements ---
  async getEnseignements() {
    return this.request('/enseignements');
  },
  async getEnseignement(id) {
    return this.request(`/enseignements/${id}`);
  },
  async createEnseignement(formData) {
    return this.request('/enseignements', { method: 'POST', body: formData });
  },
  async updateEnseignement(id, formData) {
    return this.request(`/enseignements/${id}`, { method: 'PUT', body: formData });
  },
  async deleteEnseignement(id) {
    return this.request(`/enseignements/${id}`, { method: 'DELETE' });
  },
  async deleteAllEnseignements() {
    return this.request('/enseignements/all', { method: 'DELETE' });
  },
  async deleteEnseignementsByFilter(params = {}) {
    const q = new URLSearchParams(params).toString();
    return this.request(`/enseignements/batch${q ? '?' + q : ''}`, { method: 'DELETE' });
  },

  // --- Annonces ---
  async getAnnonces() {
    return this.request('/annonces');
  },
  async createAnnonce(data) {
    return this.request('/annonces', { method: 'POST', body: data });
  },
  async deleteAnnonce(id) {
    return this.request(`/annonces/${id}`, { method: 'DELETE' });
  },
  async deleteAllAnnonces() {
    return this.request('/annonces/all', { method: 'DELETE' });
  },

  // --- Lives ---
  async getLives() {
    return this.request('/lives');
  },
  async getActiveLive() {
    return this.request('/lives/active');
  },
  async getLiveById(id) {
    return this.request(`/lives/${id}`);
  },
  async getServerInfo() {
    return this.request('/lives/server-info');
  },
  async getLiveViewerCount(id) {
    return this.request(`/lives/${id}/viewers`);
  },
  async createLive(data) {
    return this.request('/lives', { method: 'POST', body: data });
  },
  async updateLive(id, data) {
    return this.request(`/lives/${id}`, { method: 'PUT', body: data });
  },
  async updateLiveStatus(id, status) {
    return this.request(`/lives/${id}/status`, { method: 'PUT', body: { status } });
  },
  async joinLive(id) {
    return this.request(`/lives/${id}/join`, { method: 'POST' });
  },
  async leaveLive(id) {
    return this.request(`/lives/${id}/leave`, { method: 'POST' });
  },
  async deleteLive(id) {
    return this.request(`/lives/${id}`, { method: 'DELETE' });
  },
  async deleteAllLives() {
    return this.request('/lives/all', { method: 'DELETE' });
  },
  async getViewerToken(id, userId) {
    return this.request(`/lives/${id}/token`, { method: 'POST', body: { userId } });
  },
  async getPublisherToken(id) {
    return this.request(`/lives/${id}/publisher-token`, { method: 'POST' });
  },

  // --- Users (connexion / profil) ---
  async login(userData) {
    return this.request('/users', { method: 'POST', body: userData });
  },
  async getUser(id) {
    return this.request(`/users/${id}`);
  },
  async createUser(userData) {
    return this.request('/users', {
      method: 'POST',
      body: userData,
    });
  },
  async updateUser(id, data) {
    return this.request(`/users/${id}`, {
      method: 'PUT',
      body: data,
    });
  },
  async deleteUser(id) {
    return this.request(`/users/${id}`, { method: 'DELETE' });
  },
  async deleteAllUsers() {
    return this.request('/users/all', { method: 'DELETE' });
  },
  async getUserStats() {
    return this.request('/users/stats');
  },

  // --- Calendar ---
  async getCalendarEvents() {
    return this.request('/calendar');
  },
  async getCalendarEventsByYear(year) {
    return this.request(`/calendar/year/${year}`);
  },
  async getCalendarEvent(id) {
    return this.request(`/calendar/${id}`);
  },
  async createCalendarEvent(data) {
    return this.request('/calendar', { method: 'POST', body: data });
  },
  async updateCalendarEvent(id, data) {
    return this.request(`/calendar/${id}`, { method: 'PUT', body: data });
  },
  async deleteCalendarEvent(id) {
    return this.request(`/calendar/${id}`, { method: 'DELETE' });
  },
  async deleteAllCalendarEvents() {
    return this.request('/calendar/all', { method: 'DELETE' });
  },

  // --- Text Resumes ---
  async getTextResumes(params = {}) {
    const q = new URLSearchParams();
    if (params.category) q.set('category', params.category);
    if (params.mois) q.set('mois', params.mois);
    if (params.annee) q.set('annee', params.annee);
    if (params.typeCulte) q.set('typeCulte', params.typeCulte);
    if (params.sortBy) q.set('sortBy', params.sortBy);
    if (params.order) q.set('order', params.order);
    const qs = q.toString();
    return this.request(`/text-resumes${qs ? '?' + qs : ''}`);
  },
  async getTextResume(id) {
    return this.request(`/text-resumes/${id}`);
  },
  async createTextResume(formData) {
    return this.request('/text-resumes', { method: 'POST', body: formData });
  },
  async updateTextResume(id, formData) {
    return this.request(`/text-resumes/${id}`, { method: 'PUT', body: formData });
  },
  async deleteTextResume(id) {
    return this.request(`/text-resumes/${id}`, { method: 'DELETE' });
  },
  async deleteAllTextResumes() {
    return this.request('/text-resumes/all', { method: 'DELETE' });
  },
  async deleteTextResumesByFilter(params = {}) {
    const q = new URLSearchParams(params).toString();
    return this.request(`/text-resumes/batch${q ? '?' + q : ''}`, { method: 'DELETE' });
  },

  // --- Upload ---
  async uploadFile(formData) {
    return this.request('/upload', { method: 'POST', body: formData });
  },

  // --- Stream ---
  async resolveStream(key) {
    return this.request(`/stream/${encodeURIComponent(key)}`);
  },

  // --- Notifications ---
  async registerNotificationToken(fcmToken, userId) {
    return this.request('/notifications/tokens', {
      method: 'POST',
      body: { fcmToken, userId },
    });
  },
  async unregisterNotificationToken(fcmToken, userId) {
    return this.request('/notifications/tokens', {
      method: 'DELETE',
      body: { fcmToken, userId },
    });
  },
  async sendNotificationToAll(payload) {
    return this.request('/notifications/send/all', { method: 'POST', body: payload });
  },
  async sendNotificationToUser(userId, payload) {
    return this.request('/notifications/send/user', { method: 'POST', body: { userId, ...payload } });
  },
  async sendNotificationToTopic(topic, payload) {
    return this.request('/notifications/send/topic', { method: 'POST', body: { topic, ...payload } });
  },

  // --- Helpers ---
  getCategories(teachings) {
    const cats = [...new Set((teachings || []).map(t => t.category).filter(Boolean))];
    return cats;
  },

  getTypeCultes(teachings) {
    const types = [...new Set((teachings || []).map(t => t.typeCulte).filter(Boolean))];
    const order = ["Culte d'Impact", 'Culte Prophétique', "Culte d'Enseignement", 'Conférence', 'Séminaire'];
    return types.sort((a, b) => {
      const ai = order.indexOf(a);
      const bi = order.indexOf(b);
      return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
    });
  },

  getPopularTeachings(teachings, limit = 6) {
    return [...(teachings || [])]
      .sort((a, b) => (b.playCount || 0) - (a.playCount || 0))
      .slice(0, limit);
  },

  getRecommendedTeachings(teachings) {
    return (teachings || []).filter(t => t.isFeatured || t.isNew).slice(0, 6);
  },

  getSampleTeachings() {
    return [
      { id: '1', title: 'La Puissance de la Foi', speaker: 'Pasteur Jean', category: 'Foi', duration: 3600, playCount: 1520, isFeatured: true, isNew: false, description: 'Un enseignement puissant sur la foi.', typeCulte: "Culte d'Impact", annee: '2024', mois: 'Janvier', publishedAt: '2024-01-15', audioUrl: '', artworkUrl: '' },
      { id: '2', title: 'Les Fondations de la Prière', speaker: 'Pasteur Marie', category: 'Prière', duration: 2700, playCount: 980, isFeatured: true, isNew: false, description: 'Apprenez les bases d\'une vie de prière.', typeCulte: 'Culte Prophétique', annee: '2024', mois: 'Février', publishedAt: '2024-02-10', audioUrl: '', artworkUrl: '' },
      { id: '3', title: "L'Amour de Dieu", speaker: 'Pasteur Paul', category: 'Amour', duration: 4200, playCount: 2100, isFeatured: false, isNew: true, description: "Découvrez l'amour infini de Dieu.", typeCulte: "Culte d'Enseignement", annee: '2024', mois: 'Mars', publishedAt: '2024-03-05', audioUrl: '', artworkUrl: '' },
      { id: '4', title: 'La Joie du Seigneur', speaker: 'Pasteur Jean', category: 'Joie', duration: 1800, playCount: 750, isFeatured: false, isNew: true, description: 'Une méditation sur la joie chrétienne.', typeCulte: "Culte d'Impact", annee: '2024', mois: 'Avril', publishedAt: '2024-04-20', audioUrl: '', artworkUrl: '' },
      { id: '5', title: 'Les Principes Divins', speaker: 'Pasteur Marie', category: 'Principe Divin', duration: 5400, playCount: 3200, isFeatured: true, isNew: false, description: 'Les principes fondamentaux du royaume.', typeCulte: 'Culte Prophétique', annee: '2024', mois: 'Mai', publishedAt: '2024-05-12', audioUrl: '', artworkUrl: '' },
    ];
  },
};
