const Skeleton = {
  teachingCard() {
    return `
      <div class="skeleton-card">
        <div class="skeleton skeleton-card-artwork"></div>
        <div class="skeleton-card-body">
          <div class="skeleton skeleton-line"></div>
          <div class="skeleton skeleton-line-sm"></div>
        </div>
      </div>
    `;
  },

  horizontalList(count = 4) {
    return `
      <div class="skeleton-horizontal-list">
        ${Array(count).fill(this.teachingCard()).join('')}
      </div>
    `;
  },

  section(title, content) {
    return `
      <div class="skeleton-section">
        <div class="skeleton-section-header">
          <div class="skeleton skeleton-section-icon"></div>
          <div class="skeleton skeleton-section-title"></div>
        </div>
        ${content}
      </div>
    `;
  },

  teachingListItem() {
    return `
      <div class="skeleton-list-item">
        <div class="skeleton skeleton-list-artwork"></div>
        <div class="skeleton-list-body">
          <div class="skeleton skeleton-line"></div>
          <div class="skeleton skeleton-line-sm"></div>
        </div>
        <div class="skeleton skeleton-list-artwork" style="width:32px;height:20px;border-radius:4px;"></div>
      </div>
    `;
  },

  liveHeroCard() {
    return `
      <div class="skeleton-hero-card">
        <div class="skeleton skeleton-hero-artwork"></div>
        <div class="skeleton-hero-body">
          <div class="skeleton skeleton-line" style="width:60%;height:20px;"></div>
          <div class="skeleton skeleton-line-sm"></div>
          <div class="skeleton skeleton-line-sm" style="width:40%;"></div>
          <div class="skeleton" style="width:160px;height:40px;border-radius:10px;margin-top:4px;"></div>
        </div>
      </div>
    `;
  },

  liveGridCard() {
    return `
      <div class="skeleton-grid-card" style="flex-direction:column;">
        <div class="skeleton" style="width:100%;height:120px;border-radius:8px;"></div>
        <div class="skeleton skeleton-line" style="width:70%;height:16px;"></div>
        <div class="skeleton skeleton-line-sm"></div>
      </div>
    `;
  },

  liveGrid(count = 3) {
    return `
      <div style="display:grid;gap:16px;">
        ${Array(count).fill(this.liveGridCard()).join('')}
      </div>
    `;
  },

  scheduledCard() {
    return `
      <div class="skeleton-list-item">
        <div class="skeleton skeleton-list-artwork" style="border-radius:8px;"></div>
        <div class="skeleton-list-body">
          <div class="skeleton skeleton-line"></div>
          <div class="skeleton skeleton-line-sm"></div>
        </div>
      </div>
    `;
  },

  scheduledList(count = 3) {
    return `
      <div style="display:grid;gap:8px;">
        ${Array(count).fill(this.scheduledCard()).join('')}
      </div>
    `;
  },

  resumeCard() {
    return `
      <div class="resume-book-card" style="pointer-events:none;">
        <div class="skeleton" style="aspect-ratio:2/3;width:100%;border-radius:12px 12px 0 0;"></div>
        <div style="padding:12px;">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px;">
            <div class="skeleton" style="width:32px;height:32px;border-radius:50%;flex-shrink:0;"></div>
            <div style="flex:1;">
              <div class="skeleton skeleton-line" style="width:80%;"></div>
              <div class="skeleton skeleton-line-sm" style="width:50%;"></div>
            </div>
          </div>
          <div class="skeleton skeleton-line-sm" style="width:100%;"></div>
          <div class="skeleton skeleton-line-sm" style="width:60%;"></div>
        </div>
      </div>
    `;
  },

  resumeList(count = 4) {
    return `
      <div class="resumes-grid" style="padding:0 40px 32px;">
        ${Array(count).fill(this.resumeCard()).join('')}
      </div>
    `;
  },

  eventCard() {
    return `
      <div class="skeleton-list-item">
        <div class="skeleton" style="width:4px;height:40px;border-radius:4px;flex-shrink:0;"></div>
        <div class="skeleton-list-body">
          <div class="skeleton skeleton-line" style="width:60%;"></div>
          <div class="skeleton skeleton-line-sm"></div>
          <div class="skeleton skeleton-line-xs"></div>
        </div>
        <div class="skeleton" style="width:60px;height:22px;border-radius:6px;flex-shrink:0;"></div>
      </div>
    `;
  },

  eventList(count = 4) {
    return `
      <div class="skeleton-calendar-list">
        ${Array(count).fill(this.eventCard()).join('')}
      </div>
    `;
  },

  packageCard() {
    return `
      <div class="skeleton-pkg-card">
        <div class="skeleton skeleton-pkg-icon"></div>
        <div class="skeleton skeleton-pkg-line"></div>
        <div class="skeleton skeleton-pkg-line-sm"></div>
      </div>
    `;
  },

  packageGrid(count = 4) {
    return `
      <div style="display:flex;gap:12px;padding:0 40px;overflow:hidden;">
        ${Array(count).fill(this.packageCard()).join('')}
        <div class="skeleton-pkg-card" style="border-style:dashed;opacity:0.5;">
          <div class="skeleton skeleton-pkg-icon"></div>
          <div class="skeleton skeleton-pkg-line" style="width:60%;"></div>
        </div>
      </div>
    `;
  },

  profileStats() {
    return `
      <div class="skeleton-stat-row">
        <div class="skeleton-stat-card">
          <div class="skeleton skeleton-stat-icon"></div>
          <div class="skeleton skeleton-stat-value"></div>
          <div class="skeleton skeleton-stat-label"></div>
        </div>
        <div class="skeleton-stat-card">
          <div class="skeleton skeleton-stat-icon"></div>
          <div class="skeleton skeleton-stat-value"></div>
          <div class="skeleton skeleton-stat-label"></div>
        </div>
        <div class="skeleton-stat-card">
          <div class="skeleton skeleton-stat-icon"></div>
          <div class="skeleton skeleton-stat-value"></div>
          <div class="skeleton skeleton-stat-label"></div>
        </div>
      </div>
    `;
  },

  categoryGrid(count = 6) {
    return `
      <div class="skeleton-section">
        <div class="skeleton-section-header">
          <div class="skeleton skeleton-section-icon"></div>
          <div class="skeleton skeleton-section-title"></div>
        </div>
        <div class="skeleton-category-grid">
          ${Array(count).fill(`
            <div class="skeleton-category-card">
              <div class="skeleton skeleton-category-icon"></div>
              <div class="skeleton skeleton-pkg-line" style="width:70%;"></div>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  },

  pageHeader() {
    return `
      <div class="page-header">
        <h1><div class="skeleton" style="width:200px;height:28px;border-radius:6px;"></div></h1>
        <p><div class="skeleton" style="width:260px;height:16px;border-radius:4px;margin-top:6px;"></div></p>
      </div>
    `;
  },
};
