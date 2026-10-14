const App = {
  currentPage: 'login',
  loadingTimeout: null,
  _navTimeout: null,
  _visitedPages: new Set(),

  async init() {
    this.setupLoadingScreen();
    this.setupSidebar();
    this.setupAudioPlayer();

    Store.initAudio();
    await Store.initialize();
    Notifications.init();

    document.addEventListener('click', (e) => {
      if (!e.target.closest('.dropdown-menu') && !e.target.closest('.more-btn')) {
        HomePage.closeDropdownMenus?.();
      }
    });

    Store.subscribe((state) => {
      const btn = document.getElementById('retry-btn');
      if (btn) {
        btn.classList.toggle('visible', state.isOffline && state.isLoggedIn);
      }
    });

    // Refresh unitaire des composants packs (sans recharger toute la page)
    Store.subscribe((state, changedKeys) => {
      if (changedKeys && changedKeys.includes('favoritePackages')) {
        this.refreshPackUI();
      }
    });

    window.addEventListener('online', () => {
      Store.setState({ isOffline: false });
      App.showToast('Connexion r\u00e9tablie');
      const btn = document.getElementById('retry-btn');
      if (btn) btn.classList.remove('visible');
    });
    window.addEventListener('offline', () => {
      Store.setState({ isOffline: true });
      App.showToast('Mode hors ligne activ\u00e9');
    });

    setTimeout(() => {
      this.hideLoadingScreen();
      if (OnboardingPage.isCompleted()) {
        this.afterOnboarding();
      } else {
        OnboardingPage.show();
      }
    }, 2500);
  },

  afterOnboarding() {
    const target = Store.state.isLoggedIn ? 'home' : 'login';
    this.navigate(target);
    if (Store.state.isLoggedIn) Store.startPolling();
    if (Store.state.isOffline && Store.state.isLoggedIn) {
      this.showToast('Mode hors ligne \u2014 contenu limit\u00e9');
    }
  },

  setupLoadingScreen() {
    const texts = document.querySelectorAll('.loading-text');
    let index = 0;
    setInterval(() => {
      texts.forEach(t => t.classList.remove('active'));
      index = (index + 1) % texts.length;
      texts[index].classList.add('active');
    }, 2000);
  },

  hideLoadingScreen() {
    const screen = document.getElementById('loading-screen');
    screen.classList.add('hidden');
    setTimeout(() => screen.remove(), 600);
  },

  setupSidebar() {
    document.querySelectorAll('.nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const page = item.dataset.page;
        if (page) this.navigate(page);
      });
    });
  },

  navigate(page, params) {
    if (this._navTimeout) { clearTimeout(this._navTimeout); this._navTimeout = null; }

    if (page !== 'login' && !Store.state.isLoggedIn) {
      page = 'login';
    }

    this.currentPage = page;

    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const navItem = document.querySelector(`.nav-item[data-page="${page}"]`);
    if (navItem) navItem.classList.add('active');

    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    const pageEl = document.getElementById(`page-${page}`);
    if (!pageEl) return;
    pageEl.classList.add('active');

    if (page === 'login') {
      LoginPage.reset();
      LoginPage.render();
      return;
    }

    if (!this._visitedPages.has(page)) {
      this._visitedPages.add(page);
      this._renderSkeleton(page, pageEl);
      this._navTimeout = setTimeout(() => {
        this._navTimeout = null;
        this._renderContent(page, params);
      }, 800);
    } else {
      this._renderContent(page, params);
    }
  },

  _renderSkeleton(page, el) {
    switch (page) {
      case 'home':
        el.innerHTML = HomePage.renderSkeleton(Store.state.user || { name: '' }, 'Bonjour');
        break;
      case 'browse':
        el.innerHTML = BrowsePage.renderSkeleton();
        break;
      case 'live':
        el.innerHTML = LivePage.renderSkeleton();
        break;
      case 'library':
        el.innerHTML = LibraryPage.renderSkeleton(['Tous', ...Store.getTypeCultes(), 'Packs']);
        break;
      case 'downloads':
        el.innerHTML = `${Skeleton.pageHeader()}${Array(5).fill(Skeleton.teachingListItem()).join('')}`;
        break;
      case 'resumes':
        el.innerHTML = `${Skeleton.pageHeader()}${Skeleton.resumeList(4)}`;
        break;
      case 'profile':
        el.innerHTML = `
          <div class="page-header"><h1>Profil</h1><p>Votre compte MyKOG</p></div>
          <div style="display:flex;flex-direction:column;align-items:center;padding:40px;gap:16px;">
            <div class="skeleton" style="width:80px;height:80px;border-radius:50%;"></div>
            <div class="skeleton" style="width:150px;height:20px;"></div>
            <div class="skeleton" style="width:100px;height:14px;"></div>
            <div class="skeleton" style="width:200px;height:14px;"></div>
          </div>
          ${Skeleton.profileStats()}
        `;
        break;
      case 'calendar':
        el.innerHTML = `${Skeleton.pageHeader()}${Skeleton.eventList(4)}`;
        break;
    }
  },

  _renderContent(page, params) {
    switch (page) {
      case 'home': HomePage.render(); break;
      case 'browse': BrowsePage.render(); break;
      case 'live': LivePage.render(); break;
      case 'library': LibraryPage.render(params); break;
      case 'downloads': DownloadsPage.render(); break;
      case 'profile': ProfilePage.render(); break;
      case 'calendar': CalendarPage.render(); break;
      case 'resumes': ResumesPage.render(); break;
    }
  },

  reRenderCurrentPage() {
    this._renderContent(this.currentPage);
  },

  setupAudioPlayer() {
    Store.subscribe((state) => {
      const audio = state.audioPlayer;
      if (audio.currentTeaching) {
        this.updatePlayerUI(audio);
      }
    });

    document.getElementById('player-play')?.addEventListener('click', () => {
      Store.togglePlayPause();
    });

    document.getElementById('player-next')?.addEventListener('click', () => {
      Store.nextTrack();
    });

    document.getElementById('player-prev')?.addEventListener('click', () => {
      Store.prevTrack();
    });

    document.getElementById('progress-bar')?.addEventListener('click', (e) => {
      const rect = e.currentTarget.getBoundingClientRect();
      const x = e.clientX - rect.left;
      Store.seekTo(x / rect.width);
    });
  },

  updatePlayerUI(audio) {
    const player = document.getElementById('mini-player');
    if (!player) return;
    player.classList.remove('hidden');

    document.getElementById('player-title').textContent = audio.currentTeaching.title;
    document.getElementById('player-speaker').textContent = audio.currentTeaching.speaker;

    const artImg = document.getElementById('player-artwork-img');
    const artFallback = document.getElementById('player-artwork-fallback');
    if (audio.currentTeaching.artworkUrl) {
      artImg.src = audio.currentTeaching.artworkUrl;
      artImg.style.display = 'block';
      artFallback.style.display = 'none';
    } else {
      artImg.style.display = 'none';
      artFallback.style.display = 'flex';
    }

    const playBtn = document.getElementById('player-play');
    playBtn.innerHTML = audio.isPlaying
      ? '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>'
      : '<svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';

    document.getElementById('progress-fill').style.width = `${audio.duration > 0 ? (audio.currentTime / audio.duration) * 100 : 0}%`;
    document.getElementById('current-time').textContent = Store.formatDuration(audio.currentTime);
    document.getElementById('total-time').textContent = Store.formatDuration(audio.duration);
  },

  toggleTheme() {
    const isDark = !Store.state.isDarkMode;
    Store.setState({ isDarkMode: isDark });
    document.body.classList.toggle('light-mode', !isDark);
    localStorage.setItem('mykog_theme', isDark ? 'dark' : 'light');
  },

  // Met à jour uniquement les composants liés aux packs (accueil + onglet Packs)
  refreshPackUI() {
    const homeEl = document.getElementById('page-home');
    if (this.currentPage === 'home' && homeEl && homeEl.classList.contains('active')) {
      if (HomePage.viewingPackageId) {
        if (Store.getPackageById(HomePage.viewingPackageId)) {
          HomePage.renderPackageDetail(HomePage.viewingPackageId);
        } else {
          HomePage.viewingPackageId = null;
          HomePage.render();
        }
      } else {
        const sec = homeEl.querySelector('#home-packs-section');
        if (sec) sec.innerHTML = HomePage.renderPacksSection();
      }
    }

    if (this.currentPage === 'library' && LibraryPage.isPacksTab()) {
      const content = document.getElementById('library-content');
      if (content) content.innerHTML = LibraryPage.renderContent();
    }
  },

  // --- Package modals ---

  showAddToPackageModal(teachingId) {
    const s = Store.state;
    const teaching = Store.getTeachingById(teachingId);
    if (!teaching) return;

    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.dataset.teachingId = teachingId;
    overlay.innerHTML = `
      <div class="modal" style="animation:menuAppear 0.25s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;max-height:80vh;display:flex;flex-direction:column;">
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px;">
          <div style="width:40px;height:40px;border-radius:10px;background:var(--bg-secondary);display:flex;align-items:center;justify-content:center;color:var(--accent);flex-shrink:0;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
          </div>
          <div style="flex:1;min-width:0;">
            <h3 style="margin-bottom:2px;font-size:16px;">Ajouter \u00e0 un pack</h3>
            <p style="color:var(--text-secondary);font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${teaching.title} \u2014 ${teaching.speaker}</p>
          </div>
        </div>
        <div class="pkg-select-list" id="pkg-select-list" style="flex:1;overflow-y:auto;">
          ${(s.favoritePackages || []).length === 0 ? '<p style="color:var(--text-tertiary);text-align:center;padding:24px 0;font-size:14px;">Aucun pack. Cr\u00e9ez-en un !</p>' : ''}
          ${(s.favoritePackages || []).map((p, i) => `
            <div class="pkg-select-item" data-pkg-id="${p.id}" onclick="App.togglePkgSelection('${teachingId}', '${p.id}')" style="animation:fadeSlideIn 0.25s ease-out ${i * 0.04}s both;">
              <div class="pkg-sel-icon">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
              </div>
              <span class="pkg-sel-name">${p.name}</span>
              <span class="pkg-sel-check" style="visibility:${Store.isTeachingInPackage(p.id, teachingId) ? 'visible' : 'hidden'};display:flex;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
              </span>
            </div>
          `).join('')}
        </div>
        <div class="modal-actions" style="justify-content:space-between;margin-top:12px;padding-top:12px;border-top:1px solid rgba(255,255,255,0.06);flex-shrink:0;">
          <button class="modal-btn secondary" onclick="App.showCreatePackageModal('${teachingId}')" style="color:var(--accent);display:flex;align-items:center;gap:6px;">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Nouveau pack
          </button>
          <div style="display:flex;gap:8px;">
            <button class="modal-btn secondary" onclick="this.closest('.modal-overlay').remove()">Fermer</button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  },

  togglePkgSelection(teachingId, pkgId) {
    if (Store.isTeachingInPackage(pkgId, teachingId)) {
      Store.removeTeachingFromPackage(pkgId, teachingId);
    } else {
      Store.addTeachingToPackage(pkgId, teachingId);
    }
    const checks = document.querySelectorAll('.pkg-select-item');
    checks.forEach(el => {
      const check = el.querySelector('.pkg-sel-check');
      if (el.dataset.pkgId === pkgId) {
        check.style.visibility = Store.isTeachingInPackage(pkgId, teachingId) ? 'visible' : 'hidden';
      } else {
        check.style.visibility = Store.isTeachingInPackage(el.dataset.pkgId, teachingId) ? 'visible' : 'hidden';
      }
    });
  },

  _newPkgSelected: new Set(),
  _newPkgSearch: '',
  _newPkgType: null,

  showCreatePackageModal(afterAddTeachingId) {
    this._newPkgSelected = new Set(afterAddTeachingId ? [afterAddTeachingId] : []);
    this._newPkgSearch = '';
    this._newPkgType = null;
    const typeCultes = Store.getTypeCultes() || [];

    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.innerHTML = `
      <div class="modal" style="animation:menuAppear 0.25s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;max-width:560px;width:calc(100% - 32px);max-height:88vh;display:flex;flex-direction:column;">
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:8px;flex-shrink:0;">
          <div style="width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,var(--accent),var(--accent-light));display:flex;align-items:center;justify-content:center;color:white;flex-shrink:0;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/><line x1="12" y1="11" x2="12" y2="17"/><line x1="9" y1="14" x2="15" y2="14"/></svg>
          </div>
          <h3 style="font-size:18px;margin-bottom:0;">Nouveau pack</h3>
        </div>
        <label style="display:block;font-size:13px;color:var(--text-secondary);margin-bottom:6px;flex-shrink:0;">Nom du pack</label>
        <input type="text" id="new-pkg-name" placeholder="Ex: Enseignements puissants" maxlength="50" style="width:100%;padding:10px 14px;background:var(--bg-secondary);border:1px solid rgba(255,255,255,0.1);border-radius:10px;color:var(--text-primary);font-size:14px;font-family:'Inter',sans-serif;margin-bottom:12px;outline:none;transition:var(--transition);flex-shrink:0;">
        <label style="display:block;font-size:13px;color:var(--text-secondary);margin-bottom:6px;flex-shrink:0;">Description <span style="color:var(--text-tertiary);">(optionnelle)</span></label>
        <input type="text" id="new-pkg-desc" placeholder="Une courte description..." maxlength="100" style="width:100%;padding:10px 14px;background:var(--bg-secondary);border:1px solid rgba(255,255,255,0.1);border-radius:10px;color:var(--text-primary);font-size:14px;font-family:'Inter',sans-serif;margin-bottom:14px;outline:none;transition:var(--transition);flex-shrink:0;">

        <label style="display:block;font-size:13px;color:var(--text-secondary);margin-bottom:6px;flex-shrink:0;">Ajouter des enseignements</label>
        <div class="search-bar" style="margin:0 0 10px;padding:8px 12px;flex-shrink:0;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" id="new-pkg-search" placeholder="Rechercher un enseignement..." style="font-size:13px;">
        </div>
        ${typeCultes.length ? `
          <div class="filter-row" id="new-pkg-types" style="padding:0;margin-bottom:10px;flex-shrink:0;">
            <div class="filter-pill active" data-type="">Tous</div>
            ${typeCultes.map(t => `<div class="filter-pill" data-type="${t}">${t}</div>`).join('')}
          </div>
        ` : ''}
        <div class="pkg-select-list" id="new-pkg-list" style="flex:1;overflow-y:auto;min-height:120px;margin-bottom:0;">
          ${this._renderNewPkgList()}
        </div>

        <div class="modal-actions" style="padding-top:14px;flex-shrink:0;border-top:1px solid rgba(255,255,255,0.06);margin-top:12px;">
          <button class="modal-btn secondary" onclick="this.closest('.modal-overlay').remove()">Annuler</button>
          <button class="modal-btn primary" id="new-pkg-create" onclick="App.createPackage(this, '${afterAddTeachingId}')">Cr\u00e9er le pack</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });

    const searchInput = overlay.querySelector('#new-pkg-search');
    searchInput.addEventListener('input', () => {
      this._newPkgSearch = searchInput.value;
      overlay.querySelector('#new-pkg-list').innerHTML = this._renderNewPkgList();
    });
    overlay.querySelectorAll('#new-pkg-types .filter-pill').forEach(pill => {
      pill.addEventListener('click', () => {
        overlay.querySelectorAll('#new-pkg-types .filter-pill').forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        this._newPkgType = pill.dataset.type || null;
        overlay.querySelector('#new-pkg-list').innerHTML = this._renderNewPkgList();
      });
    });

    setTimeout(() => {
      const input = document.getElementById('new-pkg-name');
      if (input) input.focus();
    }, 100);
  },

  _renderNewPkgList() {
    let list = Store.state.teachings || [];
    if (this._newPkgType) {
      list = list.filter(t => (t.typeCulte || '').toLowerCase() === this._newPkgType.toLowerCase());
    }
    if (this._newPkgSearch.trim()) {
      list = Store.searchTeachings(list, this._newPkgSearch);
    }
    if (!list.length) {
      return '<p style="color:var(--text-tertiary);text-align:center;padding:24px 0;font-size:14px;">Aucun enseignement trouvé.</p>';
    }
    return list.map(t => `
      <div class="pkg-select-item" data-tid="${t.id}" onclick="App.toggleNewPkgTeaching('${t.id}')">
        <div class="pkg-sel-icon" style="overflow:hidden;padding:0;">
          ${t.artworkUrl
            ? `<img src="${t.artworkUrl}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:8px;" onerror="this.outerHTML='<svg width=&quot;18&quot; height=&quot;18&quot; viewBox=&quot;0 0 24 24&quot; fill=&quot;none&quot; stroke=&quot;currentColor&quot; stroke-width=&quot;2&quot;><path d=&quot;M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z&quot;/></svg>'">`
            : `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>`}
        </div>
        <div style="flex:1;min-width:0;">
          <span class="pkg-sel-name" style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${t.title}</span>
          <span style="font-size:11px;color:var(--text-tertiary);display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${t.speaker || ''}${t.typeCulte ? ' · ' + t.typeCulte : ''}</span>
        </div>
        <span class="pkg-sel-check" style="visibility:${this._newPkgSelected.has(t.id) ? 'visible' : 'hidden'};display:flex;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
        </span>
      </div>
    `).join('');
  },

  toggleNewPkgTeaching(teachingId) {
    if (this._newPkgSelected.has(teachingId)) {
      this._newPkgSelected.delete(teachingId);
    } else {
      this._newPkgSelected.add(teachingId);
    }
    const row = document.querySelector(`#new-pkg-list .pkg-select-item[data-tid="${teachingId}"]`);
    if (row) {
      const check = row.querySelector('.pkg-sel-check');
      if (check) check.style.visibility = this._newPkgSelected.has(teachingId) ? 'visible' : 'hidden';
    }
    const btn = document.getElementById('new-pkg-create');
    const n = this._newPkgSelected.size;
    if (btn) btn.textContent = n > 0 ? `Ajouter ${n} enseignement${n > 1 ? 's' : ''}` : 'Cr\u00e9er le pack';
  },

  createPackage(btn, afterAddTeachingId) {
    const name = document.getElementById('new-pkg-name')?.value.trim();
    if (!name) {
      document.getElementById('new-pkg-name')?.focus();
      return;
    }
    const desc = document.getElementById('new-pkg-desc')?.value.trim() || '';
    const pkg = Store.createPackage(name, desc);
    // Remplir le pack avec les enseignements sélectionnés
    this._newPkgSelected.forEach(id => Store.addTeachingToPackage(pkg.id, id));
    if (afterAddTeachingId && !this._newPkgSelected.has(afterAddTeachingId)) {
      Store.addTeachingToPackage(pkg.id, afterAddTeachingId);
    }
    // Ferme la modale de création (pas la modale "ajouter à un pack" en dessous)
    btn?.closest('.modal-overlay')?.remove();
    this.showToast(`Pack \u00ab ${name} \u00bb cr\u00e9\u00e9`);
    // Le refresh UI est géré par l'abonnement 'favoritePackages' (refreshPackUI)
  },

  handleDownload(btn, teachingId, cb) {
    if (btn.classList.contains('spinning')) return;
    btn.classList.add('spinning');
    setTimeout(() => {
      Store.toggleDownload(teachingId);
      btn.classList.remove('spinning');
      btn.classList.toggle('active');
      btn.title = Store.isDownloaded(teachingId) ? 'Retirer des téléchargements' : 'Télécharger';
      if (this.currentPage === 'downloads') DownloadsPage.render();
      if (cb) cb();
    }, 500);
  },

  _toastQueue: [],
  _toastActive: false,
  _toastBatchLen: 0,
  _toastBatchIdx: 0,

  showToast(message, duration = 60000) {
    this._toastQueue.push({ message, duration });
    if (!this._toastActive) {
      this._toastBatchLen = this._toastQueue.length;
      this._toastBatchIdx = 0;
      this._showNextToast();
    }
  },

  _showNextToast() {
    if (this._toastQueue.length === 0) {
      this._toastActive = false;
      return;
    }

    const item = this._toastQueue.shift();
    this._toastBatchIdx++;

    if (this._toastBatchIdx > this._toastBatchLen) {
      this._toastBatchLen = this._toastQueue.length + 1;
      this._toastBatchIdx = 1;
    }

    const { message, duration } = item;
    const counter = `${this._toastBatchIdx}/${this._toastBatchLen}`;
    const hasNext = this._toastQueue.length > 0;

    const toast = document.createElement('div');
    toast.className = 'toast';

    toast.innerHTML = `
      <img class="toast-logo" src="logo.png" alt="MyKOG">
      <span class="toast-text">${message}</span>
      <div class="toast-actions">
        <span class="toast-counter">${counter}</span>
        ${hasNext ? '<button class="toast-next" aria-label="Suivant"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><polyline points="9 18 15 12 9 6"/></svg></button>' : ''}
        <button class="toast-close" aria-label="Fermer">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
      <div class="toast-progress"></div>
    `;

    document.body.appendChild(toast);

    const closeBtn = toast.querySelector('.toast-close');
    const nextBtn = toast.querySelector('.toast-next');
    const progress = toast.querySelector('.toast-progress');

    const dismiss = () => this._dismissToast(toast);

    closeBtn.addEventListener('click', () => this._clearAllToasts());
    if (nextBtn) nextBtn.addEventListener('click', dismiss);

    requestAnimationFrame(() => {
      progress.style.transition = `width ${duration}ms linear`;
      progress.style.width = '0%';
    });

    this._toastTimer = setTimeout(dismiss, duration);
    this._toastActive = true;
  },

  _dismissToast(toast) {
    if (!toast || !toast.parentNode) return;
    clearTimeout(this._toastTimer);
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'opacity 0.3s, transform 0.3s ease';
    setTimeout(() => {
      toast.remove();
      this._showNextToast();
    }, 300);
  },

  _clearAllToasts() {
    clearTimeout(this._toastTimer);
    const current = document.querySelector('.toast');
    if (current) {
      current.style.opacity = '0';
      current.style.transform = 'translateX(100%)';
      current.style.transition = 'opacity 0.3s, transform 0.3s ease';
      setTimeout(() => current.remove(), 300);
    }
    this._toastQueue = [];
    this._toastActive = false;
  },
};

const PlayerUI = {
  show() {
    const audio = Store.state.audioPlayer;
    if (audio.currentTeaching) {
      App.updatePlayerUI(audio);
    }
  },
};

document.addEventListener('DOMContentLoaded', () => {
  App.init();
});
