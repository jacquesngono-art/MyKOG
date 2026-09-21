# Bilan complet – backend-API (Express)

## Structure du projet

```
backend-API/
├── package.json
├── server.js
├── .env
├── .env.render
├── veilleur.js
├── GUIDE_REDEMARRAGE_SERVEUR.md
├── README_RENDER.md
├── RAILWAY_ENV_VARS.txt
├── TROUBLESHOOTING_NOTIFICATIONS.md
├── render.yaml
├── restart-server.sh
├── kill-server.sh
├── hls/                    (dossier HLS)
├── public/
│   └── admin-dashboard.html
├── config/
│   ├── firebase.js
│   └── cloudinary.js
├── middleware/
│   └── upload.js
├── controllers/
│   ├── enseignementController.js
│   ├── annonceController.js
│   ├── liveController.js
│   ├── calendarController.js
│   ├── userController.js
│   ├── notificationController.js
│   └── textResumeController.js
├── routes/
│   ├── enseignements.js
│   ├── annonces.js
│   ├── lives.js
│   ├── calendar.js
│   ├── users.js
│   ├── notifications.js
│   └── textResumes.js
├── services/
│   ├── r2Service.js
│   └── streamingService.js
└── utils/
    ├── ffmpeg_transcoder.js
    ├── stream_helper.js
    ├── notificationHelper.js
    └── network_detector.js
```

---

## Fichier : package.json

```json
{
  "name": "backend-api",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "veilleur": "node -e \"const Veilleur = require('./veilleur'); const v = new Veilleur(14); v.start();\"",
    "livekit:start": "bash start_livekit.sh",
    "livekit:stop": "bash stop_livekit.sh",
    "livekit:logs": "tail -f livekit.log",
    "start:all": "bash start_livekit.sh && node server.js"
  },
  "type": "commonjs",
  "dependencies": {
    "@apidevtools/swagger-parser": "^12.1.0",
    "@aws-sdk/client-s3": "^3.1073.0",
    "@aws-sdk/s3-request-presigner": "^3.1073.0",
    "cloudinary": "^1.41.3",
    "cors": "^2.8.5",
    "dotenv": "^15.0.1",
    "express": "^5.1.0",
    "firebase-admin": "^13.6.0",
    "livekit-server-sdk": "^2.15.1",
    "multer": "^2.0.2",
    "multer-storage-cloudinary": "^4.0.0",
    "node-media-server": "^4.2.8",
    "swagger-jsdoc": "^6.2.8",
    "swagger-ui-express": "^5.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.1.11"
  }
}
```

**Dépendances supplémentaires vs backend-hono :**
- `express` (Express 5) – framework HTTP
- `multer` + `multer-storage-cloudinary` – upload de fichiers
- `livekit-server-sdk` – SDK LiveKit (streaming)
- `swagger-jsdoc` + `swagger-ui-express` + `@apidevtools/swagger-parser` – documentation OpenAPI
- `cors` – middleware CORS

---

## Fichier : .env

```env
# Configuration Cloudflare R2
CF_ACCOUNT_ID=51818a41cb1910fba33adcc8f6d873e
R2_ACCESS_KEY_ID=b0d73d98669673e7e7f75b3ade9e3a95
R2_SECRET_ACCESS_KEY=f9d3b349de2ca389761a6d330e6080b7222f22bc0e3b349501e30dc2eb2a28
R2_BUCKET_NAME=my-kog-media
R2_ENDPOINT=https://51818a41cb1910fba33adcc8f6d873e.r2.cloudflarestorage.com

# Configuration Firebase
FIREBASE_TYPE=service_account
FIREBASE_PROJECT_ID=test-mykog
FIREBASE_PRIVATE_KEY_ID=86f8ea53b0aa7b534805ff624d37ff437ed7168c
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDSfjuI/V4QKTDo..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@test-mykog.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=103825715076389627267
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40test-mykog.iam.gserviceaccount.com
FIREBASE_UNIVERSE_DOMAIN=googleapis.com

# Configuration Serveur Render
PORT=3001
NODE_ENV=development
RENDER_URL=https://mykog-backend-api.onrender.com
```

---

## Fichier : server.js

```javascript
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const Veilleur = require("./veilleur");
const { startStreamingServer } = require("./services/streamingService");

const app = express();
const PORT = process.env.PORT || 3000;

// --- MIDDLEWARES ---
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir les fichiers statiques (dashboard admin + HLS)
app.use(express.static('public'));

// Servir les fichiers HLS générés par FFmpeg
const hlsOutputPath = path.join(__dirname, 'hls_output');
app.use('/hls', express.static(hlsOutputPath));

// --- ROUTES ---
app.use("/api/enseignements", require("./routes/enseignements"));
app.use("/api/annonces", require("./routes/annonces"));
app.use("/api/lives", require("./routes/lives"));
app.use("/api/calendar", require("./routes/calendar"));
app.use("/api/users", require("./routes/users"));
app.use("/api/notifications", require("./routes/notifications"));
app.use("/api/text-resumes", require("./routes/textResumes"));

// --- ROUTE DE TEST ---
app.get("/", (req, res) => {
  res.json({ message: "Serveur Enseignement API opérationnel 🚀" });
});

// --- GESTION DES ERREURS (UPLOAD / AUTRE) ---
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ error: "Fichier trop volumineux" });
    }
  }
  res.status(500).json({
    error: "Erreur interne du serveur",
    details: error.message,
  });
});

// --- DEMARRAGE SERVEUR ---
app.listen(PORT, () => {
  console.log(`Serveur lancé sur le port ${PORT}`);
  console.log(`HLS: http://localhost:${PORT}/hls/{streamKey}/index.m3u8`);

  try { startStreamingServer(); }
  catch (err) { console.error('Erreur démarrage streaming:', err.message); }

  if (process.env.NODE_ENV === 'production') {
    const veilleur = new Veilleur(14);
    veilleur.start();
  } else {
    console.log("Pour téléphone : utilise l'IP du PC + :3000");
  }
});
```

---

## Fichier : config/firebase.js

```javascript
const admin = require('firebase-admin');

const serviceAccount = {
  type: process.env.FIREBASE_TYPE,
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: process.env.FIREBASE_AUTH_URI,
  token_uri: process.env.FIREBASE_TOKEN_URI,
  auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
  client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
};

let firebaseApp;
try {
  if (admin.apps.length === 0) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('Firebase Admin SDK initialisé');
  } else {
    firebaseApp = admin.app();
    console.log('Firebase Admin SDK déjà initialisé');
  }
} catch (error) {
  console.error('Erreur initialisation Firebase:', error);
}

const db = admin.firestore();
if (db) {
  db.settings({ ignoreUndefinedProperties: true });
}

module.exports = { admin, db };
```

---

## Fichier : config/cloudinary.js

```javascript
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

module.exports = cloudinary;
```

---

## Fichier : middleware/upload.js

```javascript
const multer = require('multer');

const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    console.log('File received:', {
      fieldname: file.fieldname,
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size,
    });
    cb(null, true);
  },
  limits: {
    fileSize: 300 * 1024 * 1024, // 300 MB
  },
});

module.exports = { upload };
```

---

## Fichier : services/r2Service.js

```javascript
const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const cloudinary = require('../config/cloudinary');

const ACCOUNT_ID = process.env.CF_ACCOUNT_ID;
const ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID;
const SECRET_ACCESS_KEY = process.env.R2_SECRET_ACCESS_KEY;
const BUCKET_NAME = process.env.R2_BUCKET_NAME;
const ENDPOINT = process.env.R2_ENDPOINT;

let s3Client;

function getClient() {
  if (!s3Client) {
    if (!ACCOUNT_ID || !ACCESS_KEY_ID || !SECRET_ACCESS_KEY) {
      throw new Error('R2 non configuré');
    }
    s3Client = new S3Client({
      region: 'auto',
      endpoint: ENDPOINT || `https://${ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: { accessKeyId: ACCESS_KEY_ID, secretAccessKey: SECRET_ACCESS_KEY },
      forcePathStyle: true,
      requestHandler: new (require('@smithy/node-http-handler').NodeHttpHandler)({
        connectionTimeout: 15000,
        socketTimeout: 120000,
      }),
    });
  }
  return s3Client;
}

async function r2Upload(key, body, contentType) {
  const client = getClient();
  const command = new PutObjectCommand({ Bucket: BUCKET_NAME, Key: key, Body: body, ContentType: contentType });
  await client.send(command);
}

function generateTimestampId() {
  return `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
}

async function uploadFile(key, body, contentType) {
  try {
    await r2Upload(key, body, contentType);
    return { key, provider: 'r2' };
  } catch (err) {
    if (err.name === 'Error' && (err.message?.includes('EPROTO') || err.message?.includes('handshake') || err.code === 'ENOTFOUND')) {
      console.warn('R2 S3 endpoint inaccessible, fallback Cloudinary');
    } else {
      throw err;
    }
  }

  const result = await new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { resource_type: 'auto', folder: key.split('/').slice(0, -1).join('/'), public_id: key.split('/').pop().replace(/\.[^.]+$/, '') },
      (error, result) => { if (error) reject(error); else resolve(result); }
    );
    uploadStream.end(body);
  });

  return { key: result.public_id, provider: 'cloudinary', url: result.secure_url };
}

async function uploadBuffer(file, prefix) {
  const ext = file.originalname.split('.').pop() || 'bin';
  const key = `${prefix}/${generateTimestampId()}.${ext}`;
  return uploadFile(key, file.buffer, file.mimetype);
}

async function getDownloadUrl(key, expiresIn = 604800) {
  try {
    const client = getClient();
    const command = new GetObjectCommand({ Bucket: BUCKET_NAME, Key: key });
    return await getSignedUrl(client, command, { expiresIn });
  } catch {
    return null;
  }
}

async function deleteR2File(key) {
  try {
    const client = getClient();
    const command = new DeleteObjectCommand({ Bucket: BUCKET_NAME, Key: key });
    await client.send(command);
    return 'r2';
  } catch (err) {
    if (err.name === 'Error' && (err.message?.includes('EPROTO') || err.message?.includes('handshake') || err.code === 'ENOTFOUND')) {
      console.warn('R2 delete endpoint inaccessible, skipping R2 deletion');
    } else {
      throw err;
    }
  }
  return null;
}

module.exports = { uploadFile, uploadBuffer, getDownloadUrl, deleteR2File };
```

---

## Fichier : services/streamingService.js

```javascript
const NodeMediaServer = require('node-media-server');

let nms = null;

const config = {
  rtmp: {
    port: 1935,
    chunk_size: 60000,
    gop_cache: true,
    ping: 30,
    ping_timeout: 60,
  },
};

function startStreamingServer() {
  if (nms) return nms;
  nms = new NodeMediaServer(config);
  nms.run();
  nms.on('preConnect', () => console.log('Nouvelle connexion entrante'));
  nms.on('postConnect', () => console.log('Client connecté'));
  nms.on('doneConnect', () => console.log('Client déconnecté'));
  nms.on('prePublish', (id, StreamPath) => {
    console.log(`Publication détectée: ${StreamPath.split('/').pop()}`);
  });
  nms.on('donePublish', (id, StreamPath) => {
    console.log(`Publication terminée: ${StreamPath.split('/').pop()}`);
  });
  console.log(`Serveur RTMP démarré sur le port ${config.rtmp.port}`);
  return nms;
}

function stopStreamingServer() {
  if (nms) {
    nms.stop();
    nms = null;
  }
}

function getServerInfo() {
  const ip = require('../utils/stream_helper').getServerIP();
  return { rtmpPort: config.rtmp.port, rtmpUrl: `rtmp://${ip}:${config.rtmp.port}/live` };
}

module.exports = { startStreamingServer, stopStreamingServer, getServerInfo };
```

---

## Fichier : controllers/enseignementController.js

```javascript
const { db } = require('../config/firebase');
const cloudinary = require('../config/cloudinary');
const r2 = require('../services/r2Service');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

async function resolveImageUrl(docData) {
  if (docData.imageKey) {
    const url = await r2.getDownloadUrl(docData.imageKey);
    if (url) return url;
  }
  return docData.artworkUrl || '';
}

async function resolveAudioUrl(docData) {
  if (docData.audioKey) {
    const url = await r2.getDownloadUrl(docData.audioKey);
    if (url) return url;
  }
  return docData.audioUrl || '';
}

const createEnseignement = async (req, res) => {
  try {
    const { title, speaker, description, category, tags } = req.body;
    if (!req.files || !req.files.image || !req.files.audio)
      return res.status(400).json({ error: 'Image et audio sont requis' });
    if (!title || !speaker || !category)
      return res.status(400).json({ error: 'Title, speaker et category sont requis' });

    const imageResult = await r2.uploadBuffer(req.files.image[0], 'enseignements/images');
    const audioResult = await r2.uploadBuffer(req.files.audio[0], 'enseignements/audios');

    const now = new Date();
    const mois = req.body.mois?.toString() || (now.getMonth() + 1).toString();
    const annee = req.body.annee?.toString() || now.getFullYear().toString();

    let artworkUrl = imageResult.url || '';
    let audioUrl = audioResult.url || '';
    if (imageResult.provider === 'r2')
      artworkUrl = await r2.getDownloadUrl(imageResult.key) || '';
    if (audioResult.provider === 'r2')
      audioUrl = await r2.getDownloadUrl(audioResult.key) || '';

    const enseignementData = {
      title, speaker, description: description || '', category,
      duration: parseInt(req.body.duration) || 0, audioUrl, artworkUrl,
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      playCount: 0, rating: 0.0, isNew: true, isFeatured: false,
      publishedAt: now, createdAt: now, updatedAt: now,
      mois, annee, typeCulte: req.body.typeCulte || 'Conférence',
    };

    if (imageResult.provider === 'r2') enseignementData.imageKey = imageResult.key;
    else enseignementData.imagePublicId = imageResult.key;
    if (audioResult.provider === 'r2') enseignementData.audioKey = audioResult.key;
    else enseignementData.audioPublicId = audioResult.key;

    const docRef = await db.collection('enseignements').add(enseignementData);

    try {
      await sendNotificationToAllUsers({
        title: 'Nouvel enseignement disponible',
        body: `${title} - ${speaker || 'Nouveau contenu'}`,
        data: { id: docRef.id, type: 'teaching', teachingId: docRef.id },
        imageUrl: artworkUrl, type: 'teaching',
      });
    } catch (notifError) {
      console.error('Erreur envoi notification enseignement:', notifError);
    }

    res.status(201).json({ id: docRef.id, message: 'Enseignement créé avec succès', data: enseignementData });
  } catch (error) {
    console.error('Erreur lors de la création:', error);
    res.status(500).json({ error: 'Erreur lors de la création', details: error.message });
  }
};

async function formatEnseignement(doc) {
  const data = doc.data();
  const [artworkUrl, audioUrl] = await Promise.all([resolveImageUrl(data), resolveAudioUrl(data)]);
  return {
    id: doc.id, title: data.title || 'Titre non disponible',
    speaker: data.speaker || 'Orateur non disponible',
    description: data.description || '', category: data.category || 'Non classé',
    duration: data.duration || 0, audioUrl, artworkUrl,
    tags: data.tags || [], playCount: data.playCount || 0,
    rating: data.rating || 0.0, isNew: data.isNew || false, isFeatured: data.isFeatured || false,
    publishedAt: data.publishedAt?.toDate() || new Date(),
    createdAt: data.createdAt?.toDate() || new Date(),
    updatedAt: data.updatedAt?.toDate() || new Date(),
    mois: data.mois?.toString() || (new Date().getMonth() + 1).toString(),
    annee: data.annee?.toString() || new Date().getFullYear().toString(),
    typeCulte: data.typeCulte?.toString() || 'Conférence',
  };
}

const getAllEnseignements = async (req, res) => {
  try {
    const snapshot = await db.collection('enseignements').get();
    const enseignements = await Promise.all(snapshot.docs.map(doc => formatEnseignement(doc)));
    res.json(enseignements);
  } catch (error) {
    res.status(500).json({ error: 'Erreur récupération' });
  }
};

// updateEnseignement, deleteEnseignement, deleteAllEnseignements, deleteEnseignementsByFilter
// = même pattern que backend-hono mais avec req.params, req.body, req.files (Multer)
```

---

## Fichier : controllers/annonceController.js

```javascript
const { db } = require('../config/firebase');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

const createAnnonce = async (req, res) => {
  try {
    const { nom, description } = req.body;
    if (!nom || !nom.trim())
      return res.status(400).json({ error: 'Le nom de l\'annonce est requis' });
    if (!description || !description.trim())
      return res.status(400).json({ error: 'La description est requise' });
    if (nom.length > 200)
      return res.status(400).json({ error: 'Le nom ne peut pas dépasser 200 caractères' });

    const annonceData = { nom, description, dateCreation: new Date() };
    const docRef = await db.collection('annonces').add(annonceData);

    try {
      await sendNotificationToAllUsers({
        title: 'Nouvelle annonce', body: nom,
        data: { id: docRef.id, type: 'annonce', annonceId: docRef.id },
        type: 'annonce',
      });
    } catch (notifError) { console.error('Erreur envoi notification annonce:', notifError); }

    res.status(201).json({ id: docRef.id, message: 'Annonce créée avec succès', data: annonceData });
  } catch (error) {
    res.status(500).json({ error: 'Erreur création', details: error.message });
  }
};

const getAllAnnonces = async (req, res) => {
  try {
    const annoncesSnapshot = await db.collection('annonces').get();
    const annonces = [];
    annoncesSnapshot.forEach(doc => { annonces.push({ id: doc.id, ...doc.data() }); });
    res.json(annonces);
  } catch (error) {
    res.status(500).json({ error: 'Erreur récupération' });
  }
};

const deleteAnnonce = async (req, res) => { /* ... */ };
const deleteAllAnnonces = async (req, res) => { /* ... */ };

module.exports = { createAnnonce, getAllAnnonces, deleteAnnonce, deleteAllAnnonces };
```

**Note :** Le schéma des annonces est `{ nom, description, dateCreation }` (simplifié vs Hono qui a `{ title, content, type, targetAudience, linkUrl, ... }`).

---

## Fichier : controllers/liveController.js

Mêmes 12 fonctions que la version Hono : `createLiveStream`, `getAllLiveStreams`, `getLiveStreamById`, `getActiveLive`, `getServerInfo`, `updateLiveStream`, `updateLiveStreamStatus`, `incrementViewerCount`, `decrementViewerCount`, `getViewerCount`, `deleteLiveStream`, `deleteAllLiveStreams`.

**Différence clé** : Utilise `req.params.id`, `req.body`, `res.json()` (Express) au lieu de `c.req.param('id')`, `await c.req.json()`, `c.json()` (Hono).

---

## Fichier : controllers/calendarController.js

**Différences avec la version Hono :**
- Utilise des IDs générés côté client (`calendar-${Date.now()}-${random}`) au lieu de Firestore auto-ID
- Schéma plus riche : `category`, `isAllDay`, `createdBy`, `hasAlarm`, `alarmDaysBefore`, `alarmHoursBefore`, `alarmMinutesBefore`
- Fonctions `formatEventData()` absentes : calque les dates directement avec `?.toDate?.()?.toISOString()`
- Routes : pas de `deleteAllCalendarEvents` dans la version Hono (mais présente ici)
- Notifications push envoyées pour les mises à jour d'événements

---

## Fichier : controllers/userController.js

**Différences avec la version Hono :**
- Schéma utilisateur : `{ id, name, email, profileImageUrl, favoriteTeachingIds, downloadedTeachingIds, recentlyPlayedIds, notificationsEnabled }` + `fcmTokens[]` (stockés dans l'utilisateur)
- Stocke `FCM tokens` dans `users/{userId}.fcmTokens[]` (tableau) + collection `fcm_tokens`
- `getUserStats` : stats avancées (favoris, téléchargements, notifications activées/désactivées)
- Pas de notion de `lastLogin` (contrairement à Hono qui a `lastLogin`)

---

## Fichier : controllers/notificationController.js

**Différences avec la version Hono :**
- Enregistrement token : vérifie si l'utilisateur existe, le crée par défaut si besoin
- Stocke le token dans `fcm_tokens/{fcmToken}` (contrairement à Hono qui stocke dans `fcm_tokens/{uid}`)
- `fcmTokens[]` maintenu comme tableau dans le document utilisateur
- Envoi push : batch par 500 tokens, gestion des tokens invalides (suppression auto)
- Support Android + APNS spécifique (channelId, son, badge)
- Timeout de 30s par batch avec 3 tentatives

---

## Fichier : controllers/textResumeController.js

**Différences avec la version Hono :**
- Schéma : `{ title, speaker, description, category, pdfUrl, coverImageUrl, tags, viewCount, rating, ... }`
- Le champ `speaker` est présent ici (absent dans Hono)
- `viewCount` incrémenté automatiquement à la lecture du document (`getTextResumeById`)
- Upload via `multer` avec stockage disque temporaire (pas memoryStorage comme Hono)
- `pageCount: 0` stocké (non utilisé)

---

## Fichier : routes/ (7 fichiers)

Les routes Express montent les contrôleurs avec `express.Router()` :
- `enseignements.js` : POST `/` (multipart image+audio), GET `/`, PUT `/:id`, DELETE `/batch`, `/all`, `/:id`
- `annonces.js` : POST `/`, GET `/`, DELETE `/:id`, `/all`
- `lives.js` : GET `/`, `/active`, `/server-info`, `/:id/viewers`, `/:id`, POST `/`, PUT `/:id`, `/:id/status`, POST `/:id/join`, `/:id/leave`, DELETE `/all`, `/:id`
- `calendar.js` : POST `/`, GET `/`, `/year/:year`, `/:id`, PUT `/:id`, DELETE `/all`, `/:id`
- `users.js` : POST `/`, GET `/`, `/stats`, `/:id`, PUT `/:id`, DELETE `/all`, `/:id`
- `notifications.js` : POST `/tokens`, DELETE `/tokens`, POST `/send/all`, `/send/user`, `/send/topic`
- `textResumes.js` : POST `/` (multipart pdf+image), GET `/`, `/:id`, PUT `/:id` (multipart), DELETE `/batch`, `/all`, `/:id`

---

## Fichier : utils/notificationHelper.js

**Ajouts vs Hono :**
- Timeout de 30s par batch avec `Promise.race`
- 3 tentatives avec intervalle de 2s pour les erreurs réseau
- Gestion spécifique des erreurs : `EAI_AGAIN`, `getaddrinfo`, `Timeout`
- Suppression automatique des tokens FCM invalides
- `click_action: 'FLUTTER_NOTIFICATION_CLICK'` dans les data
- `icon: 'kog_launch'` dans la config Android

---

## Fichier : utils/ffmpeg_transcoder.js

**Ajouts vs Hono :**
- Logs de connexion : `"FFmpeg arrêté (code X), reconnexion dans Ys (tentative Z/N)"`
- Logs de fin : `"Transcodage terminé pour streamKey"`
- Message d'abandon : `"FFmpeg abandonné après N tentatives"`

---

## Fichier : utils/stream_helper.js

**Différences vs Hono :**
- `RTMP_PORT: 1935` fixe (pas de `process.env.RTMP_PORT`)
- Documentation JSDoc complète sur chaque fonction

---

## Fichier : utils/network_detector.js

```javascript
const os = require('os');

function detectLocalIP() {
  const interfaces = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        ips.push({ interface: name, address: iface.address, netmask: iface.netmask });
      }
    }
  }

  // Priorité : hotspot > wifi > ethernet > fallback
  const hotspotIP = ips.find(ip => ip.interface.toLowerCase().startsWith('ap') || ip.interface.toLowerCase().includes('hotspot'));
  if (hotspotIP) return { ip: hotspotIP.address, interface: hotspotIP.interface, type: 'hotspot', allIPs: ips };

  const wifiIP = ips.find(ip => ip.interface.toLowerCase().includes('wlan') || ip.interface.toLowerCase().includes('wlp') || ip.interface.toLowerCase().includes('wifi') || ip.interface.toLowerCase().includes('en0'));
  if (wifiIP) return { ip: wifiIP.address, interface: wifiIP.interface, type: 'wifi', allIPs: ips };

  const ethIP = ips.find(ip => ip.interface.toLowerCase().includes('eth') || ip.interface.toLowerCase().includes('enp'));
  if (ethIP) return { ip: ethIP.address, interface: ethIP.interface, type: 'ethernet', allIPs: ips };

  if (ips.length > 0) return { ip: ips[0].address, interface: ips[0].interface, type: 'unknown', allIPs: ips };
  return { ip: 'localhost', interface: 'none', type: 'localhost', allIPs: [] };
}

function getAllIPs() {
  const info = detectLocalIP();
  console.log('Interfaces réseau détectées:');
  info.allIPs.forEach(ip => {
    const active = ip.address === info.ip ? '->' : '  ';
    console.log(`${active} ${ip.interface.padEnd(15)} ${ip.address.padEnd(15)} ${ip.netmask}`);
  });
  console.log(`IP sélectionnée: ${info.ip} (${info.type})`);
  return info;
}

module.exports = { detectLocalIP, getAllIPs };
```

**Fichier unique** : `network_detector.js` n'existe pas dans backend-hono. Il permet de détecter l'IP réseau avec priorité hotspot > wifi > ethernet. Utile pour l'affichage des URLs en local.

---

## Fichier : veilleur.js

```javascript
const https = require('https');

class Veilleur {
  constructor(intervalMinutes = 14) {
    this.intervalMinutes = intervalMinutes;
    this.intervalMs = intervalMinutes * 60 * 1000;
    this.intervalId = null;
    this.url = process.env.RENDER_URL || (process.env.NODE_ENV === 'production'
      ? 'https://mykog-backend-api.onrender.com'
      : `http://localhost:${process.env.PORT || 3000}`);
  }

  start() {
    console.log(`Veilleur démarré - Ping toutes les ${this.intervalMinutes} minutes`);
    this.ping();
    this.intervalId = setInterval(() => this.ping(), this.intervalMs);
  }

  ping() {
    const url = this.url.startsWith('http') ? this.url : `https://${this.url}`;
    const isHttps = url.startsWith('https://');
    const client = isHttps ? https : require('http');
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: '/api/enseignements',
      method: 'GET',
      headers: { 'User-Agent': 'MyKOG-Veilleur/1.0', 'X-Veilleur-Ping': 'true' },
      timeout: 15000
    };
    const req = client.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => console.log(`Ping réussi - Status: ${res.statusCode}`));
    });
    req.on('error', (err) => console.error(`Erreur de ping: ${err.message}`));
    req.on('timeout', () => { console.error('Timeout du ping'); req.destroy(); });
    req.end();
  }

  stop() {
    if (this.intervalId) { clearInterval(this.intervalId); this.intervalId = null; }
  }
}

module.exports = Veilleur;
```

---

## Différences clés entre backend-API (Express) et backend-hono (Hono)

### Architecture
| Aspect | backend-API (Express) | backend-hono (Hono) |
|--------|----------------------|---------------------|
| Framework | Express 5 | Hono 4.7 |
| Serveur | `app.listen()` | `@hono/node-server` |
| Upload | Multer (memoryStorage) | `c.req.parseBody()` natif |
| CORS | `cors` middleware | `hono/cors` natif |
| Static | `express.static()` | `@hono/node-server/serve-static` |

### Patterns de code
```javascript
// Express
const createItem = async (req, res) => {
  const { id } = req.params;
  const body = req.body;
  const files = req.files;
  res.status(201).json({ data });
};

// Hono
const createItem = async (c) => {
  const id = c.req.param('id');
  const body = await c.req.json();
  const formData = await c.req.parseBody();
  return c.json({ data }, 201);
};
```

### Schémas de données
| Collection | Express | Hono |
|-----------|---------|------|
| `annonces` | `{ nom, description, dateCreation }` | `{ title, content, type, targetAudience, linkUrl, isActive, priority, startDate, endDate, imageUrl }` |
| `users` | `{ id, name, email, fcmTokens[] }` | `{ uid, email, displayName, photoURL, lastLogin, fcmToken }` |
| `textes_resumes` | `{ title, speaker, description, ... }` | `{ title, description, ... }` (sans speaker) |
| `calendar` | `{ id, title, category, isAllDay, createdBy, hasAlarm, ... }` | `{ title, type, color, allDay, ... }` (simplifié) |

### Fichiers uniques à Express
- `middleware/upload.js` – Configuration Multer (remplacé par `c.req.parseBody()` dans Hono)
- `utils/network_detector.js` – Détection d'IP hotspot/wifi/ethernet
- `public/admin-dashboard.html` – Dashboard admin statique
- `render.yaml` – Configuration déploiement Render
- Swagger Docs (`swagger-jsdoc`, `swagger-ui-express`) – Documentation API

### Fichiers uniques à Hono
- `src/config/cloudinary.js` – Cloudinary config (identique mais dans `config/`)
- `src/utils/veilleur.js` – Même classe Veilleur (déplacée dans `utils/`)
- Plus de `middleware/` (Multer remplacé par `parseBody()`)

---

## Routes API complètes (Express)

### Enseignements `/api/enseignements`
| Méthode | Route | Middleware | Description |
|---------|-------|-----------|-------------|
| POST | `/` | `upload.fields([image, audio])` | Créer |
| GET | `/` | - | Lister |
| PUT | `/:id` | `upload.fields([image])` | Mettre à jour |
| DELETE | `/batch` | - | Suppr. par filtre |
| DELETE | `/all` | - | Suppr. tout |
| DELETE | `/:id` | - | Suppr. un |

### Annonces `/api/annonces`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer (`{ nom, description }`) |
| GET | `/` | Lister |
| DELETE | `/:id` | Suppr. |
| DELETE | `/all` | Suppr. tout |

### Lives `/api/lives`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/` | Lister |
| GET | `/active` | Live actif |
| GET | `/server-info` | Infos serveur |
| GET | `/:id/viewers` | Viewers |
| GET | `/:id` | Détail |
| POST | `/` | Créer |
| PUT | `/:id` | Mettre à jour |
| PUT | `/:id/status` | Statut |
| POST | `/:id/join` | +1 viewer |
| POST | `/:id/leave` | -1 viewer |
| DELETE | `/all` | Suppr. tout |
| DELETE | `/:id` | Suppr. |

### Calendar `/api/calendar`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer (schéma riche) |
| GET | `/` | Lister |
| GET | `/year/:year` | Par année |
| GET | `/:id` | Détail |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/all` | Suppr. tout |
| DELETE | `/:id` | Suppr. |

### Users `/api/users`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer/mettre à jour |
| GET | `/` | Lister |
| GET | `/stats` | Statistiques |
| GET | `/:id` | Détail |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/all` | Suppr. tout |
| DELETE | `/:id` | Suppr. |

### Notifications `/api/notifications`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/tokens` | Enregistrer token |
| DELETE | `/tokens` | Supprimer token |
| POST | `/send/all` | Envoyer à tous |
| POST | `/send/user` | Envoyer à un user |
| POST | `/send/topic` | Envoyer à un topic |

### Text Resumes `/api/text-resumes`
| Méthode | Route | Middleware | Description |
|---------|-------|-----------|-------------|
| POST | `/` | `upload.fields([pdf, image])` | Créer |
| GET | `/` | - | Lister (filtres) |
| GET | `/:id` | - | Détail (+1 vue) |
| PUT | `/:id` | `upload.fields([pdf, image])` | Mettre à jour |
| DELETE | `/batch` | - | Suppr. par filtre |
| DELETE | `/all` | - | Suppr. tout |
| DELETE | `/:id` | - | Suppr. |

---

## Dépendances

| Package | Version | Rôle | Dans le Hono ? |
|---------|---------|------|----------------|
| `express` | ^5.1.0 | Framework HTTP | ❌ (remplacé par Hono) |
| `multer` | ^2.0.2 | Upload fichiers | ❌ (remplacé par `parseBody()`) |
| `multer-storage-cloudinary` | ^4.0.0 | Storage Cloudinary pour Multer | ❌ |
| `cors` | ^2.8.5 | Middleware CORS | ❌ (natif dans Hono) |
| `swagger-jsdoc` | ^6.2.8 | Documentation OpenAPI | ❌ |
| `swagger-ui-express` | ^5.0.0 | UI Swagger | ❌ |
| `@apidevtools/swagger-parser` | ^12.1.0 | Parseur Swagger | ❌ |
| `livekit-server-sdk` | ^2.15.1 | SDK LiveKit | ❌ |
| `hono` | - | - | ✅ ^4.7.0 |
| `@hono/node-server` | - | - | ✅ ^1.14.0 |
| `@aws-sdk/client-s3` | ^3.1073.0 | Client S3 R2 | ✅ |
| `@aws-sdk/s3-request-presigner` | ^3.1073.0 | Presigned URLs | ✅ |
| `cloudinary` | ^1.41.3 | Fallback upload | ✅ |
| `firebase-admin` | ^13.6.0 | Firebase Admin | ✅ |
| `node-media-server` | ^4.2.8 | Serveur RTMP | ✅ |
| `dotenv` | ^15.0.1 | Variables env | ✅ |

---

## Problèmes connus (communs avec backend-hono)

1. **R2 S3 endpoint bloqué** : `*.r2.cloudflarestorage.com` rejette le TLS. Les uploads tombent en fallback Cloudinary.
2. **Port RTMP 1935 occupé** : Processus inconnu bloque le port. Pas de fallback automatique (contrairement à Hono qui a `RTMP_PORT=1936`).
3. **Serveur Render** : Le veilleur envoie un ping toutes les 14 min pour éviter le sleep de Render.

---

## Fichiers supplémentaires (documentation/scripts)

- `GUIDE_REDEMARRAGE_SERVEUR.md` – Procédure de redémarrage
- `README_RENDER.md` – Instructions déploiement Render
- `RAILWAY_ENV_VARS.txt` – Variables d'env pour Railway
- `TROUBLESHOOTING_NOTIFICATIONS.md` – Résolution de bugs notifs
- `render.yaml` – Config Render (infra-as-code)
- `restart-server.sh` / `kill-server.sh` – Scripts d'admin
- `hls/` – Dossier de sortie HLS (alias de `hls_output/`)
- `public/admin-dashboard.html` – Dashboard admin statique (HTML/JS pur)
