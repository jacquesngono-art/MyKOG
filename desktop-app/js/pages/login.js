const COUNTRY_CODES = [
  { code: '+237', country: 'Cameroun', flag: '🇨🇲' },
  { code: '+225', country: "C\u00f4te d'Ivoire", flag: '🇨🇮' },
  { code: '+221', country: 'S\u00e9n\u00e9gal', flag: '🇸🇳' },
  { code: '+229', country: 'B\u00e9nin', flag: '🇧🇯' },
  { code: '+228', country: 'Togo', flag: '🇹🇬' },
  { code: '+226', country: 'Burkina Faso', flag: '🇧🇫' },
  { code: '+224', country: 'Guin\u00e9e', flag: '🇬🇳' },
  { code: '+233', country: 'Ghana', flag: '🇬🇭' },
  { code: '+234', country: 'Nigeria', flag: '🇳🇬' },
  { code: '+243', country: 'RDC', flag: '🇨🇩' },
  { code: '+242', country: 'Congo', flag: '🇨🇬' },
  { code: '+241', country: 'Gabon', flag: '🇬🇦' },
  { code: '+236', country: 'RCA', flag: '🇨🇫' },
  { code: '+33', country: 'France', flag: '🇫🇷' },
  { code: '+32', country: 'Belgique', flag: '🇧🇪' },
  { code: '+41', country: 'Suisse', flag: '🇨🇭' },
  { code: '+1', country: 'USA/Canada', flag: '🇺🇸' },
];

const LoginPage = {
  selectedCode: '+237',
  isLoading: false,
  errorMsg: '',
  codePickerOpen: false,
  photoFile: null,
  photoPreview: null,
  mode: 'register', // 'register' | 'login'
  _draftName: null,
  _draftPhone: null,

  // Réinitialise l'état (appelé quand on revient sur la page login,
  // ex: après déconnexion — sinon isLoading resterait à true)
  reset() {
    this.isLoading = false;
    this.errorMsg = '';
    this.codePickerOpen = false;
  },

  render() {
    const el = document.getElementById('page-login');
    const isLogin = this.mode === 'login';
    this._captureDrafts();
    el.innerHTML = `
      <div class="login-container">
        <div class="login-card">
          <div class="login-logo">
            <img src="logo.png" alt="MyKOG">
          </div>
          <h1 class="login-title">Bienvenue sur MyKOG</h1>
          <p class="login-subtitle" id="login-subtitle">${isLogin
            ? 'Connectez-vous avec votre nom et votre num\u00e9ro'
            : 'Cr\u00e9ez votre compte pour acc\u00e9der \u00e0 tout le contenu'}</p>

          <div class="login-tabs">
            <button type="button" class="login-tab ${!isLogin ? 'active' : ''}" id="tab-register" onclick="LoginPage.switchMode('register')">S'enregistrer</button>
            <button type="button" class="login-tab ${isLogin ? 'active' : ''}" id="tab-login" onclick="LoginPage.switchMode('login')">Se connecter</button>
          </div>

          <div id="login-form-zone">${this.renderForm()}</div>

          <p class="login-footer-text">
            En vous connectant, vous acceptez nos <a href="#" onclick="event.preventDefault()">conditions d'utilisation</a>.
          </p>
        </div>
      </div>
    `;

    this._restoreAndFocus();
  },

  // Seule la partie formulaire — rechargée seule au changement d'onglet
  renderForm() {
    const isLogin = this.mode === 'login';
    return `
      <form id="login-form" class="login-form" onsubmit="LoginPage.handleSubmit(event)">
        <div class="login-avatar-picker ${isLogin ? 'is-hidden' : ''}" ${isLogin ? '' : "onclick=\"document.getElementById('login-photo-input').click()\""}>
          <div class="login-avatar-preview" id="login-avatar-preview">
            ${this.photoPreview
              ? `<img src="${this.photoPreview}" alt="Photo de profil">`
              : `<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`}
          </div>
          <span class="login-avatar-label">${this.photoPreview ? 'Changer la photo' : 'Ajouter une photo (optionnel)'}</span>
          <input type="file" id="login-photo-input" accept="image/*" style="display:none" onchange="LoginPage.handlePhotoSelect(event)">
        </div>

        <div class="login-field">
          <label for="login-name">Nom complet</label>
          <div class="login-input-wrap">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            <input type="text" id="login-name" placeholder="Votre nom" maxlength="50" autocomplete="name">
          </div>
        </div>

        <div class="login-field">
          <label for="login-phone">Num\u00e9ro de t\u00e9l\u00e9phone</label>
          <div class="login-phone-row">
            <div class="login-code-picker" id="code-picker-trigger" onclick="LoginPage.toggleCodePicker()">
              <span id="selected-flag">${this.getCurrentFlag()}</span>
              <span id="selected-code">${this.selectedCode}</span>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
            </div>
            <div class="login-input-wrap" style="flex:1;">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z"/></svg>
              <input type="tel" id="login-phone" placeholder="6 00 00 00 00" maxlength="15" autocomplete="tel">
            </div>
          </div>
          ${this.codePickerOpen ? this.renderCodePicker() : ''}
        </div>

        ${this.errorMsg ? `<div class="login-error">${this.errorMsg}</div>` : ''}

        <button type="submit" class="login-btn" id="login-submit-btn" ${this.isLoading ? 'disabled' : ''}>
          ${this.isLoading ? '<div class="login-spinner"></div>' : ''}
          <span>${this.isLoading ? 'Connexion...' : (isLogin ? 'Se connecter' : 'Cr\u00e9er mon compte')}</span>
        </button>
      </form>
    `;
  },

  _captureDrafts() {
    this._draftName = document.getElementById('login-name')?.value ?? this._draftName;
    this._draftPhone = document.getElementById('login-phone')?.value ?? this._draftPhone;
  },

  _restoreAndFocus(focus = true) {
    if (this.isLoading) return;
    setTimeout(() => {
      const nameEl = document.getElementById('login-name');
      const phoneEl = document.getElementById('login-phone');
      if (nameEl) nameEl.value = this._draftName ?? localStorage.getItem('mykog_login_name') ?? '';
      if (phoneEl) phoneEl.value = this._draftPhone ?? localStorage.getItem('mykog_login_phone') ?? '';
      if (!focus) return;
      const focusId = this.mode === 'login' ? 'login-phone' : 'login-name';
      document.getElementById(focusId)?.focus();
    }, 50);
  },

  // Change d'onglet : seuls les champs d'authentification se rechargent,
  // le reste de la page (logo, titre, onglets) ne bouge pas.
  switchMode(mode) {
    if (this.mode === mode) return;
    this._captureDrafts();
    this.mode = mode;
    this.errorMsg = '';
    this.codePickerOpen = false;

    const isLogin = mode === 'login';
    document.getElementById('tab-register')?.classList.toggle('active', !isLogin);
    document.getElementById('tab-login')?.classList.toggle('active', isLogin);
    const subtitle = document.getElementById('login-subtitle');
    if (subtitle) {
      subtitle.textContent = isLogin
        ? 'Connectez-vous avec votre nom et votre num\u00e9ro'
        : 'Cr\u00e9ez votre compte pour acc\u00e9der \u00e0 tout le contenu';
    }
    document.getElementById('login-form-zone').innerHTML = this.renderForm();
    this._restoreAndFocus();
  },

  getCurrentFlag() {
    const found = COUNTRY_CODES.find(c => c.code === this.selectedCode);
    return found ? found.flag : '🇨🇲';
  },

  renderCodePicker() {
    return `
      <div class="code-picker-dropdown" id="code-picker-dropdown">
        ${COUNTRY_CODES.map(c => `
          <div class="code-picker-item ${c.code === this.selectedCode ? 'active' : ''}" onclick="LoginPage.selectCode('${c.code}')">
            <span style="font-size:18px;">${c.flag}</span>
            <span style="flex:1;color:var(--text-primary);font-size:14px;">${c.country}</span>
            <span style="color:var(--text-secondary);font-size:14px;">${c.code}</span>
          </div>
        `).join('')}
      </div>
    `;
  },

  _renderFormZone() {
    this._captureDrafts();
    const zone = document.getElementById('login-form-zone');
    if (zone) zone.innerHTML = this.renderForm();
  },

  toggleCodePicker() {
    this.codePickerOpen = !this.codePickerOpen;
    this._renderFormZone();
    this._restoreAndFocus(false);
    if (this.codePickerOpen) {
      setTimeout(() => {
        document.addEventListener('click', this.closeCodePickerOutside);
      }, 10);
    }
  },

  closeCodePickerOutside(e) {
    if (!e.target.closest('.login-code-picker') && !e.target.closest('.code-picker-dropdown')) {
      LoginPage.codePickerOpen = false;
      LoginPage._renderFormZone();
      LoginPage._restoreAndFocus(false);
      document.removeEventListener('click', LoginPage.closeCodePickerOutside);
    }
  },

  selectCode(code) {
    this.selectedCode = code;
    this.codePickerOpen = false;
    this._renderFormZone();
    this._restoreAndFocus(false);
    setTimeout(() => document.getElementById('login-phone')?.focus(), 100);
  },

  handlePhotoSelect(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      this.errorMsg = 'Veuillez choisir une image.';
      this.render();
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      this.errorMsg = 'Image trop lourde (max 5 Mo).';
      this.render();
      return;
    }
    this.photoFile = file;
    const reader = new FileReader();
    reader.onload = (ev) => {
      this.photoPreview = ev.target.result;
      this.render();
    };
    reader.readAsDataURL(file);
  },

  async uploadPhoto() {
    if (!this.photoFile) return null;
    const formData = new FormData();
    formData.append('file', this.photoFile);
    const res = await API.uploadFile(formData);
    if (res && res.key) {
      const base = localStorage.getItem('mykog_api_base') || 'http://185.98.128.123:3001/mykog-api/api';
      return `${base}/files/${encodeURIComponent(res.key)}`;
    }
    return null;
  },

  async handleSubmit(e) {
    e.preventDefault();
    if (this.isLoading) return;
    if (this.mode === 'login') return this.handleLogin();
    return this.handleRegister();
  },

  _getPhone() {
    const phone = document.getElementById('login-phone')?.value.trim();
    return phone ? this.selectedCode + phone.replace(/\s/g, '') : '';
  },

  _fail(msg, err) {
    if (err) console.error('[Login] Erreur compl\u00e8te:', err);
    this.isLoading = false;
    this.errorMsg = msg;
    this.render();
  },

  _networkErrorMsg(err) {
    const msg = err?.message || '';
    if (msg === 'Timeout') return 'La requ\u00eate a expir\u00e9. V\u00e9rifiez votre connexion.';
    if (msg.includes('Failed to fetch') || msg.includes('NetworkError') || msg.includes('net::ERR_'))
      return 'Impossible de joindre le serveur. V\u00e9rifiez votre connexion.';
    return null;
  },

  async handleLogin() {
    const name = document.getElementById('login-name')?.value.trim();
    const fullPhone = this._getPhone();
    if (!name || fullPhone.length < 8) {
      this.errorMsg = 'Veuillez saisir votre nom et un num\u00e9ro valide.';
      this.render();
      return;
    }
    if (!navigator.onLine) {
      this.errorMsg = 'Vous devez \u00eatre connect\u00e9 \u00e0 Internet.';
      this.render();
      return;
    }

    this.isLoading = true;
    this.errorMsg = '';
    this.render();

    try {
      const user = await API.loginByPhone(fullPhone, name);
      localStorage.setItem('mykog_login_phone', document.getElementById('login-phone')?.value.trim() || '');
      localStorage.setItem('mykog_login_name', name);
      Store.setUser(user);
      Store.startPolling();
      App.navigate('home');
      App.showToast(`Bon retour, ${user.name} !`);
    } catch (err) {
      const msg = err.message || '';
      const net = this._networkErrorMsg(err);
      if (net) return this._fail(net, err);
      if (msg.includes('incorrect')) {
        return this._fail('Nom ou num\u00e9ro incorrect.', err);
      }
      if (msg.includes('Aucun compte')) {
        return this._fail('Aucun compte associ\u00e9 \u00e0 ce num\u00e9ro. Passez sur l\'onglet « S\'enregistrer ».', err);
      }
      this._fail('Erreur de connexion (' + msg + ').', err);
    }
  },

  async handleRegister() {
    const name = document.getElementById('login-name')?.value.trim();
    const phone = document.getElementById('login-phone')?.value.trim();

    if (!name || !phone) {
      this.errorMsg = 'Veuillez remplir tous les champs.';
      this.render();
      return;
    }

    const fullPhone = this.selectedCode + phone.replace(/\s/g, '');

    if (fullPhone.length < 8) {
      this.errorMsg = 'Num\u00e9ro de t\u00e9l\u00e9phone invalide.';
      this.render();
      return;
    }

    if (!navigator.onLine) {
      this.isLoading = false;
      this.errorMsg = 'Vous devez \u00eatre connect\u00e9 \u00e0 Internet pour cr\u00e9er un compte.';
      this.render();
      return;
    }

    this.isLoading = true;
    this.errorMsg = '';
    this.render();

    try {
      localStorage.setItem('mykog_login_phone', phone);

      // Le numéro a-t-il déjà un compte ?
      try {
        const existing = await API.loginByPhone(fullPhone, name);
        if (existing && existing.id) {
          this.isLoading = false;
          this.errorMsg = 'Ce num\u00e9ro poss\u00e8de d\u00e9j\u00e0 un compte. Passez sur « Se connecter ».';
          this.render();
          return;
        }
      } catch (err) {
        // 404 = pas de compte → on continue la création
        // 401 = numéro déjà pris sous un autre nom → compte existant
        const m = err.message || '';
        if (m.includes('incorrect')) {
          this.isLoading = false;
          this.errorMsg = 'Ce num\u00e9ro poss\u00e8de d\u00e9j\u00e0 un compte sous un autre nom. Passez sur « Se connecter ».';
          this.render();
          return;
        }
        if (!m.includes('Aucun compte')) {
          console.warn('[Login] Vérif compte existant échouée:', err);
        }
      }

      // Upload de la photo de profil si sélectionnée
      let profileImageUrl = null;
      if (this.photoFile) {
        try {
          profileImageUrl = await this.uploadPhoto();
        } catch (err) {
          console.warn('[Login] Upload photo échoué, création sans photo:', err);
        }
      }

      const now = new Date().toISOString();
      const userId = 'user-' + Date.now();
      const userData = {
        id: userId,
        name,
        email: fullPhone,
        profileImageUrl,
        favoriteTeachingIds: [],
        downloadedTeachingIds: [],
        recentlyPlayedIds: [],
        notificationsEnabled: true,
        createdAt: now,
        updatedAt: now,
      };

      const user = await API.login(userData);

      Store.setUser(user);
      Store.startPolling();
      App.navigate('home');
      App.showToast(`Bienvenue, ${name} !`);
    } catch (err) {
      const net = this._networkErrorMsg(err);
      this._fail(net || 'Erreur de connexion (' + (err.message || '') + ').', err);
    }
  },
};
