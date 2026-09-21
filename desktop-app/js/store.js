const CACHE_KEYS = {
  teachings: 'mykog_cache_teachings',
  lives: 'mykog_cache_lives',
  calendar: 'mykog_cache_calendar',
  textResumes: 'mykog_cache_textresumes',
  annonces: 'mykog_cache_annonces',
};

const Store = {
  state: {
    user: null,
    teachings: [],
    liveStreams: [],
    activeLive: null,
    scheduledStreams: [],
    categories: [],
    typeCultes: [],
    textResumes: [],
    calendarEvents: [],
    annonces: [],
    isOffline: false,
    isLoading: true,
    isLoggedIn: false,
    isDarkMode: true,
    currentPage: 'login',
    audioPlayer: {
      currentTeaching: null,
      playlist: [],
      isPlaying: false,
      currentTime: 0,
      duration: 0,
    },
    recentlyPlayed: [],
    favorites: [],
    favoritePackages: [],
    notificationsEnabled: true,
  },

  listeners: [],

  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  },

  notify() {
    this.listeners.forEach(l => l(this.state));
  },

  setState(updates) {
    Object.assign(this.state, updates);
    this.notify();
  },

  async initialize() {
    this.setState({ isLoading: true });

    const savedTheme = localStorage.getItem('mykog_theme');
    if (savedTheme === 'light') {
      this.setState({ isDarkMode: false });
      document.body.classList.add('light-mode');
    }

    const loggedIn = localStorage.getItem('mykog_logged_in') === 'true';
    const savedUser = localStorage.getItem('mykog_user');

    if (loggedIn && savedUser) {
      try {
        const user = JSON.parse(savedUser);
        this.setState({ user, isLoggedIn: true });
      } catch {
        localStorage.removeItem('mykog_logged_in');
      }
    }

    this.loadCachedData();

    const savedPkg = localStorage.getItem('mykog_packages');
    if (savedPkg) {
      try { this.setState({ favoritePackages: JSON.parse(savedPkg) }); } catch {}
    }

    if (!navigator.onLine) {
      this.setState({ isOffline: true, isLoading: false });
      return;
    }

    try {
      await Promise.all([
        this.loadTeachings(),
        this.loadLives(),
        this.loadCalendarEvents(),
        this.loadTextResumes(),
        this.loadAnnonces(),
      ]);
      if (this.state.isLoggedIn && this.state.user) {
        await this.syncUserWithBackend();
      }
      this.setState({ isOffline: false });
    } catch (e) {
      console.warn('Offline mode:', e.message);
      this.setState({ isOffline: true });
    }

    this.setState({ isLoading: false });
  },

  loadCachedData() {
    try {
      const teachings = localStorage.getItem(CACHE_KEYS.teachings);
      if (teachings) {
        const data = JSON.parse(teachings);
        this.setState({
          teachings: data,
          categories: API.getCategories(data),
          typeCultes: API.getTypeCultes(data),
        });
      }
      const lives = localStorage.getItem(CACHE_KEYS.lives);
      if (lives) {
        const data = JSON.parse(lives);
        this.setState({
          liveStreams: data.streams || [],
          activeLive: data.active || null,
          scheduledStreams: data.scheduled || [],
        });
      }
      const calendar = localStorage.getItem(CACHE_KEYS.calendar);
      if (calendar) {
        this.setState({ calendarEvents: JSON.parse(calendar) });
      }
      const resumes = localStorage.getItem(CACHE_KEYS.textResumes);
      if (resumes) {
        this.setState({ textResumes: JSON.parse(resumes) });
      }
      const annonces = localStorage.getItem(CACHE_KEYS.annonces);
      if (annonces) {
        this.setState({ annonces: JSON.parse(annonces) });
      }
    } catch {}
  },

  saveCache(key, data) {
    try {
      localStorage.setItem(key, JSON.stringify(data));
    } catch {}
  },

  // --- Login / Logout ---

  setUser(user) {
    this.setState({ user, isLoggedIn: true });
    localStorage.setItem('mykog_user', JSON.stringify(user));
    localStorage.setItem('mykog_logged_in', 'true');
  },

  async logout() {
    this.stopPolling();
    this.setState({
      user: null,
      isLoggedIn: false,
      favorites: [],
      recentlyPlayed: [],
    });
    localStorage.removeItem('mykog_user');
    localStorage.removeItem('mykog_logged_in');
    App.navigate('login');
  },

  async retryConnection() {
    this.setState({ isLoading: true });
    try {
      await Promise.all([
        this.loadTeachings(),
        this.loadLives(),
        this.loadCalendarEvents(),
        this.loadTextResumes(),
        this.loadAnnonces(),
      ]);
      if (this.state.isLoggedIn && this.state.user) {
        await this.syncUserWithBackend();
      }
      this.setState({ isOffline: false, isLoading: false });
      App.showToast('Connexion r\u00e9tablie');
      if (App.currentPage === 'home') HomePage.render();
    } catch {
      this.setState({ isOffline: true, isLoading: false });
      App.showToast('Impossible de se connecter au serveur');
    }
  },

  async syncUserWithBackend() {
    const user = this.state.user;
    if (!user) return;
    try {
      const synced = await API.updateUser(user.id, {
        name: user.name,
        email: user.email,
        favoriteTeachingIds: user.favoriteTeachingIds || [],
        downloadedTeachingIds: user.downloadedTeachingIds || [],
        recentlyPlayedIds: user.recentlyPlayedIds || [],
        notificationsEnabled: user.notificationsEnabled,
      });
      if (synced && synced.user) {
        this.setState({ user: { ...user, ...synced.user } });
        localStorage.setItem('mykog_user', JSON.stringify(this.state.user));
      }
    } catch {
      // Silent fail - will retry next time
    }
  },

  // --- Teachings ---

  async loadTeachings() {
    try {
      const teachings = await API.getEnseignements();

      // Préserver les téléchargements qui ont été supprimés du serveur
      const downloadedIds = this.state.user?.downloadedTeachingIds || [];
      if (downloadedIds.length > 0) {
        const serverIds = new Set(teachings.map(t => t.id));
        const orphanedIds = downloadedIds.filter(id => !serverIds.has(id));
        if (orphanedIds.length > 0) {
          const cachedData = localStorage.getItem(CACHE_KEYS.teachings);
          if (cachedData) {
            try {
              const cached = JSON.parse(cachedData);
              const orphaned = cached.filter(t => orphanedIds.includes(t.id));
              teachings.push(...orphaned);
            } catch {}
          }
        }
      }

      const categories = API.getCategories(teachings);
      const typeCultes = API.getTypeCultes(teachings);
      this.setState({ teachings, categories, typeCultes, isOffline: false });
      this.saveCache(CACHE_KEYS.teachings, teachings);
    } catch {
      throw new Error('Teachings load failed');
    }
  },

  searchTeachings(teachings, query) {
    if (!query || !query.trim()) return teachings;
    const q = query.toLowerCase().trim();
    const terms = q.split(/\s+/).filter(Boolean);

    const scored = teachings.map(t => {
      const fields = {
        title: (t.title || '').toLowerCase(),
        speaker: (t.speaker || '').toLowerCase(),
        category: (t.category || '').toLowerCase(),
        description: (t.description || '').toLowerCase(),
        typeCulte: (t.typeCulte || '').toLowerCase(),
        annee: (t.annee || ''),
        mois: (t.mois || '').toLowerCase(),
        id: (t.id || '').toLowerCase(),
      };

      let score = 0;
      for (const term of terms) {
        if (fields.title === term) score += 100;
        else if (fields.title.includes(term)) score += 50;
        if (fields.speaker === term) score += 80;
        else if (fields.speaker.includes(term)) score += 30;
        if (fields.category === term) score += 60;
        else if (fields.category.includes(term)) score += 25;
        if (fields.description.includes(term)) score += 15;
        if (fields.typeCulte.includes(term)) score += 20;
        if (fields.annee === term) score += 40;
        else if (fields.annee.includes(term)) score += 10;
        if (fields.mois === term) score += 40;
        else if (fields.mois.includes(term)) score += 10;
        if (fields.id === term) score += 50;
      }
      return { teaching: t, score };
    });

    return scored
      .filter(item => item.score > 0)
      .sort((a, b) => b.score - a.score)
      .map(item => item.teaching);
  },

  getTeachingById(id) {
    return this.state.teachings.find(t => t.id === id);
  },

  _shuffle(array) {
    const a = [...array];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  },

  getPopularTeachings(limit = 6) {
    return this._shuffle(this.state.teachings).slice(0, limit);
  },

  getRecommendedTeachings() {
    return this._shuffle(this.state.teachings).slice(0, 6);
  },

  getTypeCultes() {
    return this.state.typeCultes;
  },

  getTeachingsByType(type) {
    return this.state.teachings.filter(t =>
      t.typeCulte?.toLowerCase() === type.toLowerCase()
    );
  },

  getDownloadedTeachings() {
    return this.state.teachings.filter(t =>
      this.state.user?.downloadedTeachingIds?.includes(t.id)
    );
  },

  // --- Favorites ---

  toggleFavorite(teachingId) {
    if (!this.state.user) return;
    const ids = [...(this.state.user.favoriteTeachingIds || [])];
    const idx = ids.indexOf(teachingId);
    if (idx > -1) {
      ids.splice(idx, 1);
    } else {
      ids.push(teachingId);
    }
    this.updateUserField('favoriteTeachingIds', ids);
  },

  isFavorite(teachingId) {
    return this.state.user?.favoriteTeachingIds?.includes(teachingId) || false;
  },

  // --- Downloads ---

  toggleDownload(teachingId) {
    if (!this.state.user) return;
    const ids = [...(this.state.user.downloadedTeachingIds || [])];
    const idx = ids.indexOf(teachingId);
    if (idx > -1) {
      ids.splice(idx, 1);
    } else {
      ids.push(teachingId);
    }
    this.updateUserField('downloadedTeachingIds', ids);
  },

  isDownloaded(teachingId) {
    return this.state.user?.downloadedTeachingIds?.includes(teachingId) || false;
  },

  // --- Recently Played ---

  addToRecentlyPlayed(teachingId) {
    const ids = [teachingId, ...(this.state.user?.recentlyPlayedIds || []).filter(id => id !== teachingId)].slice(0, 20);
    this.updateUserField('recentlyPlayedIds', ids);
  },

  // --- Notifications ---

  toggleNotifications() {
    const enabled = !this.state.notificationsEnabled;
    this.setState({ notificationsEnabled: enabled });
    this.updateUserField('notificationsEnabled', enabled);
  },

  // --- User Updates ---

  updateUserField(field, value) {
    if (!this.state.user) return;
    const updated = {
      ...this.state.user,
      [field]: value,
      updatedAt: new Date().toISOString(),
    };
    this.setState({ user: updated });
    localStorage.setItem('mykog_user', JSON.stringify(updated));

    if (!this.state.isOffline) {
      API.updateUser(this.state.user.id, { [field]: value }).catch(() => {});
    }
  },

  // --- Lives ---

  async loadLives() {
    try {
      const [activeResult, streams] = await Promise.all([
        API.getActiveLive().catch(() => null),
        API.getLives(),
      ]);
      const active = activeResult && activeResult.id ? activeResult : null;
      const allStreams = Array.isArray(streams) ? streams : (streams?.streams || []);
      const scheduledStreams = allStreams.filter(s =>
        s.status === 'scheduled' || s.status === 'planifi\u00e9'
      );
      this.setState({
        activeLive: active,
        liveStreams: allStreams,
        scheduledStreams,
      });
      this.saveCache(CACHE_KEYS.lives, {
        active,
        streams: allStreams,
        scheduled: scheduledStreams,
      });
    } catch {
      throw new Error('Lives load failed');
    }
  },

  // --- Calendar ---

  async loadCalendarEvents() {
    try {
      const events = await API.getCalendarEvents();
      const list = Array.isArray(events) ? events : (events?.events || []);
      this.setState({ calendarEvents: list });
      this.saveCache(CACHE_KEYS.calendar, list);
    } catch {
      throw new Error('Calendar load failed');
    }
  },

  getUpcomingEvents(limit = 5) {
    const now = new Date();
    return [...this.state.calendarEvents]
      .filter(e => new Date(e.startDate) >= now)
      .sort((a, b) => new Date(a.startDate) - new Date(b.startDate))
      .slice(0, limit);
  },

  // --- Text Resumes ---

  async loadTextResumes() {
    try {
      const data = await API.getTextResumes();
      const list = Array.isArray(data) ? data : (data?.resumes || []);
      this.setState({ textResumes: list });
      this.saveCache(CACHE_KEYS.textResumes, list);
    } catch {
      throw new Error('Text resumes load failed');
    }
  },

  // --- Annonces ---

  async loadAnnonces() {
    try {
      const data = await API.getAnnonces();
      const list = Array.isArray(data) ? data : (data?.annonces || []);
      this.setState({ annonces: list });
      this.saveCache(CACHE_KEYS.annonces, list);
    } catch {
      // Non-critical
    }
  },

  // --- Greeting ---

  // --- Polling for new content ---

  pollInterval: null,

  startPolling() {
    this.stopPolling();
    this.pollInterval = setInterval(async () => {
      if (this.state.isOffline) return;
      try {
        const oldCount = this.state.teachings.length;
        const oldCalCount = this.state.calendarEvents.length;
        const oldResCount = this.state.textResumes.length;
        const oldAnnCount = this.state.annonces.length;

        await this.pollCheck();

        if (this.state.teachings.length > oldCount) {
          SoundManager.playNotification();
          App.showToast('Nouvel enseignement disponible');
          if (App.currentPage === 'home') HomePage.render();
        }
        if (this.state.calendarEvents.length > oldCalCount) {
          SoundManager.playNotification();
          App.showToast('Nouvel \u00e9v\u00e9nement au calendrier');
        }
        if (this.state.textResumes.length > oldResCount) {
          SoundManager.playNotification();
          App.showToast('Nouveau r\u00e9sum\u00e9 de texte disponible');
        }
        if (this.state.annonces.length > oldAnnCount) {
          SoundManager.playNotification();
          App.showToast('Nouvelle annonce disponible');
        }
      } catch {}
    }, 30000);
  },

  async pollCheck() {
    try {
      const teachings = await API.getEnseignements();
      if (teachings) {
        // Préserver les téléchargements qui ont été supprimés du serveur
        const downloadedIds = this.state.user?.downloadedTeachingIds || [];
        if (downloadedIds.length > 0) {
          const serverIds = new Set(teachings.map(t => t.id));
          const orphanedIds = downloadedIds.filter(id => !serverIds.has(id));
          if (orphanedIds.length > 0) {
            const cachedData = localStorage.getItem(CACHE_KEYS.teachings);
            if (cachedData) {
              try {
                const cached = JSON.parse(cachedData);
                const orphaned = cached.filter(t => orphanedIds.includes(t.id));
                teachings.push(...orphaned);
              } catch {}
            }
          }
        }
        const categories = API.getCategories(teachings);
        const typeCultes = API.getTypeCultes(teachings);
        this.setState({ teachings, categories, typeCultes });
        this.saveCache(CACHE_KEYS.teachings, teachings);
      }
    } catch {}
    try {
      const [eventsData, resumesData, annoncesData] = await Promise.all([
        API.getCalendarEvents(),
        API.getTextResumes(),
        API.getAnnonces(),
      ]);
      const events = Array.isArray(eventsData) ? eventsData : (eventsData?.events || []);
      if (events.length) {
        this.setState({ calendarEvents: events });
        this.saveCache(CACHE_KEYS.calendar, events);
      }
      const resumes = Array.isArray(resumesData) ? resumesData : (resumesData?.resumes || []);
      if (resumes.length) {
        this.setState({ textResumes: resumes });
        this.saveCache(CACHE_KEYS.textResumes, resumes);
      }
      const annonces = Array.isArray(annoncesData) ? annoncesData : (annoncesData?.annonces || []);
      if (annonces.length) {
        this.setState({ annonces });
        this.saveCache(CACHE_KEYS.annonces, annonces);
      }
    } catch {}
  },

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
  },

  getGreeting() {
    const hour = new Date().getHours();
    if (hour < 12) return 'Bonjour';
    if (hour < 17) return 'Bon apr\u00e8s-midi';
    return 'Bonsoir';
  },

  // --- Player ---

  audioElement: null,

  initAudio() {
    if (this.audioElement) return;
    this.audioElement = new Audio();
    this.audioElement.preload = 'metadata';

    this.audioElement.addEventListener('loadedmetadata', () => {
      const ap = this.state.audioPlayer;
      if (ap.currentTeaching) {
        this.setState({
          audioPlayer: { ...ap, duration: this.audioElement.duration || ap.duration },
        });
      }
    });

    this.audioElement.addEventListener('timeupdate', () => {
      const ap = this.state.audioPlayer;
      if (ap.currentTeaching && this.audioElement) {
        this.setState({
          audioPlayer: { ...ap, currentTime: this.audioElement.currentTime || 0 },
        });
      }
    });

    this.audioElement.addEventListener('play', () => {
      const ap = this.state.audioPlayer;
      if (!ap.isPlaying) {
        this.setState({ audioPlayer: { ...ap, isPlaying: true } });
      }
    });

    this.audioElement.addEventListener('pause', () => {
      const ap = this.state.audioPlayer;
      if (ap.isPlaying) {
        this.setState({ audioPlayer: { ...ap, isPlaying: false } });
      }
    });

    this.audioElement.addEventListener('ended', () => {
      this.nextTrack();
    });

    this.audioElement.addEventListener('error', () => {
      const ap = this.state.audioPlayer;
      this.setState({ audioPlayer: { ...ap, isPlaying: false } });
    });
  },

  playTeaching(teaching, playlist) {
    this.initAudio();
    const list = playlist || [teaching];
    const ap = {
      currentTeaching: teaching,
      playlist: list,
      isPlaying: true,
      currentTime: 0,
      duration: teaching.duration || 0,
    };
    this.setState({ audioPlayer: ap });
    this.addToRecentlyPlayed(teaching.id);
    if (this.audioElement && teaching.audioUrl) {
      this.audioElement.src = teaching.audioUrl;
      this.audioElement.currentTime = 0;
      this.audioElement.play().catch(() => {});
    }
    PlayerUI.show();
  },

  togglePlayPause() {
    const ap = this.state.audioPlayer;
    if (!ap.currentTeaching) return;
    if (ap.isPlaying) {
      this.audioElement?.pause();
    } else {
      this.audioElement?.play().catch(() => {});
    }
    this.setState({ audioPlayer: { ...ap, isPlaying: !ap.isPlaying } });
  },

  nextTrack() {
    const { currentTeaching, playlist } = this.state.audioPlayer;
    if (!playlist?.length) return;
    const idx = playlist.findIndex(t => t.id === currentTeaching?.id);
    const next = playlist[(idx + 1) % playlist.length];
    this.playTeaching(next, playlist);
  },

  prevTrack() {
    const { currentTeaching, playlist } = this.state.audioPlayer;
    if (!playlist?.length) return;
    if (this.audioElement && this.audioElement.currentTime > 3) {
      this.audioElement.currentTime = 0;
      return;
    }
    const idx = playlist.findIndex(t => t.id === currentTeaching?.id);
    const prev = playlist[(idx - 1 + playlist.length) % playlist.length];
    this.playTeaching(prev, playlist);
  },

  seekTo(percent) {
    const ap = this.state.audioPlayer;
    if (!ap.currentTeaching || !this.audioElement) return;
    const time = percent * (this.audioElement.duration || ap.duration);
    this.audioElement.currentTime = time;
    this.setState({ audioPlayer: { ...ap, currentTime: time } });
  },

  formatDuration(seconds) {
    if (!seconds) return '0:00';
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    if (h > 0) return `${h}h ${m}m`;
    return `${m}:${s.toString().padStart(2, '0')}`;
  },

  formatDate(dateStr) {
    const d = new Date(dateStr);
    const months = ['Janvier', 'F\u00e9vrier', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Ao\u00fbt', 'Septembre', 'Octobre', 'Novembre', 'D\u00e9cembre'];
    return `${months[d.getMonth()]} ${d.getFullYear()}`;
  },

  formatEventDate(dateStr) {
    const d = new Date(dateStr);
    const day = d.getDate().toString().padStart(2, '0');
    const months = ['Jan', 'F\u00e9v', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Ao\u00fb', 'Sep', 'Oct', 'Nov', 'D\u00e9c'];
    const hours = d.getHours().toString().padStart(2, '0');
    const mins = d.getMinutes().toString().padStart(2, '0');
    return `${day} ${months[d.getMonth()]} ${d.getFullYear()} \u00e0 ${hours}:${mins}`;
  },

  // --- Favorite Packages ---

  savePackages() {
    localStorage.setItem('mykog_packages', JSON.stringify(this.state.favoritePackages));
  },

  createPackage(name, description) {
    const pkg = {
      id: 'pkg_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6),
      name: name.trim(),
      description: description || '',
      teachingIds: [],
      createdAt: new Date().toISOString(),
    };
    const packages = [...(this.state.favoritePackages || []), pkg];
    this.setState({ favoritePackages: packages });
    this.savePackages();
    return pkg;
  },

  deletePackage(packageId) {
    const packages = (this.state.favoritePackages || []).filter(p => p.id !== packageId);
    this.setState({ favoritePackages: packages });
    this.savePackages();
  },

  renamePackage(packageId, name) {
    const packages = (this.state.favoritePackages || []).map(p =>
      p.id === packageId ? { ...p, name: name.trim() } : p
    );
    this.setState({ favoritePackages: packages });
    this.savePackages();
  },

  addTeachingToPackage(packageId, teachingId) {
    const packages = (this.state.favoritePackages || []).map(p => {
      if (p.id !== packageId) return p;
      if (p.teachingIds.includes(teachingId)) return p;
      return { ...p, teachingIds: [...p.teachingIds, teachingId] };
    });
    this.setState({ favoritePackages: packages });
    this.savePackages();
  },

  removeTeachingFromPackage(packageId, teachingId) {
    const packages = (this.state.favoritePackages || []).map(p => {
      if (p.id !== packageId) return p;
      return { ...p, teachingIds: p.teachingIds.filter(id => id !== teachingId) };
    });
    this.setState({ favoritePackages: packages });
    this.savePackages();
  },

  isTeachingInPackage(packageId, teachingId) {
    const pkg = (this.state.favoritePackages || []).find(p => p.id === packageId);
    return pkg?.teachingIds.includes(teachingId) || false;
  },

  getPackageById(id) {
    return (this.state.favoritePackages || []).find(p => p.id === id);
  },

  getTeachingsInPackage(packageId) {
    const pkg = (this.state.favoritePackages || []).find(p => p.id === packageId);
    if (!pkg) return [];
    return pkg.teachingIds
      .map(id => this.getTeachingById(id))
      .filter(Boolean);
  },
};
