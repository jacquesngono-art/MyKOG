const DownloadsPage = {
  render() {
    const el = document.getElementById('page-downloads');
    if (!el) return;
    const teachings = Store.getDownloadedTeachings();
    const s = Store.state;

    el.innerHTML = `
      <div class="page-header">
        <h1>Téléchargements</h1>
        <p>${teachings.length} enseignement${teachings.length !== 1 ? 's' : ''} disponible${teachings.length !== 1 ? 's' : ''} hors ligne</p>
      </div>

      ${s.isOffline ? `
        <div class="offline-banner">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <span>Mode hors ligne — contenu disponible</span>
        </div>
      ` : ''}

      ${teachings.length === 0 ? `
        <div class="empty-state">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <h3>Aucun téléchargement</h3>
          <p>Téléchargez des enseignements pour les écouter hors ligne.</p>
        </div>
      ` : `
        <div class="teaching-list">
          ${teachings.map(t => LibraryPage.renderListItem(t)).join('')}
        </div>
      `}
    `;
  },
};
