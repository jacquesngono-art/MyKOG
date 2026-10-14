const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  platform: process.platform,

  getServerConfig: () => ipcRenderer.invoke('get-server-config'),

  onNotification: (callback) => {
    const listener = (_event, data) => callback(data);
    ipcRenderer.on('new-notification', listener);
    return () => ipcRenderer.removeListener('new-notification', listener);
  },

  openPdf: (url) => ipcRenderer.invoke('open-pdf', url),

  fetchPdfBytes: (url) => ipcRenderer.invoke('fetch-pdf-bytes', url),
});
