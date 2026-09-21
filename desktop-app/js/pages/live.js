const LivePage = {
  currentTab: 'live',
  pollInterval: null,
  hls: null,
  isPlayerActive: false,
  serverConfig: null,

  async render() {
    const el = document.getElementById('page-live');

    if (window.electronAPI && window.electronAPI.getServerConfig) {
      try {
        this.serverConfig = await window.electronAPI.getServerConfig();
      } catch (_) {}
    }

    try {
      await Store.loadLives();
    } catch (_) {
      console.warn('LivePage: Store.loadLives a échoué, utilisation du cache');
    }

    this.renderContent(el);
    this.startPolling();
  },

  startPolling() {
    this.stopPolling();
    this.pollInterval = setInterval(async () => {
      if (document.getElementById('page-live').classList.contains('active')) {
        if (!this.isPlayerActive) {
          await Store.loadLives();
          this.renderContent(document.getElementById('page-live'));
        }
      }
    }, 15000);
  },

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
  },

  renderSkeleton() {
    return `
      <div class="tabs" style="opacity:0.6;pointer-events:none;margin-top:16px;">
        <div class="skeleton" style="padding:8px 16px;border-radius:10px;height:16px;width:80px;"></div>
        <div class="skeleton" style="padding:8px 16px;border-radius:10px;height:16px;width:100px;"></div>
      </div>
      <div style="padding:0 40px;">
        ${Skeleton.liveHeroCard()}
        ${Skeleton.liveGrid(3)}
      </div>
    `;
  },

  renderContent(el) {
    const s = Store.state;
    const isOffline = s.isOffline;

    el.innerHTML = `
      <div class="page-header">
        <div style="display:flex;align-items:center;gap:16px;">
          <div style="padding:12px;background:rgba(212,175,55,0.1);border-radius:12px;">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2"><path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
          </div>
          <div>
            <h1>Lives</h1>
            <p>Regardez en temps réel</p>
          </div>
        </div>
        ${s.activeLive ? `
          <div class="live-badge-header" onclick="LivePage.closePlayer()" style="cursor:pointer;">
            <span class="live-dot"></span>
            <span>EN DIRECT</span>
          </div>
        ` : ''}
      </div>

      <div class="tabs">
        <button class="tab ${this.currentTab === 'live' ? 'active' : ''}" onclick="LivePage.switchTab('live')">En direct</button>
        <button class="tab ${this.currentTab === 'scheduled' ? 'active' : ''}" onclick="LivePage.switchTab('scheduled')">Programmés</button>
      </div>

      ${isOffline ? `
        <div class="offline-banner">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <span>Les lives ne sont pas disponibles hors ligne</span>
        </div>
      ` : ''}

      ${this.isPlayerActive ? this.renderPlayerSection() : ''}

      <div id="live-tab-content" style="padding: 0 40px 32px;">
        ${this.currentTab === 'live' ? this.renderLiveTab() : this.renderScheduledTab()}
      </div>
    `;

    if (this.isPlayerActive) {
      this.initPlayer();
    }
  },

  renderPlayerSection() {
    const s = Store.state;
    const stream = s.activeLive;
    if (!stream) {
      this.closePlayer();
      return '';
    }
    return `
      <div class="live-player-section" id="livePlayerSection">
        <div class="player-wrapper">
          <video id="liveVideoPlayer" class="video-player" controls autoplay muted playsinline></video>
          <div class="player-overlay-loading" id="playerOverlayLoading">
            <div class="spinner"></div>
            <p class="overlay-text">Connexion au live...</p>
          </div>
          <div class="player-overlay-error hidden" id="playerOverlayError">
            <div class="error-icon">⚠</div>
            <p class="overlay-text" id="playerErrorMessage">Erreur de connexion</p>
            <button class="btn-retry-player" onclick="LivePage.retryPlayer()">Réessayer</button>
          </div>
        </div>
        <div class="player-info-bar">
          <div class="player-info-left">
            <span class="player-live-badge">
              <span class="live-dot"></span>
              EN DIRECT
            </span>
            <span class="player-title">${stream.title}</span>
            <span class="player-pastor">${stream.pastor}</span>
          </div>
          <div class="player-info-right">
            <span class="player-viewers" id="playerViewers">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <span id="viewerCount">${stream.viewerCount || 0}</span>
            </span>
            <span class="player-latency" id="playerLatency">--</span>
            <span class="player-quality" id="playerQuality">--</span>
            <button class="player-close-btn" onclick="LivePage.closePlayer()" title="Fermer le lecteur">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
        </div>
      </div>
    `;
  },

  renderLiveTab() {
    const s = Store.state;
    if (s.activeLive) {
      const stream = s.activeLive;
      return `
        <div class="active-live-card" onclick="LivePage.openLive('${stream.id}')">
          <div class="live-thumbnail">
            <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:var(--bg-secondary);">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="1.5"><path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
            </div>
            <div class="live-badge">
              <span class="live-dot"></span>
              <span>LIVE MAINTENANT</span>
            </div>
            <div class="live-viewers">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <span>${stream.viewerCount || 0}</span>
            </div>
          </div>
          <div class="live-info">
            <h3 class="live-title">${stream.title}</h3>
            <p class="live-pastor">${stream.pastor}</p>
            ${stream.description ? `<p class="live-desc">${stream.description}</p>` : ''}
            <button class="watch-btn" onclick="event.stopPropagation(); LivePage.openLive('${stream.id}')">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
              Regarder maintenant
            </button>
          </div>
        </div>
      `;
    }

    if (s.liveStreams.length === 0) {
      return `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
          <h3>Aucun live en cours</h3>
          <p>Revenez plus tard pour les cultes en direct.</p>
        </div>
      `;
    }

    return `
      <div style="display:grid;gap:20px;">
        ${s.liveStreams.map(stream => `
          <div class="glass-card live-card" onclick="LivePage.openLive('${stream.id}')">
            <div class="live-thumbnail">
              <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:var(--bg-secondary);">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="1.5"><path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
              </div>
            </div>
            <div class="live-badge">
              <span class="live-dot"></span>
              <span>EN DIRECT</span>
            </div>
            <div class="live-viewers">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <span>${stream.viewerCount || 0}</span>
            </div>
            <h3 class="live-title">${stream.title}</h3>
            <p class="live-pastor">${stream.pastor}</p>
            ${stream.description ? `<p class="live-desc">${stream.description}</p>` : ''}
          </div>
        `).join('')}
      </div>
    `;
  },

  renderScheduledTab() {
    const s = Store.state;
    if (s.scheduledStreams.length === 0) {
      return `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          <h3>Aucun live programmé</h3>
          <p>Les prochains cultes apparaîtront ici.</p>
        </div>
      `;
    }

    return `
      <div style="display:grid;gap:12px;">
        ${s.scheduledStreams.map(stream => this.renderScheduledCard(stream)).join('')}
      </div>
    `;
  },

  renderScheduledCard(stream) {
    const scheduledDate = stream.scheduledAt ? new Date(stream.scheduledAt) : null;
    let scheduledText = 'Bient\u00f4t';

    if (scheduledDate) {
      const now = new Date();
      const diff = scheduledDate - now;
      if (diff > 0) {
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));
        if (days > 0) scheduledText = `Dans ${days} jour${days > 1 ? 's' : ''}`;
        else {
          const hours = Math.floor(diff / (1000 * 60 * 60));
          if (hours > 0) scheduledText = `Dans ${hours} heure${hours > 1 ? 's' : ''}`;
          else {
            const mins = Math.floor(diff / (1000 * 60));
            if (mins > 0) scheduledText = `Dans ${mins} min`;
            else scheduledText = 'Bient\u00f4t';
          }
        }
      } else {
        scheduledText = 'Bient\u00f4t';
      }
    }

    return `
      <div class="glass-card scheduled-card">
        <div class="scheduled-thumb">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
        </div>
        <div class="scheduled-info">
          <p class="scheduled-title">${stream.title}</p>
          <p class="scheduled-meta">${stream.pastor}</p>
          <div class="scheduled-time">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            <span>${scheduledText}</span>
          </div>
        </div>
      </div>
    `;
  },

  switchTab(tab) {
    this.currentTab = tab;
    this.renderContent(document.getElementById('page-live'));
  },

  openLive(id) {
    const s = Store.state;
    const stream = s.activeLive?.id === id ? s.activeLive : s.liveStreams.find(l => l.id === id);
    if (!stream || stream.status !== 'live') {
      App.showToast('Ce live n\'est pas encore disponible');
      return;
    }
    Store.setState({ activeLive: stream });
    this.isPlayerActive = true;
    API.joinLive(id).catch(() => {});
    this.renderContent(document.getElementById('page-live'));
  },

  async initPlayer() {
    const video = document.getElementById('liveVideoPlayer');
    if (!video) return;

    const stream = Store.state.activeLive;
    if (!stream) {
      this.showPlayerError('Aucun live actif disponible');
      return;
    }

    if (this.hls) {
      this.hls.destroy();
      this.hls = null;
    }

    this.showPlayerLoading('Chargement du flux...');

    // Utiliser l'URL HLS du live
    const hlsUrl = stream.hlsUrl || stream.streamUrl;
    if (!hlsUrl) {
      this.showPlayerError('URL de flux non disponible');
      return;
    }

    console.log('HLS URL:', hlsUrl);

    // Charger HLS.js
    if (typeof Hls === 'undefined') {
      this.showPlayerError('hls.js non chargé');
      return;
    }

    if (Hls.isSupported()) {
      this.hls = new Hls({
        enableWorker: true,
        lowLatencyMode: true,
        backBufferLength: 90,
      });

      this.hls.loadSource(hlsUrl);
      this.hls.attachMedia(video);

      this.hls.on(Hls.Events.MANIFEST_PARSED, () => {
        console.log('HLS manifest chargé');
        this.hidePlayerOverlays();
        video.play().catch(err => {
          if (err.name !== 'AbortError') {
            console.warn('Autoplay bloqué:', err.message);
          }
        });
      });

      this.hls.on(Hls.Events.ERROR, (event, data) => {
        console.error('HLS error:', data);
        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              this.showPlayerError('Erreur réseau: impossible de charger le flux');
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              this.showPlayerError('Erreur média: format non supporté');
              break;
            default:
              this.showPlayerError('Erreur de lecture du flux');
              break;
          }
        }
      });

      this.hls.on(Hls.Events.FRAG_BUFFERED, () => {
        const qualityEl = document.getElementById('playerQuality');
        if (qualityEl) {
          const level = this.hls.levels[this.hls.currentLevel];
          if (level) {
            qualityEl.textContent = `${level.width}x${level.height}`;
          }
        }
      });
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Safari/iOS support natif HLS
      video.src = hlsUrl;
      video.addEventListener('loadedmetadata', () => {
        this.hidePlayerOverlays();
        video.play().catch(err => console.warn('Autoplay:', err));
      });
    } else {
      this.showPlayerError('HLS non supporté par ce navigateur');
    }
  },

  showPlayerLoading(message) {
    const overlay = document.getElementById('playerOverlayLoading');
    const error = document.getElementById('playerOverlayError');
    if (overlay) overlay.classList.remove('hidden');
    if (error) error.classList.add('hidden');
    const msg = overlay?.querySelector('.overlay-text');
    if (msg) msg.textContent = message;
  },

  showPlayerError(message) {
    const loading = document.getElementById('playerOverlayLoading');
    const error = document.getElementById('playerOverlayError');
    if (loading) loading.classList.add('hidden');
    if (error) error.classList.remove('hidden');
    const msg = document.getElementById('playerErrorMessage');
    if (msg) msg.textContent = message;
  },

  hidePlayerOverlays() {
    const loading = document.getElementById('playerOverlayLoading');
    const error = document.getElementById('playerOverlayError');
    if (loading) loading.classList.add('hidden');
    if (error) error.classList.add('hidden');
  },

  retryPlayer() {
    this.initPlayer();
  },

  closePlayer() {
    this.isPlayerActive = false;
    if (this.hls) {
      this.hls.destroy();
      this.hls = null;
    }
    const video = document.getElementById('liveVideoPlayer');
    if (video) {
      video.pause();
      video.src = '';
      video.load();
    }
    const stream = Store.state.activeLive;
    if (stream) {
      API.leaveLive(stream.id).catch(() => {});
    }
    this.renderContent(document.getElementById('page-live'));
  },

  destroy() {
    this.closePlayer();
    this.stopPolling();
  },
};
