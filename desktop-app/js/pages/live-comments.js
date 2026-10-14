const LiveComments = {
  liveId: null,
  comments: [],
  pollTimer: null,
  replyingTo: null,
  editingId: null,
  collapsed: new Set(),
  lastJson: '',

  escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  },

  getUser() {
    return (typeof Store !== 'undefined' && Store.state.user) || null;
  },

  userName() {
    const u = this.getUser();
    return (u && u.name) || 'Anonyme';
  },

  userAvatar() {
    const u = this.getUser();
    return (u && u.profileImageUrl) || '';
  },

  avatarHtml(name, size = 40, avatarUrl = '') {
    if (avatarUrl) {
      return `<div class="lc-avatar lc-avatar-img" style="width:${size}px;height:${size}px;"><img src="${this.escapeHtml(avatarUrl)}" alt="${this.escapeHtml(name)}" onerror="this.parentElement.outerHTML=LiveComments.avatarHtml('${this.escapeHtml(name)}', ${size}, '')"></div>`;
    }
    const letter = (name || 'A').trim()[0].toUpperCase();
    return `<div class="lc-avatar" style="width:${size}px;height:${size}px;font-size:${Math.round(size * 0.42)}px;">${this.escapeHtml(letter)}</div>`;
  },

  timeAgo(dateStr) {
    if (!dateStr) return '';
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return "À l'instant";
    if (mins < 60) return `il y a ${mins} min`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `il y a ${hours} h`;
    const days = Math.floor(hours / 24);
    return `il y a ${days} j`;
  },

  async mount(liveId) {
    this.liveId = liveId;
    this.comments = [];
    this.replyingTo = null;
    this.editingId = null;
    this.collapsed.clear();
    this.lastJson = '';
    await this.load();
    this.startPolling();
  },

  unmount() {
    this.stopPolling();
    this.liveId = null;
    this.comments = [];
  },

  startPolling() {
    this.stopPolling();
    this.pollTimer = setInterval(() => this.load(), 6000);
  },

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  },

  async load() {
    if (!this.liveId) return;
    try {
      const res = await API.getComments(this.liveId);
      const json = JSON.stringify(res.comments || []);
      if (json === this.lastJson) return;
      // Ne pas re-render si l'utilisateur est en train d'écrire
      if (document.querySelector('.lc-input textarea:focus, .lc-edit-area:focus')) return;
      this.lastJson = json;
      this.comments = res.comments || [];
      this.render();
    } catch (_) {}
  },

  render() {
    const container = document.getElementById('liveCommentsSection');
    if (!container) return;
    container.innerHTML = `
      <div class="lc-header">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
        <span>Commentaires</span>
        <span class="lc-count">${this.countAll(this.comments)}</span>
      </div>
      ${this.renderInput('lc-top-input')}
      <div class="lc-thread">
        ${this.comments.length === 0 ? `
          <div class="lc-empty">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
            <p>Aucun commentaire. Soyez le premier à réagir !</p>
          </div>
        ` : this.comments.map(c => this.renderComment(c, 0)).join('')}
      </div>
    `;
  },

  countAll(list) {
    return (list || []).reduce((n, c) => n + 1 + this.countAll(c.replies), 0);
  },

  renderInput(idSuffix, placeholder = 'Rejoignez la conversation…') {
    return `
      <div class="lc-input" id="${idSuffix}">
        ${this.avatarHtml(this.userName(), 32, this.userAvatar())}
        <div class="lc-input-body">
          <textarea rows="1" placeholder="${placeholder}" onkeydown="LiveComments.onInputKey(event, '${idSuffix}')" oninput="this.style.height='auto';this.style.height=Math.min(this.scrollHeight,120)+'px'"></textarea>
          <div class="lc-input-actions">
            <button class="lc-btn-cancel" onclick="LiveComments.cancelInput('${idSuffix}')">Annuler</button>
            <button class="lc-btn-send" onclick="LiveComments.submitInput('${idSuffix}')" title="Envoyer">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>
            </button>
          </div>
        </div>
      </div>
    `;
  },

  renderComment(c, level) {
    const isCollapsed = this.collapsed.has(c.id);
    const hasReplies = (c.replies || []).length > 0;
    const isEditing = this.editingId === c.id;
    const isReplying = this.replyingTo === c.id;
    const isMine = this.getUser() && c.userId === this.getUser().id;

    return `
      <div class="lc-item ${level > 0 ? 'lc-item-reply' : ''}">
        ${hasReplies && !isCollapsed ? '<div class="lc-thread-line"></div>' : ''}
        ${level > 0 ? '<div class="lc-thread-stub"></div>' : ''}
        <div class="lc-row">
          <div class="lc-avatar-col">
            ${isCollapsed
              ? `<div class="lc-avatar lc-avatar-collapsed" onclick="LiveComments.toggleCollapse('${c.id}')" title="Déplier">
                   <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M10.625 9.375H14v1.25h-3.375V14h-1.25v-3.375H6v-1.25h3.375V6h1.25v3.375ZM20 10A10 10 0 1 1 10 0a10.011 10.011 0 0 1 10 10Zm-1.25 0A8.75 8.75 0 1 0 10 18.75 8.76 8.76 0 0 0 18.75 10Z"/></svg>
                 </div>`
              : this.avatarHtml(c.author, 40, c.avatar)}
          </div>
          <div class="lc-body">
            <div class="lc-meta">
              <span class="lc-author">${this.escapeHtml(c.author)}</span>
              <span class="lc-dot">•</span>
              <span class="lc-time">${this.timeAgo(c.createdAt)}</span>
            </div>
            ${isEditing ? `
              <div class="lc-edit-box">
                <textarea class="lc-edit-area" rows="3">${this.escapeHtml(c.content)}</textarea>
                <div class="lc-edit-actions">
                  <button class="lc-btn-save" onclick="LiveComments.saveEdit('${c.id}', this)">Enregistrer</button>
                  <button class="lc-btn-cancel" onclick="LiveComments.cancelEdit()">Annuler</button>
                </div>
              </div>
            ` : (!isCollapsed ? `<div class="lc-content">${this.escapeHtml(c.content)}</div>` : '')}
            ${!isCollapsed ? `
              <div class="lc-actions">
                ${hasReplies ? `
                  <button class="lc-collapse-btn" onclick="LiveComments.toggleCollapse('${c.id}')" title="Réduire">
                    <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M14 10.625H6v-1.25h8v1.25ZM20 10a10 10 0 1 0-10 10 10.011 10.011 0 0 0 10-10Zm-1.25 0A8.75 8.75 0 1 1 10 1.25 8.76 8.76 0 0 1 18.75 10Z"/></svg>
                  </button>` : ''}
                <button class="lc-vote" onclick="LiveComments.vote('${c.id}', 1, this)" title="Vote positif">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M10 19c-.072 0-.145 0-.218-.006A4.1 4.1 0 0 1 6 14.816V11H2.862a1.751 1.751 0 0 1-1.234-2.993L9.41.28a.836.836 0 0 1 1.18 0l7.782 7.727A1.751 1.751 0 0 1 17.139 11H14v3.882a4.134 4.134 0 0 1-.854 2.592A3.99 3.99 0 0 1 10 19Zm0-17.193L2.685 9.071a.251.251 0 0 0 .177.429H7.5v5.316A2.63 2.63 0 0 0 9.864 17.5a2.441 2.441 0 0 0 1.856-.682A2.478 2.478 0 0 0 12.5 15V9.5h4.639a.25.25 0 0 0 .176-.429L10 1.807Z"/></svg>
                </button>
                <span class="lc-votes">${c.votes || 0}</span>
                <button class="lc-vote" onclick="LiveComments.vote('${c.id}', -1, this)" title="Vote négatif">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor"><path d="M10 1c.072 0 .145 0 .218.006A4.1 4.1 0 0 1 14 5.184V9h3.138a1.751 1.751 0 0 1 1.234 2.993L10.59 19.72a.836.836 0 0 1-1.18 0l-7.782-7.727A1.751 1.751 0 0 1 2.861 9H6V5.118a4.134 4.134 0 0 1 .854-2.592A3.99 3.99 0 0 1 10 1Zm0 17.193 7.315-7.264a.251.251 0 0 0-.177-.429H12.5V5.184A2.631 2.631 0 0 0 10.136 2.5a2.441 2.441 0 0 0-1.856.682A2.478 2.478 0 0 0 7.5 5v5.5H2.861a.251.251 0 0 0-.176.429L10 18.193Z"/></svg>
                </button>
                <button class="lc-action" onclick="LiveComments.startReply('${c.id}')">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
                  Répondre
                </button>
                ${isMine ? `
                  <button class="lc-action" onclick="LiveComments.startEdit('${c.id}')" title="Modifier">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                  </button>
                  <button class="lc-action lc-action-danger" onclick="LiveComments.remove('${c.id}')" title="Supprimer">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
                  </button>` : ''}
              </div>
              ${isReplying ? `<div class="lc-reply-box">${this.renderInput('lc-reply-' + c.id, 'Écrivez une réponse…')}</div>` : ''}
            ` : `<div class="lc-collapsed-hint">${hasReplies ? `${c.replies.length} réponse(s)` : ''}</div>`}
          </div>
        </div>
        ${hasReplies && !isCollapsed ? `
          <div class="lc-children">
            ${c.replies.map(r => this.renderComment(r, level + 1)).join('')}
          </div>
        ` : ''}
      </div>
    `;
  },

  findComment(id, list = this.comments) {
    for (const c of list) {
      if (c.id === id) return c;
      const f = this.findComment(id, c.replies);
      if (f) return f;
    }
    return null;
  },

  onInputKey(e, idSuffix) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      this.submitInput(idSuffix);
    }
    if (e.key === 'Escape') this.cancelInput(idSuffix);
  },

  async submitInput(idSuffix) {
    const box = document.getElementById(idSuffix);
    const ta = box?.querySelector('textarea');
    const content = (ta?.value || '').trim();
    if (!content) return;

    const u = this.getUser();
    const parentId = idSuffix.startsWith('lc-reply-') ? idSuffix.replace('lc-reply-', '') : null;

    try {
      const res = await API.postComment(this.liveId, {
        content,
        author: this.userName(),
        userId: u ? u.id : null,
        avatar: this.userAvatar(),
        parentId,
      });
      if (res.comment) {
        this.insertComment(res.comment, parentId);
        this.replyingTo = null;
        this.lastJson = JSON.stringify(this.comments);
        this.render();
      }
    } catch (err) {
      App.showToast('Erreur: ' + (err.message || 'envoi impossible'));
    }
  },

  insertComment(comment, parentId) {
    const node = { ...comment, replies: [] };
    if (!parentId) {
      this.comments.unshift(node);
      return;
    }
    const parent = this.findComment(parentId);
    if (parent) parent.replies.push(node);
  },

  cancelInput(idSuffix) {
    const box = document.getElementById(idSuffix);
    const ta = box?.querySelector('textarea');
    if (ta) ta.value = '';
    if (idSuffix.startsWith('lc-reply-')) {
      this.replyingTo = null;
      this.render();
    }
  },

  startReply(commentId) {
    this.replyingTo = this.replyingTo === commentId ? null : commentId;
    this.editingId = null;
    this.render();
    const box = document.getElementById('lc-reply-' + commentId);
    box?.querySelector('textarea')?.focus();
  },

  startEdit(commentId) {
    this.editingId = commentId;
    this.replyingTo = null;
    this.render();
  },

  cancelEdit() {
    this.editingId = null;
    this.render();
  },

  async saveEdit(commentId, btn) {
    const box = btn.closest('.lc-edit-box');
    const ta = box?.querySelector('textarea');
    const content = (ta?.value || '').trim();
    if (!content) return;
    try {
      const res = await API.updateComment(this.liveId, commentId, content);
      const c = this.findComment(commentId);
      if (c && res.comment) c.content = res.comment.content;
      this.editingId = null;
      this.lastJson = JSON.stringify(this.comments);
      this.render();
    } catch (err) {
      App.showToast('Erreur: ' + (err.message || 'modification impossible'));
    }
  },

  async vote(commentId, delta, btn) {
    const c = this.findComment(commentId);
    if (c) {
      c.votes = (c.votes || 0) + delta;
      const span = btn.parentElement.querySelector('.lc-votes');
      if (span) span.textContent = c.votes;
    }
    try {
      await API.voteComment(this.liveId, commentId, delta);
    } catch (_) {}
  },

  async remove(commentId) {
    if (!confirm('Supprimer ce commentaire et ses réponses ?')) return;
    try {
      await API.deleteComment(this.liveId, commentId);
      this.removeFromTree(commentId);
      this.lastJson = JSON.stringify(this.comments);
      this.render();
    } catch (err) {
      App.showToast('Erreur: ' + (err.message || 'suppression impossible'));
    }
  },

  removeFromTree(id, list = this.comments) {
    const i = list.findIndex(c => c.id === id);
    if (i !== -1) {
      list.splice(i, 1);
      return true;
    }
    return list.some(c => this.removeFromTree(id, c.replies));
  },

  toggleCollapse(commentId) {
    if (this.collapsed.has(commentId)) this.collapsed.delete(commentId);
    else this.collapsed.add(commentId);
    this.render();
  },
};
