const LibraryPage = {
  currentTab: 0,
  searchQuery: '',
  selectedYear: null,
  selectedMonth: null,
  selectedCategory: null,
  availableYears: [],
  availableMonths: [],
  availableCategories: [],
  tabs: ['Tous', 'Packs'],

  packsIndex() { return this.tabs.length - 1; },
  isPacksTab() { return this.currentTab === this.packsIndex(); },

  async render(params) {
    const el = document.getElementById('page-library');
    const s = Store.state;

    // Onglets dynamiques : 'Tous' + types de culte réellement présents + 'Packs'
    this.tabs = ['Tous', ...Store.getTypeCultes(), 'Packs'];
    if (this.currentTab >= this.tabs.length) this.currentTab = 0;

    if (params?.category) {
      this.selectedYear = null;
      this.selectedMonth = null;
      this.searchQuery = '';
    }

    if (params?.typeCulte) {
      const idx = this.tabs.findIndex(t => t.toLowerCase() === params.typeCulte.toLowerCase());
      if (idx !== -1) {
        this.currentTab = idx;
      }
      this.selectedYear = null;
      this.selectedMonth = null;
      this.searchQuery = '';
    }

    this.availableYears = ['Tout', ...new Set(s.teachings.map(t => t.annee).filter(Boolean))];
    this.availableMonths = ['Tout', ...new Set(s.teachings.map(t => t.mois).filter(Boolean))];
    this.availableCategories = s.categories || API.getCategories(s.teachings);

    const tabs = this.tabs;

    if (s.isLoading && !s.teachings.length) {
      el.innerHTML = this.renderSkeleton(tabs);
      return;
    }

    el.innerHTML = `
      <div class="page-header">
        <h1>Bibliothèque</h1>
        <p>Enseignements et ressources</p>
      </div>

      ${s.isOffline ? `
        <div class="offline-banner">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <span>Mode hors ligne — seuls les téléchargements disponibles</span>
        </div>
      ` : ''}

      <div class="tabs">
        ${tabs.map((t, i) => `
          <button class="tab ${this.currentTab === i ? 'active' : ''}" onclick="LibraryPage.switchTab(${i})">${t}</button>
        `).join('')}
      </div>

      ${!this.isPacksTab() ? `
        <div class="search-bar">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" id="library-search" placeholder="Rechercher un enseignement..." value="${this.searchQuery}" oninput="LibraryPage.onSearch(this.value)">
          <button class="search-clear ${this.searchQuery ? 'visible' : ''}" onclick="LibraryPage.clearSearch()">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        ${this.availableCategories.length ? `
        <div class="filter-row">
          <div class="filter-pill ${!this.selectedCategory ? 'active' : ''}" onclick="LibraryPage.filterCategory(null)">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/></svg>
            Toutes catégories
          </div>
          ${this.availableCategories.map(c => `
            <div class="filter-pill ${c === this.selectedCategory ? 'active' : ''}" onclick="LibraryPage.filterCategory('${c.replace(/'/g, "\\'")}')">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/></svg>
              ${c}
            </div>
          `).join('')}
        </div>
        ` : ''}

        <div class="filter-row">
          ${this.availableYears.map(y => `
            <div class="filter-pill ${(y === 'Tout' && !this.selectedYear) || y === this.selectedYear ? 'active' : ''}" onclick="LibraryPage.filterYear('${y}')">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
              ${y}
            </div>
          `).join('')}
        </div>

        <div class="filter-row">
          ${this.availableMonths.map(m => `
            <div class="filter-pill ${(m === 'Tout' && !this.selectedMonth) || m === this.selectedMonth ? 'active' : ''}" onclick="LibraryPage.filterMonth('${m}')">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
              ${m}
            </div>
          `).join('')}
        </div>
      ` : ''}

      <div id="library-content">
        ${this.renderContent()}
      </div>
    `;
  },

  switchTab(index) {
    this.currentTab = index;
    this.render();
  },

  filterYear(year) {
    this.selectedYear = year === 'Tout' ? null : year;
    document.getElementById('library-content').innerHTML = this.renderContent();
    // Update pill styles
    document.querySelectorAll('.filter-row:first-child .filter-pill').forEach(pill => {
      pill.classList.toggle('active', pill.textContent.trim() === year || (!this.selectedYear && pill.textContent.trim() === 'Tout'));
    });
  },

  filterMonth(month) {
    this.selectedMonth = month === 'Tout' ? null : month;
    document.getElementById('library-content').innerHTML = this.renderContent();
    document.querySelectorAll('.filter-row:last-child .filter-pill').forEach(pill => {
      pill.classList.toggle('active', pill.textContent.trim() === month || (!this.selectedMonth && pill.textContent.trim() === 'Tout'));
    });
  },

  filterCategory(category) {
    this.selectedCategory = category;
    this.render();
  },

  onSearch(value) {
    this.searchQuery = value;
    const clearBtn = document.querySelector('.search-clear');
    if (clearBtn) clearBtn.classList.toggle('visible', value.length > 0);
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      document.getElementById('library-content').innerHTML = this.renderContent();
    }, 300);
  },

  clearSearch() {
    this.searchQuery = '';
    const input = document.getElementById('library-search');
    if (input) input.value = '';
    document.querySelector('.search-clear')?.classList.remove('visible');
    document.getElementById('library-content').innerHTML = this.renderContent();
  },

  renderSkeleton(tabs) {
    return `
      <div class="page-header">
        <h1>Bibliothèque</h1>
        <p>Enseignements et ressources</p>
      </div>
      <div class="tabs" style="opacity:0.6;pointer-events:none;">
        ${tabs.map(t => `<div class="skeleton" style="padding:8px 16px;border-radius:10px;height:16px;width:120px;"></div>`).join('')}
      </div>
      ${Array(5).fill(Skeleton.teachingListItem()).join('')}
    `;
  },

  renderContent() {
    const s = Store.state;
    let teachings = [];

    if (this.currentTab === 0) {
      teachings = [...s.teachings];
    } else if (this.isPacksTab()) {
      return this.renderPacksTab();
    } else {
      const label = this.tabs[this.currentTab] || '';
      teachings = s.teachings.filter(t =>
        (t.typeCulte || '').toLowerCase() === label.toLowerCase()
      );
    }

    // Apply filters
    if (this.selectedCategory) {
      teachings = teachings.filter(t => (t.category || '').toLowerCase() === this.selectedCategory.toLowerCase());
    }
    if (this.selectedYear) {
      teachings = teachings.filter(t => t.annee === this.selectedYear);
    }
    if (this.selectedMonth) {
      teachings = teachings.filter(t => t.mois === this.selectedMonth);
    }
    if (this.searchQuery) {
      teachings = Store.searchTeachings(teachings, this.searchQuery);
    }

    teachings.sort((a, b) => {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      if (a.isNew && !b.isNew) return -1;
      if (!a.isNew && b.isNew) return 1;
      return new Date(b.publishedAt) - new Date(a.publishedAt);
    });

    if (!teachings.length) {
      const hasFilters = this.searchQuery || this.selectedYear || this.selectedMonth;
      return `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
          </svg>
          <h3>Aucun enseignement trouvé</h3>
          <p>Essayez de modifier vos filtres de recherche.</p>
        </div>
      `;
    }

    return `
      <div class="teaching-list">
        ${teachings.map(t => this.renderListItem(t)).join('')}
      </div>
    `;
  },

  renderListItem(teaching) {
    const isFav = Store.isFavorite(teaching.id);
    const isDl = Store.isDownloaded(teaching.id);
    return `
      <div class="teaching-list-item" onclick="Store.playTeaching(Store.getTeachingById('${teaching.id}'), Store.state.teachings)">
        <button class="dl-btn ${isDl ? 'active' : ''}" onclick="event.stopPropagation();App.handleDownload(this, '${teaching.id}')" title="${isDl ? 'Retirer des téléchargements' : 'Télécharger'}" style="position:static;opacity:1;flex-shrink:0;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <div class="dl-spinner"></div>
        </button>
        <button class="fav-btn ${isFav ? 'active' : ''}" onclick="event.stopPropagation();Store.toggleFavorite('${teaching.id}');this.classList.toggle('active');" title="Favori">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="${isFav ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2"><path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
        </button>
        <div class="item-artwork">
          ${teaching.artworkUrl ? `<img src="${teaching.artworkUrl}" alt="" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
          <div class="artwork-fallback" style="${teaching.artworkUrl ? 'display:none' : ''}">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
          </div>
        </div>
        <div class="item-info">
          <p class="item-title">${teaching.title}${teaching.isFeatured ? '<span class="badge-featured" title="Mis en avant">★</span>' : ''}${teaching.isNew ? '<span class="badge-new">NEW</span>' : ''}</p>
          <p class="item-meta">${teaching.speaker} · ${teaching.category}</p>
        </div>
        <span class="item-duration">${Store.formatDuration(teaching.duration)}</span>
        <button class="add-pkg-btn" onclick="event.stopPropagation();App.showAddToPackageModal('${teaching.id}')" title="Ajouter à un pack" style="position:static;opacity:1;margin-left:8px;flex-shrink:0;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        </button>
      </div>
    `;
  },

  pkgMenuId: null,

  togglePkgMenu(pkgId) {
    this.pkgMenuId = this.pkgMenuId === pkgId ? null : pkgId;
    const el = document.getElementById('library-content');
    if (el) el.innerHTML = this.renderContent();
  },

  openPackage(pkgId) {
    this.pkgMenuId = null;
    HomePage.viewingPackageId = pkgId;
    App.navigate('home');
  },

  renamePackage(pkgId) {
    this.pkgMenuId = null;
    HomePage.viewingPackageId = pkgId;
    HomePage.editingPackageId = pkgId;
    App.navigate('home');
  },

  confirmDeletePackage(pkgId) {
    this.pkgMenuId = null;
    const pkg = Store.getPackageById(pkgId);
    if (!pkg) return;
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.innerHTML = `
      <div class="modal" style="max-width:380px;animation:menuAppear 0.25s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;">
        <h3 style="margin:0 0 8px;">Supprimer ce pack ?</h3>
        <p style="color:var(--text-secondary);font-size:14px;margin:0 0 16px;">« ${pkg.name} » sera supprimé. Les enseignements restent dans la bibliothèque.</p>
        <div class="modal-actions">
          <button class="modal-btn secondary" id="pkg-del-cancel">Annuler</button>
          <button class="modal-btn danger" id="pkg-del-confirm">Supprimer</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.querySelector('#pkg-del-cancel').onclick = () => overlay.remove();
    overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
    overlay.querySelector('#pkg-del-confirm').onclick = () => {
      overlay.remove();
      Store.deletePackage(pkgId);
      App.showToast(`Pack « ${pkg.name} » supprimé`);
      const el = document.getElementById('library-content');
      if (el) el.innerHTML = this.renderContent();
    };
  },

  _packThumb(teaching, i, count) {
    // Positions façon "dossier gallery" : éventail de vignettes
    const totalSpread = 160;
    const step = count > 1 ? totalSpread / (count - 1) : 0;
    const x = count > 1 ? -totalSpread / 2 + step * i : 0;
    const norm = count > 1 ? (i / (count - 1)) * 2 - 1 : 0;
    const rotate = norm * 10;
    const center = (count - 1) / 2;
    const d = Math.abs(i - center) * (count > 1 ? 2 / (count - 1) : 0); // 0 centre → 1 extrémité
    const dLevel = d === 0 ? 0 : d <= 0.5 ? 1 : 2;
    const zIndex = 10 - Math.round(d * 10);
    const brightness = dLevel === 0 ? 1 : dLevel === 1 ? 0.55 : 0.3;
    const blur = dLevel === 0 ? 0 : dLevel === 1 ? 0.5 : 1.5;
    const scale = dLevel === 0 ? 1.05 : dLevel === 1 ? 0.95 : 0.88;
    const yOff = -16 * (1 - Math.min(d, 2) / 2);
    const y = 10 + yOff;
    const xh = x * 1.4, yh = -8 + yOff, rh = rotate * 1.3;
    const cover = teaching?.artworkUrl || '';
    return `
      <div class="pack-thumb" style="--x:${x}px;--y:${y}px;--r:${rotate}deg;--s:${scale};--z:${zIndex};--b:${brightness};--f:${blur}px;--xh:${xh}px;--yh:${yh}px;--rh:${rh}deg;">
        ${cover
          ? `<img src="${cover}" alt="" loading="lazy" onerror="this.parentElement.classList.add('no-img');this.remove()">`
          : `<div class="pack-thumb-fallback"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg></div>`}
      </div>
    `;
  },

  renderPackCard(pkg) {
    const teachings = Store.getTeachingsInPackage(pkg.id);
    const count = teachings.length;
    const n = Math.min(Math.max(count, 1), 5);
    const thumbs = Array.from({ length: n }, (_, i) => this._packThumb(teachings.length ? teachings[i % count] : null, i, n)).join('');
    const date = pkg.createdAt ? new Date(pkg.createdAt) : null;
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'];
    const dateLabel = date ? `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}` : '';
    const isMenuOpen = this.pkgMenuId === pkg.id;

    return `
      <div class="pack-folder ${isMenuOpen ? 'menu-open' : ''}" onclick="LibraryPage.openPackage('${pkg.id}')">
        <div class="pack-folder-back">
          <div class="pack-folder-thumbs">${thumbs}</div>
          ${!count ? `<div class="pack-folder-empty"><svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg></div>` : ''}
        </div>
        <div class="pack-folder-front">
          <h3 class="pack-folder-title">${pkg.name}</h3>
          <div class="pack-folder-footer">
            <span class="pack-folder-count"><b>${count}</b>&nbsp;audio${count !== 1 ? 's' : ''}</span>
            <div class="pack-folder-right">
              <span class="pack-folder-date">${dateLabel}</span>
              <button class="pack-folder-menu-btn" onclick="event.stopPropagation();LibraryPage.togglePkgMenu('${pkg.id}')" title="Options">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="5" r="1.5" fill="currentColor"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><circle cx="12" cy="19" r="1.5" fill="currentColor"/></svg>
              </button>
              ${isMenuOpen ? `
                <div class="dropdown-menu pack-folder-menu" onclick="event.stopPropagation()">
                  <button class="dropdown-menu-item" onclick="LibraryPage.openPackage('${pkg.id}')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    Ouvrir
                  </button>
                  <button class="dropdown-menu-item" onclick="LibraryPage.renamePackage('${pkg.id}')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                    Renommer
                  </button>
                  <button class="dropdown-menu-item danger" onclick="LibraryPage.confirmDeletePackage('${pkg.id}')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
                    Supprimer
                  </button>
                </div>
              ` : ''}
            </div>
          </div>
        </div>
      </div>
    `;
  },

  renderPacksTab() {
    const s = Store.state;
    const packages = s.favoritePackages || [];
    return `
      <div class="pack-folders-grid" style="padding-top:16px;">
        ${packages.map(p => this.renderPackCard(p)).join('')}
        <div class="pack-folder pack-folder-new" onclick="App.showCreatePackageModal('')">
          <div class="pack-folder-new-inner">
            <div class="pack-folder-new-icon">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            </div>
            <span>Nouveau pack</span>
          </div>
        </div>
      </div>
    `;
  },

};
