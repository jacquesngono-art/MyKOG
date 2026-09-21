const BrowsePage = {
  searchQuery: '',
  expandedTeachingId: null,

  async render() {
    const el = document.getElementById('page-browse');
    const s = Store.state;

    el.innerHTML = `
      <div class="page-header">
        <h1>Découvrir</h1>
        <p>Explorez les enseignements</p>
      </div>
      ${this.renderSkeleton()}
    `;

    try {
      if (!s.teachings.length) await Store.loadTeachings();
      this.renderContent(el);
    } catch {
      this.renderContent(el);
    }
  },

  renderContent(el) {
    const s = Store.state;

    el.innerHTML = `
      <div class="page-header">
        <h1>Découvrir</h1>
        <p>Explorez les enseignements</p>
      </div>

      ${s.isOffline ? `
        <div class="offline-banner">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <span>Mode hors ligne — contenu limité aux téléchargements</span>
        </div>
      ` : ''}

      <div class="search-bar" style="margin-top: 16px;">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        <input type="text" id="browse-search" placeholder="Rechercher un enseignement..." value="${this.searchQuery}" oninput="BrowsePage.onSearch(this.value)">
        <button class="search-clear ${this.searchQuery ? 'visible' : ''}" onclick="BrowsePage.clearSearch()">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>

      <div id="browse-content">
        ${this.searchQuery ? this.renderSearchResults(s) : this.renderSections(s)}
      </div>
    `;
  },

  renderSections(s) {
    const recommended = Store.getRecommendedTeachings();
    const popular = Store.getPopularTeachings(6);
    const categories = s.categories;
    const typeCultes = s.typeCultes;
    const colors = ['#d4af37', '#1db954', '#3b82f6', '#8b5cf6', '#f59e0b', '#14b8a6'];

    const getIcon = (cat) => {
      const icons = {
        'foi': 'M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z',
        'priere': 'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z',
        'amour': 'M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z',
        'fondation': 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4',
      };
      const key = cat?.toLowerCase() || '';
      return icons[key] || 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253';
    };

    return `
      ${recommended.length ? `
        <div class="section-header" style="margin-top: 24px;">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="8.5" cy="7" r="4"/></svg>
          <h2>Recommandés pour vous</h2>
        </div>
        <div class="horizontal-list">
          ${recommended.map(t => BrowsePage.renderCard(t)).join('')}
        </div>
      ` : ''}

      ${popular.length ? `
        <div class="section-header" style="margin-top: 24px;">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
          <h2>Populaires cette semaine</h2>
        </div>
        <div class="horizontal-list">
          ${popular.map(t => BrowsePage.renderCard(t)).join('')}
        </div>
      ` : ''}

      ${typeCultes.length ? `
        <div class="section-header" style="margin-top: 24px;">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
          <h2>Cultes</h2>
        </div>
        <div class="category-grid">
          ${typeCultes.map((t, i) => {
            const culteColors = ['#d4af37', '#8b5cf6', '#3b82f6', '#1db954', '#f59e0b', '#14b8a6', '#e17055'];
            return `
              <div class="glass-card category-card" onclick="App.navigate('library', {typeCulte: '${t}'})">
                <div class="category-icon" style="background: ${culteColors[i % culteColors.length]}">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>
                </div>
                <span class="category-name">${t}</span>
              </div>
            `;
          }).join('')}
        </div>
      ` : ''}
      ${categories.length ? `
        <div class="section-header" style="margin-top: 24px;">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6h16M4 10h16M4 14h16M4 18h16"/></svg>
          <h2>Parcourir par catégorie</h2>
        </div>
        <div class="category-grid">
          ${categories.map((cat, i) => `
            <div class="glass-card category-card" onclick="App.navigate('library', {category: '${cat}'})">
              <div class="category-icon" style="background: ${colors[i % colors.length]}">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="${getIcon(cat)}"/></svg>
              </div>
              <span class="category-name">${cat}</span>
            </div>
          `).join('')}
        </div>
      ` : ''}
    `;
  },

  renderSearchResults(s) {
    const results = Store.searchTeachings(s.teachings, this.searchQuery);
    if (!results.length) {
      return `
        <div class="empty-state" style="margin-top: 32px;">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
          <h3>Aucun enseignement trouvé</h3>
          <p>Essayez de modifier votre recherche.</p>
        </div>
      `;
    }
    return `
      <div style="margin-top: 16px;">
        <p style="font-size:13px;color:var(--text-secondary);margin-bottom:12px;">${results.length} r\u00e9sultat(s) pour "${this.searchQuery}"</p>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;">
          ${results.map(t => BrowsePage.renderCard(t)).join('')}
        </div>
      </div>
    `;
  },

  onSearch(value) {
    this.searchQuery = value;
    const clearBtn = document.querySelector('.search-clear');
    if (clearBtn) clearBtn.classList.toggle('visible', value.length > 0);
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      const content = document.getElementById('browse-content');
      if (content) {
        content.innerHTML = this.searchQuery
          ? this.renderSearchResults(Store.state)
          : this.renderSections(Store.state);
      }
    }, 300);
  },

  clearSearch() {
    this.searchQuery = '';
    const input = document.getElementById('browse-search');
    if (input) input.value = '';
    document.querySelector('.search-clear')?.classList.remove('visible');
    const content = document.getElementById('browse-content');
    if (content) content.innerHTML = this.renderSections(Store.state);
  },

  renderSkeleton() {
    return `
      ${Skeleton.section('', Skeleton.horizontalList(4))}
      ${Skeleton.section('', Skeleton.horizontalList(4))}
      ${Skeleton.categoryGrid(6)}
    `;
  },

  renderCard(teaching) {
    const isFav = Store.isFavorite(teaching.id);
    const isDl = Store.isDownloaded(teaching.id);
    return `
      <div class="teaching-card browse-card" onclick="BrowsePage.expandCard(this, '${teaching.id}')">
        <div class="card-artwork">
          ${teaching.artworkUrl ? `<img src="${teaching.artworkUrl}" alt="" class="card-artwork-img" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
          <div class="artwork-fallback" style="${teaching.artworkUrl ? 'display:none' : ''}"><svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg></div>
          <button class="dl-btn ${isDl ? 'active' : ''}" onclick="event.stopPropagation();App.handleDownload(this, '${teaching.id}')" title="${isDl ? 'Retirer des téléchargements' : 'Télécharger'}">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            <div class="dl-spinner"></div>
          </button>
          <button class="fav-btn ${isFav ? 'active' : ''}" onclick="event.stopPropagation();Store.toggleFavorite('${teaching.id}');this.classList.toggle('active');" title="Favori">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="${isFav ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2"><path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
          </button>
          <button class="add-pkg-btn" onclick="event.stopPropagation();App.showAddToPackageModal('${teaching.id}')" title="Ajouter à un pack">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          </button>
          <div class="card-overlay"></div>
          <span class="play-count">${teaching.playCount || 0}</span>
        </div>
        <p class="card-title">${teaching.title}</p>
        <p class="card-speaker">${teaching.speaker}</p>
      </div>
    `;
  },

  // ---- Expansion plein écran (design "ExpandableCard") ----

  expandCard(cardEl, teachingId) {
    const teaching = Store.getTeachingById(teachingId);
    if (!teaching) return;

    if (document.getElementById('expanded-overlay')) return;
    this.expandedTeachingId = teachingId;

    // Lecture audio immédiate au clic (comportement d'origine conservé)
    Store.playTeaching(teaching, Store.state.teachings);

    const rect = cardEl.querySelector('.card-artwork').getBoundingClientRect();
    const isFav = Store.isFavorite(teachingId);
    const isDl = Store.isDownloaded(teachingId);

    const overlay = document.createElement('div');
    overlay.className = 'expanded-overlay';
    overlay.id = 'expanded-overlay';
    overlay.innerHTML = `
      <div class="expanded-card" id="expanded-card" style="top:${rect.top}px;left:${rect.left}px;width:${rect.width}px;height:${rect.height}px;">
        <div class="expanded-artwork">
          ${teaching.artworkUrl ? `<img src="${teaching.artworkUrl}" alt="" class="expanded-artwork-img" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
          <div class="expanded-artwork-fallback" style="${teaching.artworkUrl ? 'display:none' : ''}"><svg width="64" height="64" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg></div>
        </div>
        <div class="expanded-gradient"></div>
        <span class="expanded-play-count">${teaching.playCount || 0}</span>
        <button class="expanded-close" onclick="event.stopPropagation();BrowsePage.closeExpanded()" title="Fermer">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
        <div class="expanded-content">
          <div class="expanded-info">
            <h2 class="expanded-title">${teaching.title}</h2>
            <p class="expanded-speaker">${teaching.speaker}</p>
          </div>
          <div class="expanded-actions">
            <button class="expanded-play-btn" onclick="event.stopPropagation();Store.playTeaching(Store.getTeachingById('${teaching.id}'), Store.state.teachings);BrowsePage.closeExpanded()" title="Écouter">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
            </button>
            <button class="expanded-action-btn ${isFav ? 'active' : ''}" id="expanded-fav" onclick="event.stopPropagation();Store.toggleFavorite('${teaching.id}');this.classList.toggle('active');" title="Favori">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
            </button>
            <button class="expanded-action-btn ${isDl ? 'active' : ''}" id="expanded-dl" onclick="event.stopPropagation();App.handleDownload(this, '${teaching.id}')" title="${isDl ? 'Retirer des téléchargements' : 'Télécharger'}">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            </button>
            <button class="expanded-action-btn" onclick="event.stopPropagation();App.showAddToPackageModal('${teaching.id}')" title="Ajouter à un pack">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            </button>
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);
    document.body.classList.add('expanded-open');

    this._expandedKeyHandler = (e) => {
      if (e.key === 'Escape') this.closeExpanded();
    };
    window.addEventListener('keydown', this._expandedKeyHandler);

    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) this.closeExpanded();
    });

    // Force le morphing card → plein écran (équivalent framer-motion 0.5s easeInOut)
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        overlay.classList.add('active');
      });
    });
  },

  closeExpanded() {
    const overlay = document.getElementById('expanded-overlay');
    if (!overlay) return;
    overlay.classList.remove('active');
    document.body.classList.remove('expanded-open');
    if (this._expandedKeyHandler) {
      window.removeEventListener('keydown', this._expandedKeyHandler);
      this._expandedKeyHandler = null;
    }
    this.expandedTeachingId = null;
    setTimeout(() => overlay.remove(), 550);
  },
};
