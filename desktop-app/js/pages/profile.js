const ProfilePage = {
  render() {
    const el = document.getElementById('page-profile');
    const s = Store.state;
    const user = s.user || { name: 'U', email: '', createdAt: new Date().toISOString(), favoriteTeachingIds: [], downloadedTeachingIds: [], recentlyPlayedIds: [] };
    const firstLetter = (user.name || 'U')[0].toUpperCase();
    const isDark = s.isDarkMode;

    if (s.isLoading && !s.user) {
      el.innerHTML = `
        <div class="profile-header">
          <div class="profile-avatar" style="position:relative;">
            <div class="skeleton" style="width:80px;height:80px;border-radius:50%;"></div>
          </div>
          <div style="margin-top:12px;display:flex;flex-direction:column;align-items:center;gap:6px;">
            <div class="skeleton" style="width:160px;height:24px;border-radius:6px;"></div>
            <div class="skeleton" style="width:200px;height:14px;border-radius:4px;"></div>
            <div class="skeleton" style="width:140px;height:12px;border-radius:4px;"></div>
          </div>
        </div>
        ${Skeleton.profileStats()}
      `;
      return;
    }

    el.innerHTML = `
      <div class="profile-header">
        <div class="profile-avatar" onclick="ProfilePage.showEditProfile()">
          <span class="avatar-letter">${firstLetter}</span>
          <div class="avatar-edit">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </div>
        </div>
        <h2 class="profile-name">${user.name}</h2>
        <p class="profile-email">${user.email}</p>
        <p class="profile-joined">Membre depuis ${Store.formatDate(user.createdAt)}</p>
      </div>

      <div class="stats-row" style="margin-top: 24px;">
        <div class="glass-card stat-card">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#e22134" stroke-width="2"><path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
          <p class="stat-value">${(user.favoriteTeachingIds || []).length}</p>
          <p class="stat-label">Favoris</p>
        </div>
        <div class="glass-card stat-card">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1db954" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <p class="stat-value">${(user.downloadedTeachingIds || []).length}</p>
          <p class="stat-label">Téléchargés</p>
        </div>
        <div class="glass-card stat-card">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#d4af37" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          <p class="stat-value">${(user.recentlyPlayedIds || []).length}</p>
          <p class="stat-label">Récents</p>
        </div>
      </div>

      <div class="settings-section">
        <h3>Paramètres</h3>
        <div class="glass-card settings-card">
          <div class="settings-item" onclick="ProfilePage.showDownloads()">
            <div class="settings-icon">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            </div>
            <div class="settings-info">
              <p class="settings-title">Enseignements téléchargés</p>
              <p class="settings-subtitle">Gérer le contenu hors ligne</p>
            </div>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--text-tertiary)"><polyline points="9 18 15 12 9 6"/></svg>
          </div>

          <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:4px 0;">

          <div class="settings-item">
            <div class="settings-icon">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707"/></svg>
            </div>
            <div class="settings-info">
              <p class="settings-title">Mode sombre</p>
              <p class="settings-subtitle">Basculer entre les thèmes</p>
            </div>
            <button class="toggle ${isDark ? 'active' : ''}" onclick="ProfilePage.toggleTheme()"></button>
          </div>

          <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:4px 0;">

          <div class="settings-item">
            <div class="settings-icon">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
            </div>
            <div class="settings-info">
              <p class="settings-title">Notifications</p>
              <p class="settings-subtitle">Notifications pour les nouveaux contenus</p>
            </div>
            <button class="toggle ${s.notificationsEnabled ? 'active' : ''}" onclick="Store.toggleNotifications(); ProfilePage.render();"></button>
          </div>

          <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:4px 0;">

          <div class="settings-item" onclick="ProfilePage.showAbout()">
            <div class="settings-icon">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
            </div>
            <div class="settings-info">
              <p class="settings-title">À propos de MyKOG</p>
              <p class="settings-subtitle">Version 1.0.0</p>
            </div>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--text-tertiary)"><polyline points="9 18 15 12 9 6"/></svg>
          </div>

          <hr style="border:none;border-top:1px solid rgba(255,255,255,0.08);margin:4px 0;">

          <div class="settings-item" onclick="ProfilePage.showSignOut()" style="color:var(--error)">
            <div class="settings-icon" style="color:var(--error)">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            </div>
            <div class="settings-info">
              <p class="settings-title">Déconnexion</p>
              <p class="settings-subtitle" style="color:var(--error)">Se déconnecter du compte</p>
            </div>
          </div>
        </div>
      </div>
    `;
  },

  toggleTheme() {
    Store.setState({ isDarkMode: !Store.state.isDarkMode });
    document.body.classList.toggle('light-mode');
    this.render();
  },

  showEditProfile() {
    const user = Store.state.user;
    if (!user) return;

    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.innerHTML = `
      <div class="modal">
        <h3>Modifier le profil</h3>
        <label>Nom</label>
        <input type="text" id="edit-name" value="${user.name}">
        <label>Email</label>
        <input type="email" id="edit-email" value="${user.email}">
        <div class="modal-actions">
          <button class="modal-btn secondary" onclick="this.closest('.modal-overlay').remove()">Annuler</button>
          <button class="modal-btn primary" onclick="ProfilePage.saveProfile()">Enregistrer</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);

    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  },

  saveProfile() {
    const name = document.getElementById('edit-name').value.trim();
    const email = document.getElementById('edit-email').value.trim();
    if (name) Store.updateUser({ name, email });
    document.querySelector('.modal-overlay')?.remove();
    this.render();
    App.showToast('Profil mis à jour avec succès');
  },

  showDownloads() {
    const teachings = Store.getDownloadedTeachings();
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.innerHTML = `
      <div class="modal" style="max-height:80vh;display:flex;flex-direction:column;">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;">
          <div style="display:flex;align-items:center;gap:10px;">
            <div style="width:36px;height:36px;border-radius:10px;background:var(--accent);display:flex;align-items:center;justify-content:center;color:var(--bg-primary);flex-shrink:0;">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            </div>
            <h3 style="font-size:18px;">Mes Téléchargements</h3>
          </div>
          <span style="font-size:13px;color:var(--text-secondary);">${teachings.length} enseignement${teachings.length !== 1 ? 's' : ''}</span>
        </div>
        ${teachings.length === 0 ? `
          <div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:40px 20px;color:var(--text-tertiary);">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom:16px;"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            <p style="font-size:14px;text-align:center;">Aucun enseignement téléchargé.<br>Utilisez le bouton ⬇ sur un enseignement pour l'ajouter.</p>
          </div>
        ` : `
          <div style="flex:1;overflow-y:auto;display:flex;flex-direction:column;gap:6px;">
            ${teachings.map(t => `
              <div class="teaching-list-item" onclick="this.closest('.modal-overlay').remove();Store.playTeaching(Store.getTeachingById('${t.id}'), Store.state.teachings)" style="cursor:pointer;">
                <div class="item-artwork">
                  ${t.artworkUrl ? `<img src="${t.artworkUrl}" alt="" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : ''}
                  <div class="artwork-fallback" style="${t.artworkUrl ? 'display:none' : ''}">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
                  </div>
                </div>
                <div class="item-info">
                  <p class="item-title">${t.title}</p>
                  <p class="item-meta">${t.speaker} · ${t.category || ''}</p>
                </div>
                <span class="item-duration">${Store.formatDuration(t.duration)}</span>
                <button class="dl-btn active" onclick="event.stopPropagation();var _btn=this;App.handleDownload(this, '${t.id}', function(){_btn.closest('.teaching-list-item').remove();if(!document.querySelector('.teaching-list-item')){document.querySelector('.modal')?.querySelector('[data-empty]')?.style.removeProperty('display');}});" title="Retirer des téléchargements" style="position:static;opacity:1;flex-shrink:0;">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                  <div class="dl-spinner"></div>
                </button>
              </div>
            `).join('')}
          </div>
        `}
        <div class="modal-actions" style="margin-top:12px;padding-top:12px;border-top:1px solid rgba(255,255,255,0.06);flex-shrink:0;">
          <button class="modal-btn secondary" onclick="this.closest('.modal-overlay').remove()">Fermer</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  },

  showAbout() {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.innerHTML = `
      <div class="modal">
        <h3>À propos de MyKOG</h3>
        <p style="color:var(--text-secondary);line-height:1.6;margin-bottom:16px;">
          MyKOG est une application de streaming audio spirituel qui combine le design élégant de Spotify avec l'esthétique raffinée d'Apple Music, offrant une expérience immersive pour les contenus basés sur la foi.
        </p>
        <p style="color:var(--text-tertiary);margin-bottom:16px;">Version 1.0.0 — Desktop</p>
        <div class="modal-actions">
          <button class="modal-btn primary" onclick="this.closest('.modal-overlay').remove()">OK</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  },

  showSignOut() {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay open';
    overlay.innerHTML = `
      <div class="modal">
        <h3>Déconnexion</h3>
        <p style="color:var(--text-secondary);margin-bottom:16px;">Êtes-vous sûr de vouloir vous déconnecter ? Vos données locales seront effacées.</p>
        <div class="modal-actions">
          <button class="modal-btn secondary" onclick="this.closest('.modal-overlay').remove()">Annuler</button>
          <button class="modal-btn danger" onclick="ProfilePage.doSignOut()">Se déconnecter</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  },

  doSignOut() {
    document.querySelector('.modal-overlay')?.remove();
    Store.logout();
    App.showToast('D\u00e9connect\u00e9 avec succ\u00e8s');
  },
};
