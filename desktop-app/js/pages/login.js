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

  render() {
    const el = document.getElementById('page-login');
    el.innerHTML = `
      <div class="login-container">
        <div class="login-card">
          <div class="login-logo">
            <img src="logo.png" alt="MyKOG">
          </div>
          <h1 class="login-title">Bienvenue sur MyKOG</h1>
          <p class="login-subtitle">Cr\u00e9ez votre compte pour acc\u00e9der \u00e0 tout le contenu</p>

          <form id="login-form" class="login-form" onsubmit="LoginPage.handleSubmit(event)">
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
              <span>${this.isLoading ? 'Connexion...' : 'Cr\u00e9er mon compte'}</span>
            </button>
          </form>

          <p class="login-footer-text">
            En vous connectant, vous acceptez nos <a href="#" onclick="event.preventDefault()">conditions d'utilisation</a>.
          </p>
        </div>
      </div>
    `;

    if (!this.isLoading) {
      setTimeout(() => {
        const saved = localStorage.getItem('mykog_login_phone');
        if (saved) {
          document.getElementById('login-phone').value = saved;
          document.getElementById('login-name')?.focus();
        } else {
          document.getElementById('login-name')?.focus();
        }
      }, 200);
    }
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

  toggleCodePicker() {
    this.codePickerOpen = !this.codePickerOpen;
    this.render();
    if (this.codePickerOpen) {
      setTimeout(() => {
        document.addEventListener('click', this.closeCodePickerOutside);
      }, 10);
    }
  },

  closeCodePickerOutside(e) {
    if (!e.target.closest('.login-code-picker') && !e.target.closest('.code-picker-dropdown')) {
      LoginPage.codePickerOpen = false;
      LoginPage.render();
      document.removeEventListener('click', LoginPage.closeCodePickerOutside);
    }
  },

  selectCode(code) {
    this.selectedCode = code;
    this.codePickerOpen = false;
    this.render();
    setTimeout(() => document.getElementById('login-phone')?.focus(), 100);
  },

  async handleSubmit(e) {
    e.preventDefault();
    if (this.isLoading) return;

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

      const now = new Date().toISOString();
      const userId = 'user-' + Date.now();
      const userData = {
        id: userId,
        name,
        email: fullPhone,
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
      App.showToast('Connexion r\u00e9ussie');
      App.navigate('home');
      App.showToast(`Bienvenue, ${name} !`);
    } catch (err) {
      this.isLoading = false;
      const msg = err.message || '';
      if (msg === 'Timeout') {
        this.errorMsg = 'La requ\u00eate a expir\u00e9. V\u00e9rifiez votre connexion ou que le serveur est en marche.';
      } else if (msg.startsWith('HTTP ')) {
        this.errorMsg = 'Erreur serveur (' + msg + '). Contactez l\'administrateur.';
      } else if (msg.includes('Failed to fetch') || msg.includes('NetworkError') || msg.includes('net::ERR_')) {
        this.errorMsg = 'Impossible de joindre le serveur (' + (localStorage.getItem('mykog_api_base') || 'http://185.98.128.123:3001/mykog-api/api') + '). V\u00e9rifiez que le serveur est allum\u00e9.';
      } else {
        this.errorMsg = 'Erreur de connexion. V\u00e9rifiez votre r\u00e9seau.';
      }
      console.error('[Login] Erreur compl\u00e8te:', err);
      this.render();
    }
  },
};
