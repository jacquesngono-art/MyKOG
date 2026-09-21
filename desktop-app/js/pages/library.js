const LibraryPage = {
  currentTab: 0,
  searchQuery: '',
  selectedYear: null,
  selectedMonth: null,
  availableYears: [],
  availableMonths: [],

  async render(params) {
    const el = document.getElementById('page-library');
    const s = Store.state;

    if (params?.category) {
      this.selectedYear = null;
      this.selectedMonth = null;
      this.searchQuery = '';
    }

    if (params?.typeCulte) {
      const types = ["Culte d'Impact", 'Culte Prophétique', "Culte d'Enseignement", 'Conférence', 'Séminaire'];
      const idx = types.findIndex(t => t.toLowerCase() === params.typeCulte.toLowerCase());
      if (idx !== -1) {
        this.currentTab = idx + 1;
      }
      this.selectedYear = null;
      this.selectedMonth = null;
      this.searchQuery = '';
    }

    this.availableYears = ['Tout', ...new Set(s.teachings.map(t => t.annee).filter(Boolean))];
    this.availableMonths = ['Tout', ...new Set(s.teachings.map(t => t.mois).filter(Boolean))];

    const tabs = ['Tous', "Culte d'Impact", 'Culte Prophétique', "Culte d'Enseignement", 'Conférence', 'Séminaire', 'Téléchargements', 'Packs'];

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

      ${this.currentTab !== 5 ? `
        <div class="search-bar">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <input type="text" id="library-search" placeholder="Rechercher un enseignement..." value="${this.searchQuery}" oninput="LibraryPage.onSearch(this.value)">
          <button class="search-clear ${this.searchQuery ? 'visible' : ''}" onclick="LibraryPage.clearSearch()">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

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
    } else if (this.currentTab === 6) {
      teachings = Store.getDownloadedTeachings();
    } else if (this.currentTab === 7) {
      return this.renderPacksTab();
    } else {
      const types = ["Culte d'Impact", 'Culte Prophétique', "Culte d'Enseignement", 'Conférence', 'Séminaire'];
      teachings = s.teachings.filter(t =>
        t.typeCulte?.toLowerCase() === types[this.currentTab - 1]?.toLowerCase()
      );
    }

    // Apply filters
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
      const isDl = this.currentTab === 4;
      return `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            ${isDl && !hasFilters ? '<path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>' : '<circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>'}
          </svg>
          <h3>${isDl && !hasFilters ? 'Aucun téléchargement' : 'Aucun enseignement trouvé'}</h3>
          <p>${isDl && !hasFilters ? 'Téléchargez des enseignements pour les écouter hors ligne.' : 'Essayez de modifier vos filtres de recherche.'}</p>
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
          <p class="item-title">${teaching.title}</p>
          <p class="item-meta">${teaching.speaker} · ${teaching.category}</p>
        </div>
        <span class="item-duration">${Store.formatDuration(teaching.duration)}</span>
        <button class="add-pkg-btn" onclick="event.stopPropagation();App.showAddToPackageModal('${teaching.id}')" title="Ajouter à un pack" style="position:static;opacity:1;margin-left:8px;flex-shrink:0;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        </button>
      </div>
    `;
  },

  renderPacksTab() {
    const s = Store.state;
    const packages = s.favoritePackages || [];
    if (packages.length === 0) {
      return `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
          <h3>Aucun pack</h3>
          <p>Créez des packs pour organiser vos enseignements favoris.</p>
          <button class="watch-btn" style="width:auto;margin-top:16px;padding:10px 24px;" onclick="App.showCreatePackageModal('')">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Créer un pack
          </button>
        </div>
      `;
    }
    return `
      <div class="package-grid" style="padding-top:16px;">
        ${packages.map(p => `
          <div class="glass-card package-card" onclick="HomePage.viewingPackageId='${p.id}';App.navigate('home')" style="position:relative;">
            <div class="package-icon">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
            </div>
            <span class="package-name">${p.name}</span>
            <span class="package-count">${p.teachingIds.length} enseignement${p.teachingIds.length !== 1 ? 's' : ''}</span>
          </div>
        `).join('')}
        <div class="glass-card create-pkg-card" onclick="App.showCreatePackageModal('')">
          <div class="create-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          </div>
          <span class="create-text">Nouveau pack</span>
        </div>
      </div>
    `;
  },

};
