const Notifications = {
  unsubscribe: null,

  init() {
    if (typeof window.electronAPI?.onNotification !== 'function') {
      console.warn('⚠️ Notification IPC non disponible');
      return;
    }

    this.unsubscribe = window.electronAPI.onNotification((data) => {
      this.show(data);
    });

    console.log('✅ Notifications écoute active');
  },

  show(data) {
    console.log(`📬 Notification: ${data.title} - ${data.body}`);

    SoundManager.playNotification();
    App.showToast(`${data.title}: ${data.body}`);

    this._refreshContent(data);

    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        const notif = new Notification(data.title, {
          body: data.body,
          icon: 'logo.png',
        });
        notif.onclick = () => {
          window.focus();
        };
      } catch (e) {
        // Le renderer n'a pas toujours accès à Notification selon le contexte
      }
    }
  },

  _refreshContent(data) {
    const type = data.data?.type || '';
    const loaders = {
      teaching: () => Store.loadTeachings(),
      text_resume: () => Store.loadTextResumes(),
      annonce: () => Store.loadAnnonces(),
      calendar: () => Store.loadCalendarEvents(),
    };
    const loader = loaders[type];
    if (loader) {
      loader().then(() => {
        App.reRenderCurrentPage();
      }).catch(() => {});
    }
  },

  destroy() {
    if (this.unsubscribe) {
      this.unsubscribe();
      this.unsubscribe = null;
    }
  },
};
