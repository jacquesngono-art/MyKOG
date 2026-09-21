const OnboardingPage = {
  pageIndex: 0,

  pages: [
    {
      title: 'VISION',
      text: '\u00ab R\u00c9V\u00c9LER LA LUMI\u00c8RE ET LA GLOIRE DE CHRIST AUX NATIONS ET AUX ROIS \u00bb',
      reference: 'COLOSSIENS 1:27',
    },
    {
      title: 'MANDAT\n(18 OCTOBRE 2018)',
      text: 'VA ET D\u00c9LIVRE MON PEUPLE,\nJE SERAI AVEC TOI',
      reference: '',
    },
    {
      title: 'ORDRE DE MISSION',
      text: '',
      reference: '',
      isMission: true,
    },
  ],

  missions: [
    'Conduire le peuple de Dieu \u00e0 la repentance et \u00e0 la v\u00e9ritable conversion',
    'Faire conna\u00eetre au peuple de Dieu leur identit\u00e9 en Christ',
    'Conduire le peuple de Dieu dans son couloir d\u2019appel et vers sa destin\u00e9e',
    'Annoncer les myst\u00e8res du royaume',
    '\u00c9largir les limites de leurs pens\u00e9es',
  ],

  isCompleted() {
    return localStorage.getItem('mykog_onboarding_completed') === 'true';
  },

  complete() {
    localStorage.setItem('mykog_onboarding_completed', 'true');
  },

  show() {
    this.pageIndex = 0;
    const overlay = document.createElement('div');
    overlay.className = 'onboarding-overlay';
    overlay.id = 'onboarding-overlay';
    document.body.appendChild(overlay);
    this.render();
  },

  hide() {
    const overlay = document.getElementById('onboarding-overlay');
    if (overlay) {
      overlay.classList.add('hidden');
      setTimeout(() => overlay.remove(), 400);
    }
  },

  render() {
    const overlay = document.getElementById('onboarding-overlay');
    if (!overlay) return;
    const page = this.pages[this.pageIndex];
    const isLast = this.pageIndex === this.pages.length - 1;

    overlay.innerHTML = `
      <div class="onboarding-card">
        <img src="assets/kog.png" alt="KOG" class="onboarding-logo">
        <div class="onboarding-content">
          <h1 class="onboarding-title">${page.title.replace(/\n/g, '<br>')}</h1>
          ${page.isMission
            ? this.renderMissions()
            : `
              <p class="onboarding-text">${page.text.replace(/\n/g, '<br>')}</p>
              ${page.reference ? `<div class="onboarding-reference">${page.reference}</div>` : ''}
            `}
        </div>
        <div class="onboarding-dots">
          ${this.pages.map((_, i) => `
            <span class="onboarding-dot ${i === this.pageIndex ? 'active' : ''}"></span>
          `).join('')}
        </div>
        <button class="onboarding-btn" onclick="OnboardingPage.next()">
          ${isLast ? 'Commencer' : 'Suivant'}
        </button>
      </div>
    `;
  },

  renderMissions() {
    return `
      <div class="onboarding-missions">
        ${this.missions.map((m, i) => `
          <div class="onboarding-mission">
            <div class="onboarding-mission-num">${i + 1}</div>
            <p class="onboarding-mission-text">${m}</p>
          </div>
        `).join('')}
      </div>
    `;
  },

  next() {
    const isLast = this.pageIndex === this.pages.length - 1;
    if (isLast) {
      this.complete();
      this.hide();
      App.afterOnboarding();
    } else {
      this.pageIndex++;
      this.render();
    }
  },
};
