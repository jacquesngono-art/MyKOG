const HomePage = {
  viewingPackageId: null,
  editingPackageId: null,
  deletingPackageId: null,
  deleteProgress: 0,
  deleteTimer: null,
  deleteInterval: null,
  menuOpenPkgId: null,

  render() {
    this.editingPackageId = null;
    this.deletingPackageId = null;
    this.clearDeleteTimers();

    if (this.viewingPackageId) {
      this.renderPackageDetail(this.viewingPackageId);
      return;
    }
    const el = document.getElementById('page-home');
    const s = Store.state;
    const user = s.user || { name: 'Utilisateur' };
    const greeting = Store.getGreeting();
    const popular = Store.getPopularTeachings(5);
    const recent = s.recentlyPlayed.slice(0, 5).map(id => Store.getTeachingById(id)).filter(Boolean);
    const packages = s.favoritePackages || [];

    if (s.isLoading && !packages.length && !recent.length && !popular.length) {
      el.innerHTML = this.renderSkeleton(user, greeting);
      return;
    }

    el.innerHTML = `
      <div class="hero-section">
        <div class="hero-top">
          <div>
            <p class="hero-greeting">${greeting}</p>
            <h1 class="hero-name">${user.name}</h1>
          </div>
          <div class="hero-actions">
            <button class="hero-btn" onclick="App.showCreatePackageModal('')" title="Créer un pack">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/><line x1="12" y1="11" x2="12" y2="17"/><line x1="9" y1="14" x2="15" y2="14"/></svg>
            </button>
          </div>
        </div>
        <div class="glass-card verse-card">
          <div class="verse-header">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            <span>Verset du Jour</span>
          </div>
          <p class="verse-text">"Nous Avons un puissant culte ce dimanche ! Rejoignez-nous pour une experience spirituelle transformative."</p>
          <p class="verse-ref">Communiquez !</p>
        </div>
      </div>

      ${packages.length ? `
        <div class="section-header" style="margin-top: 24px;">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
          <h2>Mes Packs Favoris</h2>
        </div>
        <div class="package-grid">
          ${packages.map(p => this.renderPackageCard(p)).join('')}
          <div class="glass-card create-pkg-card" onclick="App.showCreatePackageModal('')">
            <div class="create-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            </div>
            <span class="create-text">Nouveau pack</span>
          </div>
        </div>
      ` : ''}

      ${recent.length ? `
        <div class="section-header">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          <h2>Récemment écoutés</h2>
        </div>
        <div class="horizontal-list">
          ${recent.map(t => this.renderCard(t)).join('')}
        </div>
      ` : ''}

      ${Store.getDownloadedTeachings().length ? `
        <div class="section-header">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <h2>Mes Téléchargements</h2>
        </div>
        <div class="horizontal-list">
          ${Store.getDownloadedTeachings().slice(0, 10).map(t => this.renderCard(t)).join('')}
        </div>
      ` : ''}

      <div class="section-header" style="margin-top: 24px;">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
        <h2>Populaires cette semaine</h2>
      </div>
      <div class="horizontal-list">
        ${popular.map(t => this.renderCard(t)).join('')}
      </div>

      ${s.isOffline ? `
        <div class="empty-state">
          <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <h3>Mode hors ligne</h3>
          <p>Connectez-vous pour découvrir les nouveaux enseignements.</p>
        </div>
      ` : ''}
    `;
  },

  renderPackageCard(pkg) {
    const count = pkg.teachingIds.length;
    const iconSvg = count > 0
      ? '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>'
      : '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>';
    const isMenuOpen = this.menuOpenPkgId === pkg.id;
    return `
      <div class="glass-card package-card" onclick="HomePage.viewPackage('${pkg.id}')" style="position:relative;">
        <div class="package-icon">${iconSvg}</div>
        <span class="package-name">${pkg.name}</span>
        <span class="package-count">${count} enseignement${count !== 1 ? 's' : ''}</span>
        <button class="more-btn ${isMenuOpen ? 'open' : ''}" onclick="event.stopPropagation();HomePage.togglePackageMenu('${pkg.id}')" title="Plus d'options">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="5" r="1.5" fill="currentColor"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><circle cx="12" cy="19" r="1.5" fill="currentColor"/></svg>
        </button>
        ${isMenuOpen ? `
          <div class="dropdown-menu" onclick="event.stopPropagation()">
            <button class="dropdown-menu-item" onclick="event.stopPropagation();HomePage.renamePackageInline('${pkg.id}')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              Renommer
            </button>
            <button class="dropdown-menu-item danger" onclick="event.stopPropagation();HomePage.confirmDeletePackage('${pkg.id}')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
              Supprimer
            </button>
          </div>
        ` : ''}
      </div>
    `;
  },

  togglePackageMenu(pkgId) {
    this.menuOpenPkgId = this.menuOpenPkgId === pkgId ? null : pkgId;
    this.render();
  },

  renamePackageInline(pkgId) {
    const pkg = Store.getPackageById(pkgId);
    if (!pkg) return;
    this.menuOpenPkgId = null;
    this.viewingPackageId = pkgId;
    this.editingPackageId = pkgId;
    this.renderPackageDetail(pkgId);
  },

  confirmDeletePackage(pkgId) {
    this.menuOpenPkgId = null;
    this.viewingPackageId = pkgId;
    this.deletePackage(pkgId);
  },

  viewPackage(packageId) {
    this.viewingPackageId = packageId;
    this.renderPackageDetail(packageId);
  },

  renderPackageDetail(packageId) {
    const el = document.getElementById('page-home');
    const pkg = Store.getPackageById(packageId);
    if (!pkg) {
      this.viewingPackageId = null;
      this.render();
      return;
    }
    const teachings = Store.getTeachingsInPackage(packageId);
    const isEditing = this.editingPackageId === packageId;

    el.innerHTML = `
      <div class="package-detail-header">
        <button class="pkg-back-btn" onclick="HomePage.backToHome()">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
        </button>
        <div class="big-icon">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
        </div>
        <div class="pkg-detail-info" style="flex:1;min-width:0;">
          ${isEditing ? `
            <div class="inline-edit-container">
              <textarea class="inline-edit-input" id="inline-rename-input" style="font-size:26px;padding:0;" maxlength="50" rows="1">${pkg.name}</textarea>
              <div style="display:flex;gap:6px;margin-top:8px;">
                <button class="inline-edit-btn cancel" onclick="HomePage.cancelInlineRename()">Annuler</button>
                <button class="inline-edit-btn save" onclick="HomePage.saveInlineRename('${packageId}')">Enregistrer</button>
              </div>
            </div>
          ` : `
            <h2>${pkg.name}</h2>
          `}
          <p>${pkg.description || `${teachings.length} enseignement${teachings.length !== 1 ? 's' : ''}`}</p>
        </div>
        <div style="margin-left:auto;display:flex;gap:8px;align-items:flex-start;">
          ${!isEditing ? `
            <button class="hero-btn" onclick="HomePage.editingPackageId='${packageId}';HomePage.renderPackageDetail('${packageId}')" title="Renommer">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
            </button>
            <button class="hero-btn" onclick="HomePage.deletePackage('${packageId}')" title="Supprimer" style="color:var(--error)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
            </button>
          ` : ''}
        </div>
      </div>

      ${this.deletingPackageId === packageId ? `
        <div class="pkg-delete-overlay">
          <div class="delete-content">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--error)" stroke-width="1.5"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
            <div class="delete-title">Supprimer « ${pkg.name} » ?</div>
            <div class="delete-desc">Cette action est irréversible. Maintenez pour confirmer.</div>
            <div class="delete-progress-bar">
              <div class="delete-progress-fill" style="width:${this.deleteProgress}%"></div>
            </div>
            <div class="delete-btns">
              <button class="delete-btn secondary" onclick="HomePage.cancelDeleteCountdown()">Annuler</button>
              <button class="delete-btn danger" onmousedown="HomePage.startDeleteCountdown('${packageId}')" onmouseup="HomePage.cancelDeleteCountdown()" onmouseleave="HomePage.cancelDeleteCountdown()" ontouchstart="HomePage.startDeleteCountdown('${packageId}')" ontouchend="HomePage.cancelDeleteCountdown()">
                ${this.deleteProgress > 0 && this.deleteProgress < 100 ? 'Suppression...' : 'Maintenir pour supprimer'}
              </button>
            </div>
          </div>
        </div>
      ` : ''}

      ${teachings.length === 0 ? `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/></svg>
          <h3>Ce pack est vide</h3>
          <p>Ajoutez des enseignements depuis l'accueil ou la bibliothèque.</p>
        </div>
      ` : `
        <div class="teaching-list" style="padding-top: 16px;">
          ${teachings.map(t => `
            <div class="teaching-list-item" onclick="Store.playTeaching(Store.getTeachingById('${t.id}'), Store.state.teachings)">
              <div class="item-artwork">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
              </div>
              <div class="item-info">
                <p class="item-title">${t.title}</p>
                <p class="item-meta">${t.speaker} · ${t.category}</p>
              </div>
              <span class="item-duration">${Store.formatDuration(t.duration)}</span>
              <button class="hero-btn" onclick="event.stopPropagation();HomePage.removeFromPackage('${packageId}','${t.id}')" title="Retirer du pack" style="flex-shrink:0;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--error)" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </button>
            </div>
          `).join('')}
        </div>
      `}
    `;

    if (isEditing) {
      const textarea = document.getElementById('inline-rename-input');
      if (textarea) {
        setTimeout(() => {
          textarea.focus();
          textarea.setSelectionRange(textarea.value.length, textarea.value.length);
          textarea.style.height = 'auto';
          textarea.style.height = textarea.scrollHeight + 'px';
        }, 50);
        textarea.addEventListener('input', () => {
          textarea.style.height = 'auto';
          textarea.style.height = textarea.scrollHeight + 'px';
        });
        textarea.addEventListener('keydown', (e) => {
          if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            HomePage.saveInlineRename(packageId);
          } else if (e.key === 'Escape') {
            HomePage.cancelInlineRename();
          }
        });
      }
    }
  },

  cancelInlineRename() {
    this.editingPackageId = null;
    if (this.viewingPackageId) {
      this.renderPackageDetail(this.viewingPackageId);
    }
  },

  saveInlineRename(packageId) {
    const input = document.getElementById('inline-rename-input');
    if (!input) return;
    const name = input.value.trim();
    if (!name) return;
    Store.renamePackage(packageId, name);
    this.editingPackageId = null;
    this.renderPackageDetail(packageId);
    App.showToast('Pack renommé');
  },

  deletePackage(packageId) {
    const pkg = Store.getPackageById(packageId);
    if (!pkg) return;
    this.deletingPackageId = packageId;
    this.deleteProgress = 0;
    this.renderPackageDetail(packageId);
  },

  startDeleteCountdown(packageId) {
    if (this.deleteTimer) return;
    this.deleteProgress = 0;
    const duration = 1500;
    const interval = 50;
    let elapsed = 0;

    this.deleteInterval = setInterval(() => {
      elapsed += interval;
      this.deleteProgress = Math.min(100, (elapsed / duration) * 100);
      const fill = document.querySelector('.delete-progress-fill');
      if (fill) fill.style.width = this.deleteProgress + '%';
      const btn = document.querySelector('.delete-btn.danger');
      if (btn) btn.textContent = this.deleteProgress >= 100 ? 'Suppression...' : 'Maintenir pour supprimer';
    }, interval);

    this.deleteTimer = setTimeout(() => {
      this.clearDeleteTimers();
      Store.deletePackage(packageId);
      this.deletingPackageId = null;
      this.viewingPackageId = null;
      this.render();
      App.showToast('Pack supprimé');
    }, duration);
  },

  cancelDeleteCountdown() {
    if (!this.deleteTimer && !this.deleteInterval) return;
    this.clearDeleteTimers();
    this.deletingPackageId = null;
    this.deleteProgress = 0;
    if (this.viewingPackageId) {
      this.renderPackageDetail(this.viewingPackageId);
    }
  },

  clearDeleteTimers() {
    if (this.deleteInterval) {
      clearInterval(this.deleteInterval);
      this.deleteInterval = null;
    }
    if (this.deleteTimer) {
      clearTimeout(this.deleteTimer);
      this.deleteTimer = null;
    }
  },

  removeFromPackage(packageId, teachingId) {
    Store.removeTeachingFromPackage(packageId, teachingId);
    this.renderPackageDetail(packageId);
  },

  closeDropdownMenus() {
    if (this.menuOpenPkgId) {
      this.menuOpenPkgId = null;
      this.render();
    }
  },

  backToHome() {
    this.viewingPackageId = null;
    this.editingPackageId = null;
    this.deletingPackageId = null;
    this.menuOpenPkgId = null;
    this.clearDeleteTimers();
    this.render();
  },

  renderSkeleton(user, greeting) {
    return `
      <div class="hero-section">
        <div class="hero-top">
          <div>
            <p class="hero-greeting">${greeting}</p>
            <h1 class="hero-name">${user.name}</h1>
          </div>
        </div>
        <div class="glass-card verse-card">
          <div class="verse-header">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            <span>Verset du Jour</span>
          </div>
          <p class="verse-text">"Nous Avons un puissant culte ce dimanche ! Rejoignez-nous pour une experience spirituelle transformative."</p>
          <p class="verse-ref">Communiquez !</p>
        </div>
      </div>
      ${Skeleton.packageGrid(4)}
      ${Skeleton.section('', Skeleton.horizontalList(4))}
      ${Skeleton.section('', Skeleton.horizontalList(4))}
    `;
  },

  renderCard(teaching) {
    const isFav = Store.isFavorite(teaching.id);
    const isDl = Store.isDownloaded(teaching.id);
    return `
      <div class="teaching-card" onclick="Store.playTeaching(Store.getTeachingById('${teaching.id}'), Store.state.teachings)">
        <div class="card-artwork">
          ${teaching.artworkUrl ? `<img src="${teaching.artworkUrl}" alt="" class="card-artwork-img" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
          <div class="artwork-fallback" style="${teaching.artworkUrl ? 'display:none' : ''}">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
          </div>
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
};
