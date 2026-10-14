const ResumesPage = {
  searchQuery: '',
  selectedCategory: null,
  selectedTypeCulte: null,

  openPdf(url) {
    if (window.electronAPI?.openPdf) {
      window.electronAPI.openPdf(url);
    } else {
      window.open(url, '_blank');
    }
  },

  getPdfThumbnailUrl(resume) {
    if (resume.coverImageUrl) return resume.coverImageUrl;
    if (resume.pdfUrl && resume.pdfUrl.includes('cloudinary.com')) {
      return resume.pdfUrl.replace('/upload/', '/upload/w_200,h_300,c_fit,pg_1/');
    }
    // Un PDF brut (S3) ne peut pas servir de miniature dans un <img>
    return null;
  },

  // Génère la miniature de la 1ère page du PDF via pdf.js (bytes récupérés
  // par le processus main → pas de blocage CORS). Résultat mis en cache.
  async _pdfThumb(resume, slotEl) {
    try {
      const cacheKey = `pdfthumb_${resume.id}`;
      let dataUrl = localStorage.getItem(cacheKey);

      if (!dataUrl) {
        if (!window.electronAPI?.fetchPdfBytes || !window.pdfjsLib) return;
        if (!pdfjsLib.GlobalWorkerOptions.workerSrc) {
          pdfjsLib.GlobalWorkerOptions.workerSrc = 'node_modules/pdfjs-dist/build/pdf.worker.min.js';
        }
        const bytes = await window.electronAPI.fetchPdfBytes(resume.pdfUrl);
        if (!bytes) return;
        const pdf = await pdfjsLib.getDocument({ data: bytes }).promise;
        const page = await pdf.getPage(1);
        const viewport = page.getViewport({ scale: 1 });
        const vp = page.getViewport({ scale: 480 / viewport.width });
        const canvas = document.createElement('canvas');
        canvas.width = vp.width;
        canvas.height = vp.height;
        await page.render({ canvasContext: canvas.getContext('2d'), viewport: vp }).promise;
        dataUrl = canvas.toDataURL('image/jpeg', 0.85);
        try { localStorage.setItem(cacheKey, dataUrl); } catch (_) {}
      }

      if (slotEl.isConnected) {
        slotEl.innerHTML = `<img src="${dataUrl}" alt="" style="width:100%;height:100%;object-fit:cover;display:block;">`;
      }
    } catch (_) { /* conserve le placeholder */ }
  },

  renderPdfThumbs(rootEl) {
    rootEl.querySelectorAll('.pdf-thumb-slot').forEach(slot => {
      const resume = (Store.state.textResumes || []).find(r => String(r.id) === slot.dataset.rid);
      if (resume && resume.pdfUrl) this._pdfThumb(resume, slot);
    });
  },

  render() {
    const el = document.getElementById('page-resumes');
    const resumes = Store.state.textResumes || [];
    const categories = API.getCategories(Store.state.teachings);
    const typeCultes = Store.getTypeCultes();
    const s = Store.state;

    if (s.isLoading && !resumes.length) {
      el.innerHTML = `
        ${Skeleton.pageHeader()}
        <div class="resumes-grid" style="padding:0 40px 32px;">
          ${Array(6).fill(Skeleton.resumeCard()).join('')}
        </div>
      `;
      return;
    }

    const filtered = this.filterResumes(resumes);

    el.innerHTML = `
      <div class="page-header">
        <h1>R\u00e9sum\u00e9s</h1>
        <p>${resumes.length} r\u00e9sum\u00e9${resumes.length !== 1 ? 's' : ''} de textes</p>
      </div>

      ${s.isOffline ? `
        <div class="offline-banner" style="margin:0 40px 16px;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <span>Donn\u00e9es en cache \u2014 mode hors ligne</span>
        </div>
      ` : ''}

      <div class="search-bar" style="margin:0 40px 16px;">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
        <input type="text" id="resumes-search" placeholder="Rechercher un r\u00e9sum\u00e9..." value="${this.searchQuery}" oninput="ResumesPage.onSearch(this.value)">
        <button class="search-clear ${this.searchQuery ? 'visible' : ''}" onclick="ResumesPage.clearSearch()">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>

      ${categories.length > 0 ? `
        <div class="filter-row" style="padding:0 40px 4px;">
          <div class="filter-pill ${!this.selectedCategory ? 'active' : ''}" onclick="ResumesPage.filterCategory(null)">Tout</div>
          ${categories.map(c => `
            <div class="filter-pill ${this.selectedCategory === c ? 'active' : ''}" onclick="ResumesPage.filterCategory('${c}')">${c}</div>
          `).join('')}
        </div>
      ` : ''}
      ${typeCultes.length > 0 ? `
        <div class="filter-row" style="padding:0 40px 12px;">
          <div class="filter-pill ${!this.selectedTypeCulte ? 'active' : ''}" onclick="ResumesPage.filterTypeCulte(null)">Tous</div>
          ${typeCultes.map(t => `
            <div class="filter-pill ${this.selectedTypeCulte === t ? 'active' : ''}" onclick="ResumesPage.filterTypeCulte('${t}')">${t}</div>
          `).join('')}
        </div>
      ` : ''}

      <div id="resumes-content">
        ${filtered.length === 0 ? `
          <div class="empty-state">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
            <h3>Aucun r\u00e9sum\u00e9 trouv\u00e9</h3>
            <p>Essayez de modifier vos filtres de recherche.</p>
          </div>
        ` : `
          <div class="resumes-grid" style="padding:0 40px 32px;">
            ${filtered.map(r => this.renderResumeCard(r)).join('')}
          </div>
        `}
      </div>
    `;

    this.renderPdfThumbs(el);
  },

  filterResumes(resumes) {
    let filtered = [...resumes];
    if (this.searchQuery) {
      const q = this.searchQuery.toLowerCase();
      filtered = filtered.filter(r =>
        (r.title || '').toLowerCase().includes(q) ||
        (r.speaker || '').toLowerCase().includes(q) ||
        (r.description || '').toLowerCase().includes(q) ||
        (r.category || '').toLowerCase().includes(q) ||
        (r.typeCulte || '').toLowerCase().includes(q)
      );
    }
    if (this.selectedCategory) {
      filtered = filtered.filter(r => r.category === this.selectedCategory);
    }
    if (this.selectedTypeCulte) {
      filtered = filtered.filter(r => r.typeCulte === this.selectedTypeCulte);
    }
    return filtered.sort((a, b) => new Date(b.publishedAt || b.createdAt) - new Date(a.publishedAt || a.createdAt));
  },

  onSearch(value) {
    this.searchQuery = value;
    const clearBtn = document.querySelector('.search-clear');
    if (clearBtn) clearBtn.classList.toggle('visible', value.length > 0);
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      this.render();
    }, 300);
  },

  clearSearch() {
    this.searchQuery = '';
    const input = document.getElementById('resumes-search');
    if (input) input.value = '';
    document.querySelector('.search-clear')?.classList.remove('visible');
    this.render();
  },

  filterCategory(category) {
    this.selectedCategory = category;
    this.render();
  },

  filterTypeCulte(typeCulte) {
    this.selectedTypeCulte = typeCulte;
    this.render();
  },

  getSpeakerInitials(name) {
    if (!name) return '?';
    return name.split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
  },

  getSpeakerColor(name) {
    const colors = [
      'var(--accent)', '#6c5ce7', '#fd79a8', '#00b894',
      '#e17055', '#0984e3', '#fdcb6e', '#e84393'
    ];
    let hash = 0;
    for (let i = 0; i < (name || '').length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  },

  formatDate(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    const months = ['Jan','F\u00e9v','Mar','Avr','Mai','Juin','Juil','Ao\u00fb','Sep','Oct','Nov','D\u00e9c'];
    return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
  },

  renderResumeCard(resume) {
    const hasPdf = resume.pdfUrl || resume.pdfPublicId;
    const thumbnailUrl = this.getPdfThumbnailUrl(resume);
    const initials = this.getSpeakerInitials(resume.speaker);
    const speakerColor = this.getSpeakerColor(resume.speaker);
    const clickHandler = hasPdf ? `onclick="ResumesPage.openPdf('${resume.pdfUrl}')"` : '';

    return `
      <div class="resume-book-card" ${clickHandler}>
        <div class="resume-book-cover">
          ${thumbnailUrl ? `
            <img src="${thumbnailUrl}" alt="${resume.title}" loading="lazy" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
            <div class="resume-book-placeholder" style="display:none;">
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
            </div>
          ` : `
            <div class="pdf-thumb-slot" data-rid="${resume.id}" style="width:100%;height:100%;">
              <div class="resume-book-placeholder">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
              </div>
            </div>
          `}
          ${hasPdf ? `<div class="resume-book-play"><svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg></div>` : ''}
        </div>
        <div class="resume-book-body">
          <div class="resume-book-speaker">
            ${resume.coverImageUrl ? `
              <img src="${resume.coverImageUrl}" class="resume-book-avatar-img" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
              <div class="resume-book-avatar" style="background:${speakerColor};display:none;">${initials}</div>
            ` : `
              <div class="resume-book-avatar" style="background:${speakerColor};">${initials}</div>
            `}
            <div class="resume-book-meta">
              <p class="resume-book-title">${resume.title}</p>
              <p class="resume-book-author">${resume.speaker || 'Inconnu'}</p>
            </div>
          </div>
          <p class="resume-book-desc">${resume.description || ''}</p>
          <div class="resume-book-footer">
            ${resume.category ? `<span class="resume-book-tag">${resume.category}</span>` : ''}
            ${resume.pageCount ? `<span class="resume-book-stat">${resume.pageCount} p.</span>` : ''}
            ${resume.viewCount ? `<span class="resume-book-stat">${resume.viewCount} vues</span>` : ''}
            ${resume.publishedAt ? `<span class="resume-book-date">${this.formatDate(resume.publishedAt)}</span>` : ''}
          </div>
        </div>
      </div>
    `;
  },
};
