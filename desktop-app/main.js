const { app, BrowserWindow, ipcMain, Notification, Tray, Menu, nativeImage, shell, protocol, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// ── Mises à jour automatiques (electron-updater) ──────────────
let autoUpdater = null;
try {
  autoUpdater = require('electron-updater').autoUpdater;
} catch {
  console.warn('⚠️ electron-updater non disponible');
}

function setupAutoUpdate() {
  // Uniquement dans l'app packagée (pas en `npm start` / dev)
  if (!autoUpdater || !app.isPackaged) return;

  autoUpdater.autoDownload = true;
  autoUpdater.autoInstallOnAppQuit = true;
  autoUpdater.logger = console;

  autoUpdater.on('update-available', (info) => {
    console.log(`⬇️ Mise à jour ${info.version} — téléchargement en cours...`);
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('update-status', { status: 'downloading', version: info.version });
    }
  });

  autoUpdater.on('update-not-available', () => {
    console.log('✅ MyKOG est à jour');
  });

  autoUpdater.on('download-progress', (p) => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('update-status', { status: 'progress', percent: Math.round(p.percent) });
    }
  });

  autoUpdater.on('update-downloaded', async (info) => {
    console.log(`✅ Mise à jour ${info.version} prête à installer`);
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('update-status', { status: 'downloaded', version: info.version });
    }
    try {
      const { response } = await dialog.showMessageBox({
        type: 'info',
        title: 'Mise à jour MyKOG',
        message: `La version ${info.version} a été téléchargée.`,
        detail: 'Redémarrer maintenant pour l\'installer ?',
        buttons: ['Redémarrer maintenant', 'Plus tard'],
        defaultId: 0,
        cancelId: 1,
      });
      if (response === 0) {
        isQuitting = true;
        autoUpdater.quitAndInstall();
      }
      // "Plus tard" → installée automatiquement à la prochaine fermeture
    } catch (err) {
      console.warn('⚠️ Dialog mise à jour:', err.message);
    }
  });

  autoUpdater.on('error', (err) => {
    console.warn('⚠️ Auto-update erreur:', err.message);
  });

  // Vérification au démarrage + toutes les 4h
  autoUpdater.checkForUpdates().catch(() => {});
  setInterval(() => autoUpdater.checkForUpdates().catch(() => {}), 4 * 3600 * 1000);
}

let mainWindow;
let tray = null;
let firestoreUnsubscribe = null;
let isQuitting = false;
let db = null;
let firestoreRetryCount = 0;
const MAX_FIRESTORE_RETRIES = 10;
let firestoreRetryTimeout = null;

function initFirebaseAdmin() {
  try {
    const admin = require('firebase-admin');

    const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '')
      .replace(/\\n/g, '\n');

    if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !privateKey) {
      console.warn('⚠️ Firebase Admin non configuré (vars .env manquantes). Les notifications ne fonctionneront pas.');
      return;
    }

    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey,
        }),
      });
      console.log('✅ Firebase Admin SDK initialisé (desktop)');
    }

    db = admin.firestore();
    db.settings({ ignoreUndefinedProperties: true });
  } catch (error) {
    console.error('❌ Erreur initialisation Firebase Admin:', error.message);
  }
}

function scheduleFirestoreRetry() {
  if (firestoreRetryCount >= MAX_FIRESTORE_RETRIES) {
    console.error(`❌ Abandon après ${MAX_FIRESTORE_RETRIES} tentatives de reconnexion Firestore`);
    return;
  }
  const delay = Math.min(1000 * Math.pow(2, firestoreRetryCount), 30000);
  firestoreRetryCount++;
  console.log(`🔄 Reconnexion Firestore dans ${delay / 1000}s (tentative ${firestoreRetryCount}/${MAX_FIRESTORE_RETRIES})`);
  if (firestoreRetryTimeout) clearTimeout(firestoreRetryTimeout);
  firestoreRetryTimeout = setTimeout(setupNotificationsListener, delay);
}

function setupNotificationsListener() {
  if (!db) return;

  if (firestoreUnsubscribe) {
    firestoreUnsubscribe();
    firestoreUnsubscribe = null;
  }

  const processedIds = new Set();
  let isInitialSnapshot = true;

  try {
    firestoreUnsubscribe = db.collection('notifications_outbox')
      .orderBy('createdAt', 'desc')
      .limit(50)
      .onSnapshot((snapshot) => {
        firestoreRetryCount = 0;
        if (isInitialSnapshot) {
          snapshot.docs.forEach((doc) => processedIds.add(doc.id));
          isInitialSnapshot = false;
          console.log(`👂 Écoute des notifications démarrée (${processedIds.size} existantes)`);
          return;
        }

        snapshot.docChanges().forEach((change) => {
          if (change.type !== 'added') return;
          if (processedIds.has(change.doc.id)) return;

          processedIds.add(change.doc.id);
          const data = change.doc.data();
          const notificationData = {
            id: change.doc.id,
            title: data.title || 'MyKOG',
            body: data.body || '',
            data: data.data || {},
            imageUrl: data.imageUrl || null,
          };

          console.log(`📬 Nouvelle notification reçue: ${notificationData.title}`);

          const windowVisible = mainWindow && !mainWindow.isDestroyed() && mainWindow.isVisible() && !mainWindow.isMinimized();

          if (windowVisible) {
            mainWindow.webContents.send('new-notification', notificationData);
          }

          if (!windowVisible) {
            try {
              const notif = new Notification({
                title: notificationData.title,
                body: notificationData.body,
                icon: path.join(__dirname, 'logo.png'),
              });
              notif.on('click', () => {
                if (mainWindow && !mainWindow.isDestroyed()) {
                  if (mainWindow.isMinimized()) mainWindow.restore();
                  mainWindow.show();
                  mainWindow.focus();
                }
              });
              notif.show();
            } catch (err) {
              console.warn('⚠️ Erreur notification native:', err.message);
            }
          }
        });
      }, (error) => {
        console.error('❌ Erreur listener Firestore:', error.message);
        if (firestoreUnsubscribe) {
          firestoreUnsubscribe();
          firestoreUnsubscribe = null;
        }
        scheduleFirestoreRetry();
      });
  } catch (error) {
    console.error('❌ Erreur setup listener notifications:', error.message);
    scheduleFirestoreRetry();
  }
}

function createTray() {
  try {
    const iconPath = path.join(__dirname, 'logo.png');
    const trayIcon = nativeImage.createFromPath(iconPath).resize({ width: 16, height: 16 });
    tray = new Tray(trayIcon);

    const contextMenu = Menu.buildFromTemplate([
      {
        label: 'Afficher MyKOG',
        click: () => {
          if (mainWindow && !mainWindow.isDestroyed()) {
            mainWindow.show();
            mainWindow.focus();
          }
        },
      },
      { type: 'separator' },
      {
        label: 'Quitter',
        click: () => {
          isQuitting = true;
          app.quit();
        },
      },
    ]);

    tray.setToolTip('MyKOG');
    tray.setContextMenu(contextMenu);

    tray.on('click', () => {
      if (mainWindow && !mainWindow.isDestroyed()) {
        if (mainWindow.isVisible()) {
          mainWindow.hide();
        } else {
          mainWindow.show();
          mainWindow.focus();
        }
      }
    });

    console.log('✅ Tray icône créée');
  } catch (err) {
    console.warn('⚠️ Impossible de créer le tray:', err.message);
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    title: 'MyKOG',
    backgroundColor: '#000000',
    icon: path.join(__dirname, 'logo.png'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    frame: true,
    show: false,
  });

  mainWindow.loadFile('index.html');

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('close', (event) => {
    if (!isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  if (process.argv.includes('--dev')) {
    mainWindow.webContents.openDevTools();
  }
}

// ── Configuration du serveur de streaming ──────────────────────
const SERVER_CONFIG = {
  apiUrl: process.env.API_URL || 'http://185.98.128.123:3001/mykog-api',
  hlsBaseUrl: process.env.HLS_BASE_URL || 'http://185.98.128.123:3001',
};

ipcMain.handle('get-server-config', () => ({
  apiUrl: SERVER_CONFIG.apiUrl,
  hlsBaseUrl: SERVER_CONFIG.hlsBaseUrl,
}));

ipcMain.handle('get-platform', () => process.platform);

ipcMain.handle('open-pdf', async (_event, url) => {
  if (!url) return { success: false, error: 'URL manquante' };
  shell.openExternal(url);
  return { success: true };
});

// Récupère les bytes d'un PDF côté main (pas de restriction CORS)
// Utilisé pour générer la miniature de la 1ère page avec pdf.js
ipcMain.handle('fetch-pdf-bytes', async (_event, url) => {
  if (!url || typeof url !== 'string' || !/^https?:\/\//.test(url)) return null;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return Buffer.from(await res.arrayBuffer());
});

app.whenReady().then(() => {
  protocol.handle('mykog-pdf', (request) => {
    const filePath = decodeURIComponent(request.url.slice('mykog-pdf://'.length));
    try {
      const data = fs.readFileSync(filePath);
      return new Response(data, {
        status: 200,
        headers: { 'Content-Type': 'application/pdf' },
      });
    } catch {
      return new Response('Fichier non trouvé', { status: 404 });
    }
  });
  Menu.setApplicationMenu(null);
  initFirebaseAdmin();
  createWindow();
  createTray();
  setupNotificationsListener();
  setupAutoUpdate();
});

app.on('before-quit', () => {
  isQuitting = true;
  if (firestoreUnsubscribe) {
    firestoreUnsubscribe();
    firestoreUnsubscribe = null;
  }
  if (firestoreRetryTimeout) {
    clearTimeout(firestoreRetryTimeout);
    firestoreRetryTimeout = null;
  }
});

app.on('window-all-closed', () => {
  // Ne pas quitter, laisser le tray gérer
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
    setupNotificationsListener();
  } else if (mainWindow) {
    mainWindow.show();
    mainWindow.focus();
  }
});
