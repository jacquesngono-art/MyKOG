# Bilan complet – Projet backend-hono (MyKOG-Terminal)

## Structure du projet backend-hono

```
backend-hono/
├── package.json
├── .env
├── hls_output/            (généré par FFmpeg)
├── public/                (fichiers statiques)
└── src/
    ├── index.js
    ├── config/
    │   ├── firebase.js
    │   └── cloudinary.js
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
        └── veilleur.js
```

---

## Fichier : package.json

```json
{
  "name": "backend-hono",
  "version": "1.0.0",
  "type": "commonjs",
  "scripts": {
    "dev": "node --watch src/index.js",
    "start": "node src/index.js",
    "livekit:start": "bash start_livekit.sh",
    "livekit:stop": "bash stop_livekit.sh",
    "livekit:logs": "tail -f livekit.log",
    "veilleur": "node -e \"const Veilleur = require('./src/veilleur'); const v = new Veilleur(14); v.start();\""
  },
  "dependencies": {
    "@aws-sdk/client-s3": "^3.1073.0",
    "@aws-sdk/s3-request-presigner": "^3.1073.0",
    "@hono/node-server": "^1.14.0",
    "cloudinary": "^1.41.3",
    "dotenv": "^16.4.7",
    "firebase-admin": "^13.6.0",
    "hono": "^4.7.0",
    "node-media-server": "^4.2.8"
  }
}
```

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
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDSfjuI/V4QKTDo\n9swnioYChD0OSTCQsPUKlqTiZyTb2rxmEPGmI9xo/vRu70lIboLrtQLfagJ9U/m+\nHBxvRXN8ErLy2xgKUG2iUR9VMpVj9uPd6zktyjHkG1ytq8xJAf7BN81bmmN8nR8k\n5zJKlEAPMojHOMRlZG9Dvhpsrq0O/Xuyj1zdG3SrwzN7xs2TaYXsCSdgQUbsxH3j\nSmUEIP5viqr+Vj+wTgXAzIYHGhZnTLunFE4Z9Qo0rF9guBOF+Dya0AsICC+ZF6gV\nrxoKP/zK+I2hr4TOw/XGcXElM6bgAUIT3NkB7/vMPHyM9J7JrLRL54ziM03Atl4E\nbQE8C3fpAgMBAAECggEAC2A427kUurMdMnP3Gdp3zl5C9fkQ47r6jUdRsy4vnOWs\nCaiYBLp6rJ59y5qJR324e+BhHr2qE4ekr0hx5XYXjRCuJOegG5uX5z4y3y4ACqJi\n04ElSpMbQeiUKEso+9ecoujfA3i7MHaF4r7Pdh4fvaqFn52y6IdmZ374SuAgWHdT\no/u+GR2JQdblXPfpraodX1n/UnJZMzdBYFAUacTmJEZgwRnnIi3skP2z9gFuaQGE\ndXp8HYLkzDr0ZrrqQXCKb3XytcM6q7Zp3d0awgVFmbYD4jSarwsXMz7FRWEC1AJB\n6QO1K+tV4WSfQaMmEYSXoN0YrjYKyqSy2rMdbK3vkQKBgQD+d3LQkrksWQoT1dWB\nvORM5/8jhaV3yGZC1aFQWywZtp7ekHZRlMPTlWFcflb1ezaoyinz8WYc+2PGbvIh\nhN9M4VwC6fhMnTqRhGC31/P4cBcoeXN84ulBZ40K0MOqZcHYNxifwImIdMCulGdd\n0fE5ZiZ6w5l1eZWvgfq6ppTLmQKBgQDTwvLWcKndeA2AsP192UzMRpuNcslxMacE\nYQukhbwP7EzkneRk9oUulsSsUL7Vimqo4F7rw1BpLkdwxYQjHBS1SZfeitOxXn/D\nKm3u52M39Co3r/Sg0KF85mpt4+FLVy13oTgJLm07aLjE9mraRDxzI8nnUVVHos3Z\n5I6eKeNA0QKBgFZjZOYsOZM1szcirDY8U2FMjZCYqaEttpHQBtDJ8wHTvsGeV5zA\nnW6yUvhcp9b0+ox4/Z8kf98s9SWDus3oVwq5o0wV9EbGRgDq6Q7g0KGyJBqIiM2I\nF1ot9nMKhrLNku59Xe22JrrdsCBUn3b5dCRhaoTY7Ls2CLwpq148eV1ZAoGBAM93\noBMYLlQc2p3KyZAS5Xr9ckkSvOl5i/huW8nEfIvdJziUuL9yBumuLOHl+hGcmwL5\nUAYMRSvHe5aw7NS5HlC+2VvfB6guvV2opCv75ula/kGw0ir8PDryRDOFn6UAtDsQ\naKYWJk6eOug9xFIzqEXmOlm3BaY5ixR/KHss7skBAoGBANeOirRMn5+64MxtuRfl\n1Iu6zQFmEN6npdsHT53qsr2pDJdr/H7+eaZXyvSKnjwlR9/AEI0+wkmz1x01jXDF\ndh6UisvBpB7nJ0n2in8nKpaU1m97f6H7aC9QMWID0BeeUvDESR6c2FMON75ateFU\nVpzBUtdN+OE3qHSFy2jE5o0l\n-----END PRIVATE KEY-----\n"
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

## Fichier : src/index.js

```javascript
require('dotenv').config();
const { Hono } = require('hono');
const { serve } = require('@hono/node-server');
const { cors } = require('hono/cors');
const { serveStatic } = require('@hono/node-server/serve-static');
const path = require('path');
const { startStreamingServer } = require('./services/streamingService');

process.on('uncaughtException', (err) => {
  if (err.code === 'EADDRINUSE' || err.message?.includes('EADDRINUSE') || err.message?.includes('listen')) {
    console.warn('Un composant réseau n\'a pas pu démarrer (port occupé)');
    return;
  }
  console.error('Erreur non gérée:', err);
  process.exit(1);
});

const app = new Hono();

app.use('/*', cors());
app.use('/hls/*', serveStatic({ root: path.join(__dirname, '..', 'hls_output') }));
app.use('/public/*', serveStatic({ root: path.join(__dirname, '..', 'public') }));

app.route('/api/enseignements', require('./routes/enseignements'));
app.route('/api/annonces', require('./routes/annonces'));
app.route('/api/lives', require('./routes/lives'));
app.route('/api/calendar', require('./routes/calendar'));
app.route('/api/users', require('./routes/users'));
app.route('/api/notifications', require('./routes/notifications'));
app.route('/api/text-resumes', require('./routes/textResumes'));

app.get('/', (c) => c.json({ message: 'Serveur Hono API opérationnel' }));

app.onError((err, c) => {
  console.error(err);
  return c.json({ error: 'Erreur interne', details: err.message }, 500);
});

app.notFound((c) => c.json({ error: 'Route non trouvée' }, 404));

const PORT = parseInt(process.env.PORT || '3000');

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`Serveur Hono lancé sur le port ${info.port}`);
  console.log(`HLS: http://localhost:${info.port}/hls/{streamKey}/index.m3u8`);

  startStreamingServer();

  if (process.env.NODE_ENV === 'production') {
    const Veilleur = require('./utils/veilleur');
    const v = new Veilleur(14);
    v.start();
  }
});
```

---

## Fichier : src/config/firebase.js

```javascript
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

if (admin.apps.length === 0) {
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: privateKey,
    }),
  });
}

const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

module.exports = { admin, db };
```

---

## Fichier : src/config/cloudinary.js

```javascript
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

module.exports = cloudinary;
```

---

## Fichier : src/services/r2Service.js

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

function generateTimestampId() {
  return `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
}

async function r2Upload(key, body, contentType) {
  const client = getClient();
  const command = new PutObjectCommand({ Bucket: BUCKET_NAME, Key: key, Body: body, ContentType: contentType });
  await client.send(command);
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
      console.warn('R2 delete inaccessible');
    } else {
      throw err;
    }
  }
  return null;
}

module.exports = { uploadFile, uploadBuffer, getDownloadUrl, deleteR2File };
```

---

## Fichier : src/services/streamingService.js

```javascript
const NodeMediaServer = require('node-media-server');

let nms = null;

const RTMP_PORT = parseInt(process.env.RTMP_PORT || '1936');

const config = {
  rtmp: {
    port: RTMP_PORT,
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

  return nms;
}

function stopStreamingServer() {
  if (nms) {
    nms.stop();
    nms = null;
  }
}

module.exports = { startStreamingServer, stopStreamingServer };
```

---

## Fichier : src/controllers/enseignementController.js

```javascript
const { db } = require('../config/firebase');
const cloudinary = require('../config/cloudinary');
const r2 = require('../services/r2Service');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

function generateKey(prefix, file) {
  const ext = file.name.split('.').pop() || 'bin';
  return `${prefix}/${Date.now()}-${Math.round(Math.random() * 1E9)}.${ext}`;
}

async function fileToUpload(file) {
  return {
    originalname: file.name,
    mimetype: file.type,
    buffer: Buffer.from(await file.arrayBuffer()),
    size: file.size,
  };
}

async function resolveImageUrl(data) {
  if (data.imageKey) {
    const url = await r2.getDownloadUrl(data.imageKey);
    if (url) return url;
  }
  return data.artworkUrl || '';
}

async function resolveAudioUrl(data) {
  if (data.audioKey) {
    const url = await r2.getDownloadUrl(data.audioKey);
    if (url) return url;
  }
  return data.audioUrl || '';
}

const createEnseignement = async (c) => {
  try {
    const body = await c.req.parseBody();
    const title = body['title'];
    const speaker = body['speaker'];
    const description = body['description'];
    const category = body['category'];
    const tags = body['tags'];

    const rawImage = body['image'];
    const rawAudio = body['audio'];

    if (!rawImage || typeof rawImage === 'string' || !rawAudio || typeof rawAudio === 'string') {
      return c.json({ error: 'Image et audio sont requis' }, 400);
    }
    if (!title || !speaker || !category) {
      return c.json({ error: 'Title, speaker et category sont requis' }, 400);
    }

    const imageUpload = await fileToUpload(rawImage);
    const audioUpload = await fileToUpload(rawAudio);

    const imageResult = await r2.uploadFile(generateKey('enseignements/images', rawImage), imageUpload.buffer, imageUpload.mimetype);
    const audioResult = await r2.uploadFile(generateKey('enseignements/audios', rawAudio), audioUpload.buffer, audioUpload.mimetype);

    const now = new Date();
    const mois = body['mois']?.toString() || (now.getMonth() + 1).toString();
    const annee = body['annee']?.toString() || now.getFullYear().toString();

    let artworkUrl = imageResult.url || '';
    let audioUrl = audioResult.url || '';
    if (imageResult.provider === 'r2') artworkUrl = await r2.getDownloadUrl(imageResult.key) || '';
    if (audioResult.provider === 'r2') audioUrl = await r2.getDownloadUrl(audioResult.key) || '';

    const data = {
      title, speaker, description: description || '', category,
      duration: parseInt(body['duration']) || 0,
      audioUrl, artworkUrl,
      tags: tags ? (typeof tags === 'string' ? tags.split(',').map(t => t.trim()) : tags) : [],
      playCount: 0, rating: 0.0, isNew: true, isFeatured: false,
      publishedAt: now, createdAt: now, updatedAt: now,
      mois, annee, typeCulte: body['typeCulte'] || 'Conférence',
    };

    if (imageResult.provider === 'r2') data.imageKey = imageResult.key;
    else data.imagePublicId = imageResult.key;
    if (audioResult.provider === 'r2') data.audioKey = audioResult.key;
    else data.audioPublicId = audioResult.key;

    const docRef = await db.collection('enseignements').add(data);

    try {
      await sendNotificationToAllUsers({
        title: 'Nouvel enseignement disponible',
        body: `${title} - ${speaker}`,
        data: { id: docRef.id, type: 'teaching', teachingId: docRef.id },
        imageUrl: artworkUrl, type: 'teaching',
      });
    } catch {}

    return c.json({ id: docRef.id, message: 'Enseignement créé avec succès', data }, 201);
  } catch (error) {
    return c.json({ error: 'Erreur lors de la création', details: error.message }, 500);
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

const getAllEnseignements = async (c) => {
  try {
    const snapshot = await db.collection('enseignements').get();
    const results = await Promise.all(snapshot.docs.map(doc => formatEnseignement(doc)));
    return c.json(results);
  } catch (error) {
    return c.json({ error: 'Erreur lors de la récupération', details: error.message }, 500);
  }
};

async function deleteFiles(data) {
  if (data.imageKey) await r2.deleteR2File(data.imageKey);
  else if (data.imagePublicId) try { await cloudinary.uploader.destroy(data.imagePublicId); } catch {}
  if (data.audioKey) await r2.deleteR2File(data.audioKey);
  else if (data.audioPublicId) try { await cloudinary.uploader.destroy(data.audioPublicId, { resource_type: 'video' }); } catch {}
}

const deleteEnseignement = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('enseignements').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Enseignement non trouvé' }, 404);
    await deleteFiles(doc.data());
    await ref.delete();
    return c.json({ id, message: 'Enseignement supprimé' });
  } catch (error) {
    return c.json({ error: 'Erreur lors de la suppression', details: error.message }, 500);
  }
};

const deleteAllEnseignements = async (c) => {
  try {
    const snapshot = await db.collection('enseignements').get();
    const ids = [];
    await Promise.all(snapshot.docs.map(async (doc) => { ids.push(doc.id); await deleteFiles(doc.data()); await doc.ref.delete(); }));
    return c.json({ message: `${ids.length} enseignement(s) supprimé(s)`, ids });
  } catch (error) {
    return c.json({ error: 'Erreur lors de la suppression', details: error.message }, 500);
  }
};

const deleteEnseignementsByFilter = async (c) => {
  try {
    let query = db.collection('enseignements');
    ['category', 'mois', 'annee', 'typeCulte'].forEach(f => { const v = c.req.query(f); if (v) query = query.where(f, '==', v); });
    const snapshot = await query.get();
    const ids = [];
    await Promise.all(snapshot.docs.map(async (doc) => { ids.push(doc.id); await deleteFiles(doc.data()); await doc.ref.delete(); }));
    return c.json({ message: `${ids.length} enseignement(s) supprimé(s)`, ids });
  } catch (error) {
    return c.json({ error: 'Erreur lors de la suppression', details: error.message }, 500);
  }
};

const updateEnseignement = async (c) => {
  try {
    const id = c.req.param('id');
    const ct = c.req.header('content-type') || '';
    let body;
    if (ct.includes('multipart/form-data')) body = await c.req.parseBody();
    else body = await c.req.json();

    const ref = db.collection('enseignements').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Enseignement non trouvé' }, 404);

    const existing = doc.data();
    const updateData = { updatedAt: new Date() };

    ['title', 'speaker', 'description', 'category', 'typeCulte'].forEach(f => { if (body[f] !== undefined) updateData[f] = body[f]; });
    ['mois', 'annee'].forEach(f => { if (body[f] !== undefined) updateData[f] = body[f].toString(); });
    if (body['playCount'] !== undefined) updateData.playCount = parseInt(body['playCount']);
    if (body['rating'] !== undefined) updateData.rating = parseFloat(body['rating']);
    if (body['isNew'] !== undefined) updateData.isNew = body['isNew'] === true || body['isNew'] === 'true';
    if (body['isFeatured'] !== undefined) updateData.isFeatured = body['isFeatured'] === true || body['isFeatured'] === 'true';
    if (body['tags'] !== undefined) {
      const t = body['tags'];
      updateData.tags = typeof t === 'string' ? t.split(',').map(s => s.trim()).filter(Boolean) : t;
    }

    const rawImage = body['image'];
    if (rawImage && typeof rawImage !== 'string') {
      if (existing.imageKey) await r2.deleteR2File(existing.imageKey);
      else if (existing.imagePublicId) try { await cloudinary.uploader.destroy(existing.imagePublicId); } catch {}
      const upload = await fileToUpload(rawImage);
      const result = await r2.uploadFile(generateKey('enseignements/images', rawImage), upload.buffer, upload.mimetype);
      if (result.provider === 'r2') {
        updateData.imageKey = result.key; delete updateData.imagePublicId;
        updateData.artworkUrl = await r2.getDownloadUrl(result.key) || '';
      } else {
        updateData.imagePublicId = result.key; delete updateData.imageKey;
        if (result.url) updateData.artworkUrl = result.url;
      }
    }

    await ref.update(updateData);
    const updated = await ref.get();
    const formatted = await formatEnseignement(updated);
    return c.json({ id, message: 'Enseignement mis à jour', data: formatted });
  } catch (error) {
    return c.json({ error: 'Erreur lors de la mise à jour', details: error.message }, 500);
  }
};

module.exports = { createEnseignement, getAllEnseignements, updateEnseignement, deleteEnseignement, deleteAllEnseignements, deleteEnseignementsByFilter };
```

---

## Fichier : src/controllers/annonceController.js

```javascript
const { db } = require('../config/firebase');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

const createAnnonce = async (c) => {
  try {
    const body = await c.req.json();
    const { title, content, type, targetAudience, linkUrl } = body;
    if (!title || !content) return c.json({ error: 'Title et content sont requis' }, 400);

    const now = new Date();
    const data = {
      title, content, type: type || 'info',
      targetAudience: targetAudience || 'all',
      linkUrl: linkUrl || '',
      isActive: true, priority: body.priority || 0,
      startDate: body.startDate ? new Date(body.startDate) : null,
      endDate: body.endDate ? new Date(body.endDate) : null,
      imageUrl: body.imageUrl || '',
      createdAt: now, updatedAt: now,
    };

    const docRef = await db.collection('annonces').add(data);

    try {
      await sendNotificationToAllUsers({
        title: 'Nouvelle annonce', body: title,
        data: { id: docRef.id, type: 'announcement', announcementId: docRef.id },
        type: 'announcement',
      });
    } catch {}

    return c.json({ id: docRef.id, message: 'Annonce créée', data }, 201);
  } catch (error) {
    return c.json({ error: 'Erreur création', details: error.message }, 500);
  }
};

const getAllAnnonces = async (c) => {
  try {
    const snapshot = await db.collection('annonces').orderBy('createdAt', 'desc').get();
    const items = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate(), updatedAt: doc.data().updatedAt?.toDate() }));
    return c.json(items);
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const deleteAnnonce = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('annonces').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Annonce non trouvée' }, 404);
    await ref.delete();
    return c.json({ id, message: 'Annonce supprimée' });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const deleteAllAnnonces = async (c) => {
  try {
    const snapshot = await db.collection('annonces').get();
    await Promise.all(snapshot.docs.map(doc => doc.ref.delete()));
    return c.json({ message: `${snapshot.size} annonce(s) supprimée(s)` });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

module.exports = { createAnnonce, getAllAnnonces, deleteAnnonce, deleteAllAnnonces };
```

---

## Fichier : src/controllers/liveController.js

```javascript
const { db } = require('../config/firebase');
const { STREAM_CONFIG, getServerIP, getHLSUrl, getRTMPUrl, getHLSUrlWithIP, getRTMPUrlWithIP, isValidStreamKey, generateStreamKey } = require('../utils/stream_helper');
const FFmpegTranscoder = require('../utils/ffmpeg_transcoder');

if (!global.__activeTranscoders) global.__activeTranscoders = new Map();
const activeTranscoders = global.__activeTranscoders;

const createLiveStream = async (c) => {
  try {
    const body = await c.req.json();
    const { title, description, pastor, thumbnailUrl, streamUrl, streamKey, scheduledAt, serverIP } = body;
    if (!title || !title.trim()) return c.json({ error: 'Le titre est requis' }, 400);
    if (!pastor || !pastor.trim()) return c.json({ error: 'Le pasteur est requis' }, 400);

    const finalStreamKey = streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;
    if (streamKey && !isValidStreamKey(streamKey)) return c.json({ error: 'Clé de stream invalide' }, 400);

    const rtmpUrl = serverIP ? getRTMPUrlWithIP(serverIP, finalStreamKey) : getRTMPUrl(finalStreamKey);
    const hlsUrl = serverIP ? getHLSUrlWithIP(serverIP, finalStreamKey) : getHLSUrl(finalStreamKey);
    const finalStreamUrl = (streamUrl && streamUrl.trim()) ? streamUrl : hlsUrl;

    const now = new Date();
    const isLiveNow = (body['status'] || 'scheduled') === 'live';

    const data = {
      title, description: description || '', pastor,
      thumbnailUrl: thumbnailUrl || '', streamUrl: finalStreamUrl,
      streamKey: finalStreamKey, rtmpUrl, hlsUrl,
      status: body['status'] || 'scheduled',
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      startedAt: isLiveNow ? now : null, endedAt: null,
      viewerCount: 0, peakViewerCount: 0,
      tags: body['tags'] || [], createdAt: now, updatedAt: now,
    };

    const docRef = await db.collection('liveStreams').add(data);

    if (data.status === 'live') {
      try {
        if (!activeTranscoders.has(finalStreamKey)) {
          const t = new FFmpegTranscoder(finalStreamKey);
          t.start();
          activeTranscoders.set(finalStreamKey, t);
        }
      } catch (err) { console.error('Erreur démarrage transcoder:', err.message); }
    }

    return c.json({ id: docRef.id, message: 'Live stream créé', data }, 201);
  } catch (error) {
    return c.json({ error: 'Erreur création live', details: error.message }, 500);
  }
};

const getAllLiveStreams = async (c) => {
  try {
    const snapshot = await db.collection('liveStreams').get();
    const currentIP = getServerIP();
    const items = snapshot.docs.map(doc => {
      const d = doc.data();
      const key = d.streamKey || 'mykog_live';
      return { id: doc.id, title: d.title || 'Live Stream', description: d.description || '', pastor: d.pastor || 'Unknown',
        thumbnailUrl: d.thumbnailUrl || '', streamUrl: getHLSUrl(key), streamKey: key, rtmpUrl: getRTMPUrl(key), hlsUrl: getHLSUrl(key),
        status: d.status || 'scheduled', viewerCount: d.viewerCount || 0, peakViewerCount: d.peakViewerCount || 0,
        tags: d.tags || [], scheduledAt: d.scheduledAt?.toDate() || null, startedAt: d.startedAt?.toDate() || null, endedAt: d.endedAt?.toDate() || null,
        createdAt: d.createdAt?.toDate() || new Date(), updatedAt: d.updatedAt?.toDate() || new Date() };
    });
    items.sort((a, b) => ({ live: 0, scheduled: 1, ended: 2 }[a.status] || 3) - ({ live: 0, scheduled: 1, ended: 2 }[b.status] || 3));
    return c.json(items);
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const getLiveStreamById = async (c) => {
  try {
    const id = c.req.param('id');
    const doc = await db.collection('liveStreams').doc(id).get();
    if (!doc.exists) return c.json({ error: 'Live non trouvé' }, 404);
    const d = doc.data();
    return c.json({ id: doc.id, ...d, scheduledAt: d.scheduledAt?.toDate(), startedAt: d.startedAt?.toDate(), endedAt: d.endedAt?.toDate(), createdAt: d.createdAt?.toDate(), updatedAt: d.updatedAt?.toDate() });
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const getActiveLive = async (c) => {
  try {
    const snapshot = await db.collection('liveStreams').get();
    const active = [];
    snapshot.forEach(doc => { const d = doc.data(); if (d.status === 'live') active.push({ id: doc.id, data: d, startedAt: d.startedAt?.toDate() || new Date(0) }); });
    active.sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime());
    if (active.length === 0) return c.json({ error: 'Aucun live actif', data: null }, 404);

    const most = active[0];
    const d = most.data;
    const ip = getServerIP();
    const key = d.streamKey || 'mykog_live';
    return c.json({ id: most.id, title: d.title || 'Live en cours', description: d.description || '', pastor: d.pastor || 'MyKOG',
      thumbnailUrl: d.thumbnailUrl || '', streamUrl: getHLSUrl(key), streamKey: key, rtmpUrl: getRTMPUrl(key), hlsUrl: getHLSUrl(key),
      status: d.status || 'live', viewerCount: d.viewerCount || 0, peakViewerCount: d.peakViewerCount || 0,
      scheduledAt: d.scheduledAt?.toDate() || null, startedAt: d.startedAt?.toDate() || null, endedAt: d.endedAt?.toDate() || null,
      tags: d.tags || [], createdAt: d.createdAt?.toDate() || new Date(), updatedAt: d.updatedAt?.toDate() || new Date() });
  } catch (error) {
    return c.json({ error: 'Erreur récupération live actif', details: error.message }, 500);
  }
};

const getServerInfo = (c) => {
  const ip = getServerIP();
  return c.json({ serverIP: ip, rtmpUrl: getRTMPUrlWithIP(ip), hlsUrl: getHLSUrlWithIP(ip), streamKey: STREAM_CONFIG.DEFAULT_STREAM_KEY,
    rtmpPort: STREAM_CONFIG.RTMP_PORT, hlsPort: STREAM_CONFIG.HLS_PORT, hlsPath: STREAM_CONFIG.HLS_PATH });
};

const updateLiveStream = async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();
    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Live non trouvé' }, 404);

    const current = doc.data();
    const now = new Date();
    const update = { updatedAt: now };

    ['title', 'description', 'pastor', 'thumbnailUrl'].forEach(f => { if (body[f] !== undefined) update[f] = body[f]; });

    const finalKey = body['streamKey'] || current.streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;
    if (body['streamKey'] && !isValidStreamKey(body['streamKey'])) return c.json({ error: 'Clé invalide' }, 400);

    if (body['streamKey'] || body['serverIP']) {
      update.streamKey = finalKey;
      update.rtmpUrl = body['serverIP'] ? getRTMPUrlWithIP(body['serverIP'], finalKey) : getRTMPUrl(finalKey);
      update.hlsUrl = body['serverIP'] ? getHLSUrlWithIP(body['serverIP'], finalKey) : getHLSUrl(finalKey);
      if (!body['streamUrl']) update.streamUrl = update.hlsUrl;
    }
    if (body['streamUrl'] !== undefined) update.streamUrl = body['streamUrl'];

    if (body['status'] !== undefined) {
      if (!['scheduled', 'live', 'ended'].includes(body['status'])) return c.json({ error: 'Statut invalide' }, 400);
      update.status = body['status'];
      const prevStatus = current.status;
      const streamKey = current.streamKey || finalKey;

      if (body['status'] === 'live' && !current.startedAt) {
        update.startedAt = now;
        if (prevStatus !== 'live') {
          try {
            if (!activeTranscoders.has(streamKey)) { const t = new FFmpegTranscoder(streamKey); t.start(); activeTranscoders.set(streamKey, t); }
          } catch (err) { console.error('Erreur transcoder:', err.message); }
        }
      } else if (body['status'] === 'ended') {
        update.endedAt = now;
        if (prevStatus === 'live') {
          const t = activeTranscoders.get(streamKey);
          if (t) { t.stop(); activeTranscoders.delete(streamKey); }
        }
      }
    }

    await ref.update(update);
    const updated = await ref.get();
    const d = updated.data();
    return c.json({ id, message: 'Live mis à jour', data: { ...d, scheduledAt: d.scheduledAt?.toDate(), startedAt: d.startedAt?.toDate(), endedAt: d.endedAt?.toDate(), createdAt: d.createdAt?.toDate(), updatedAt: d.updatedAt?.toDate() } });
  } catch (error) {
    return c.json({ error: 'Erreur mise à jour', details: error.message }, 500);
  }
};

const updateLiveStreamStatus = async (c) => {
  try {
    const id = c.req.param('id');
    const { status } = await c.req.json();
    if (!['scheduled', 'live', 'ended'].includes(status)) return c.json({ error: 'Statut invalide' }, 400);

    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Live non trouvé' }, 404);

    const current = doc.data();
    const now = new Date();
    const update = { status, updatedAt: now };
    const streamKey = current.streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;

    if (status === 'live' && !current.startedAt) {
      update.startedAt = now;
      if (current.status !== 'live') {
        try { if (!activeTranscoders.has(streamKey)) { const t = new FFmpegTranscoder(streamKey); t.start(); activeTranscoders.set(streamKey, t); } } catch {}
      }
    } else if (status === 'ended') {
      update.endedAt = now;
      if (current.status === 'live') {
        const t = activeTranscoders.get(streamKey);
        if (t) { t.stop(); activeTranscoders.delete(streamKey); }
      }
    }

    await ref.update(update);
    return c.json({ id, message: `Statut mis à jour: ${status}`, data: update });
  } catch (error) {
    return c.json({ error: 'Erreur mise à jour statut', details: error.message }, 500);
  }
};

const incrementViewerCount = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Live non trouvé' }, 404);
    const current = doc.data();
    const count = (current.viewerCount || 0) + 1;
    const peak = Math.max(count, current.peakViewerCount || 0);
    await ref.update({ viewerCount: count, peakViewerCount: peak, updatedAt: new Date() });
    return c.json({ id, viewerCount: count, peakViewerCount: peak });
  } catch (error) {
    return c.json({ error: 'Erreur incrémentation', details: error.message }, 500);
  }
};

const decrementViewerCount = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Live non trouvé' }, 404);
    const current = doc.data();
    const count = Math.max((current.viewerCount || 0) - 1, 0);
    await ref.update({ viewerCount: count, updatedAt: new Date() });
    return c.json({ id, viewerCount: count });
  } catch (error) {
    return c.json({ error: 'Erreur décrémentation', details: error.message }, 500);
  }
};

const getViewerCount = async (c) => {
  try {
    const id = c.req.param('id');
    const doc = await db.collection('liveStreams').doc(id).get();
    if (!doc.exists) return c.json({ error: 'Live non trouvé' }, 404);
    const d = doc.data();
    return c.json({ id, viewerCount: d.viewerCount || 0, peakViewerCount: d.peakViewerCount || 0, status: d.status || 'scheduled' });
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const deleteLiveStream = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('liveStreams').doc(id);
    if (!(await ref.get()).exists) return c.json({ error: 'Live non trouvé' }, 404);
    await ref.delete();
    return c.json({ id, message: 'Live supprimé' });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const deleteAllLiveStreams = async (c) => {
  try {
    const snapshot = await db.collection('liveStreams').get();
    await Promise.all(snapshot.docs.map(doc => doc.ref.delete()));
    return c.json({ message: `${snapshot.size} live(s) supprimé(s)`, deleted: snapshot.size });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

module.exports = { createLiveStream, getAllLiveStreams, getLiveStreamById, getActiveLive, getServerInfo, updateLiveStream, updateLiveStreamStatus, incrementViewerCount, decrementViewerCount, getViewerCount, deleteLiveStream, deleteAllLiveStreams };
```

---

## Fichier : src/controllers/calendarController.js

```javascript
const { db } = require('../config/firebase');

const createCalendarEvent = async (c) => {
  try {
    const body = await c.req.json();
    const { title, startDate, endDate } = body;
    if (!title || !startDate) return c.json({ error: 'Title et startDate sont requis' }, 400);

    const now = new Date();
    const data = {
      title, description: body.description || '',
      startDate: new Date(startDate), endDate: endDate ? new Date(endDate) : null,
      type: body.type || 'event', location: body.location || '',
      color: body.color || '#D4AF37',
      allDay: body.allDay || false,
      createdAt: now, updatedAt: now,
    };

    const docRef = await db.collection('calendar').add(data);
    return c.json({ id: docRef.id, message: 'Événement créé', data }, 201);
  } catch (error) {
    return c.json({ error: 'Erreur création', details: error.message }, 500);
  }
};

const getAllCalendarEvents = async (c) => {
  try {
    const snapshot = await db.collection('calendar').orderBy('startDate', 'asc').get();
    const items = snapshot.docs.map(formatEvent);
    return c.json(items);
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const getEventsByYear = async (c) => {
  try {
    const year = parseInt(c.req.param('year'));
    const startDate = new Date(`${year}-01-01T00:00:00Z`);
    const endDate = new Date(`${year + 1}-01-01T00:00:00Z`);

    const snapshot = await db.collection('calendar')
      .where('startDate', '>=', startDate).where('startDate', '<', endDate)
      .orderBy('startDate', 'asc').get();

    const items = snapshot.docs.map(formatEvent);
    return c.json(items);
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const getCalendarEventById = async (c) => {
  try {
    const id = c.req.param('id');
    const doc = await db.collection('calendar').doc(id).get();
    if (!doc.exists) return c.json({ error: 'Événement non trouvé' }, 404);
    return c.json({ id: doc.id, ...formatEventData(doc.data()) });
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const updateCalendarEvent = async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();
    const ref = db.collection('calendar').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Événement non trouvé' }, 404);

    const updateData = { updatedAt: new Date() };
    ['title', 'description', 'type', 'location', 'color'].forEach(f => { if (body[f] !== undefined) updateData[f] = body[f]; });
    if (body.allDay !== undefined) updateData.allDay = body.allDay;
    if (body.startDate) updateData.startDate = new Date(body.startDate);
    if (body.endDate !== undefined) updateData.endDate = body.endDate ? new Date(body.endDate) : null;

    await ref.update(updateData);
    const updated = await ref.get();
    return c.json({ id, message: 'Événement mis à jour', data: formatEventData(updated.data()) });
  } catch (error) {
    return c.json({ error: 'Erreur mise à jour', details: error.message }, 500);
  }
};

const deleteCalendarEvent = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('calendar').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Événement non trouvé' }, 404);
    await ref.delete();
    return c.json({ id, message: 'Événement supprimé' });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const deleteAllCalendarEvents = async (c) => {
  try {
    const snapshot = await db.collection('calendar').get();
    await Promise.all(snapshot.docs.map(doc => doc.ref.delete()));
    return c.json({ message: `${snapshot.size} événement(s) supprimé(s)` });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

function formatEvent(doc) {
  return { id: doc.id, ...formatEventData(doc.data()) };
}

function formatEventData(data) {
  return {
    title: data.title || '', description: data.description || '',
    startDate: data.startDate?.toDate() || null,
    endDate: data.endDate?.toDate() || null,
    type: data.type || 'event', location: data.location || '',
    color: data.color || '#D4AF37', allDay: data.allDay || false,
    createdAt: data.createdAt?.toDate() || new Date(),
    updatedAt: data.updatedAt?.toDate() || new Date(),
  };
}

module.exports = { createCalendarEvent, getAllCalendarEvents, getEventsByYear, getCalendarEventById, updateCalendarEvent, deleteCalendarEvent, deleteAllCalendarEvents };
```

---

## Fichier : src/controllers/userController.js

```javascript
const { db } = require('../config/firebase');

const createOrUpdateUser = async (c) => {
  try {
    const body = await c.req.json();
    const { uid, email, displayName, photoURL } = body;
    if (!uid) return c.json({ error: 'uid est requis' }, 400);

    const now = new Date();
    const data = { uid, email: email || '', displayName: displayName || '', photoURL: photoURL || '', lastLogin: now, updatedAt: now };

    const existing = await db.collection('users').doc(uid).get();
    if (existing.exists) {
      const update = { ...data };
      delete update.uid;
      if (existing.data().createdAt) delete update.createdAt;
      else update.createdAt = now;
      await db.collection('users').doc(uid).update(update);
    } else {
      data.createdAt = now;
      await db.collection('users').doc(uid).set(data);
    }

    return c.json({ uid, message: 'Utilisateur créé/mis à jour' }, existing.exists ? 200 : 201);
  } catch (error) {
    return c.json({ error: 'Erreur', details: error.message }, 500);
  }
};

const getAllUsers = async (c) => {
  try {
    const snapshot = await db.collection('users').orderBy('createdAt', 'desc').get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate(), updatedAt: doc.data().updatedAt?.toDate(), lastLogin: doc.data().lastLogin?.toDate() }));
    return c.json(users);
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const getUserById = async (c) => {
  try {
    const id = c.req.param('id');
    const doc = await db.collection('users').doc(id).get();
    if (!doc.exists) return c.json({ error: 'Utilisateur non trouvé' }, 404);
    const data = doc.data();
    return c.json({ id: doc.id, ...data, createdAt: data.createdAt?.toDate(), updatedAt: data.updatedAt?.toDate(), lastLogin: data.lastLogin?.toDate() });
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const updateUser = async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();
    const ref = db.collection('users').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Utilisateur non trouvé' }, 404);

    const updateData = { updatedAt: new Date() };
    ['email', 'displayName', 'photoURL'].forEach(f => { if (body[f] !== undefined) updateData[f] = body[f]; });
    if (body.fcmToken !== undefined) updateData.fcmToken = body.fcmToken;
    if (body.notificationPreferences !== undefined) updateData.notificationPreferences = body.notificationPreferences;

    await ref.update(updateData);
    return c.json({ id, message: 'Utilisateur mis à jour' });
  } catch (error) {
    return c.json({ error: 'Erreur mise à jour', details: error.message }, 500);
  }
};

const deleteUser = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('users').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Utilisateur non trouvé' }, 404);
    await ref.delete();
    return c.json({ id, message: 'Utilisateur supprimé' });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const deleteAllUsers = async (c) => {
  try {
    const snapshot = await db.collection('users').get();
    await Promise.all(snapshot.docs.map(doc => doc.ref.delete()));
    return c.json({ message: `${snapshot.size} utilisateur(s) supprimé(s)` });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const getUserStats = async (c) => {
  try {
    const snapshot = await db.collection('users').get();
    const total = snapshot.size;
    const now = new Date();
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
    let activeMonth = 0, withFcm = 0;
    snapshot.forEach(doc => {
      const d = doc.data();
      if (d.lastLogin?.toDate() > lastMonth) activeMonth++;
      if (d.fcmToken) withFcm++;
    });
    return c.json({ total, activeLastMonth: activeMonth, withFcmTokens: withFcm });
  } catch (error) {
    return c.json({ error: 'Erreur stats', details: error.message }, 500);
  }
};

module.exports = { createOrUpdateUser, getAllUsers, getUserById, updateUser, deleteUser, deleteAllUsers, getUserStats };
```

---

## Fichier : src/controllers/notificationController.js

```javascript
const { admin, db } = require('../config/firebase');

const registerToken = async (c) => {
  try {
    const body = await c.req.json();
    const { uid, token } = body;
    if (!uid || !token) return c.json({ error: 'uid et token sont requis' }, 400);

    await db.collection('users').doc(uid).update({ fcmToken: token, updatedAt: new Date() });
    await db.collection('fcm_tokens').doc(uid).set({ uid, token, createdAt: new Date(), updatedAt: new Date() });

    return c.json({ message: 'Token enregistré' });
  } catch (error) {
    return c.json({ error: 'Erreur enregistrement token', details: error.message }, 500);
  }
};

const unregisterToken = async (c) => {
  try {
    const body = await c.req.json();
    const { uid } = body;
    if (!uid) return c.json({ error: 'uid est requis' }, 400);

    await db.collection('users').doc(uid).update({ fcmToken: '', updatedAt: new Date() });
    await db.collection('fcm_tokens').doc(uid).delete();

    return c.json({ message: 'Token désenregistré' });
  } catch (error) {
    return c.json({ error: 'Erreur désenregistrement', details: error.message }, 500);
  }
};

const sendNotificationToAll = async (c) => {
  try {
    const { title, body: messageBody, imageUrl, type, data } = await c.req.json();
    if (!title) return c.json({ error: 'title est requis' }, 400);

    const fcmSnapshot = await db.collection('fcm_tokens').get();
    const tokens = [];
    fcmSnapshot.forEach(doc => { const t = doc.data().token; if (t) tokens.push(t); });
    if (tokens.length === 0) return c.json({ error: 'Aucun token disponible' }, 400);

    const msg = {
      notification: { title, body: messageBody || '', imageUrl: imageUrl || undefined },
      data: { ...(data || {}), type: type || 'general' },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(msg);

    await db.collection('notifications_outbox').add({
      title, body: messageBody || '', data: data || {}, type: type || 'general',
      imageUrl: imageUrl || '', createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return c.json({ success: true, successCount: response.successCount, failureCount: response.failureCount });
  } catch (error) {
    return c.json({ error: 'Erreur envoi', details: error.message }, 500);
  }
};

const sendNotificationToUser = async (c) => {
  try {
    const { userId, title, body: messageBody, imageUrl, type, data } = await c.req.json();
    if (!userId || !title) return c.json({ error: 'userId et title sont requis' }, 400);

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return c.json({ error: 'Utilisateur non trouvé' }, 404);
    const token = userDoc.data().fcmToken;
    if (!token) return c.json({ error: 'Aucun token FCM' }, 400);

    const msg = {
      notification: { title, body: messageBody || '', imageUrl: imageUrl || undefined },
      data: { ...(data || {}), type: type || 'general' },
      token,
    };

    await admin.messaging().send(msg);
    return c.json({ success: true });
  } catch (error) {
    return c.json({ error: 'Erreur envoi', details: error.message }, 500);
  }
};

const sendNotificationToTopic = async (c) => {
  try {
    const { topic, title, body: messageBody, imageUrl, type, data } = await c.req.json();
    if (!topic || !title) return c.json({ error: 'topic et title sont requis' }, 400);

    const msg = {
      notification: { title, body: messageBody || '', imageUrl: imageUrl || undefined },
      data: { ...(data || {}), type: type || 'general' },
      topic,
    };

    await admin.messaging().send(msg);

    await db.collection('notifications_outbox').add({
      title, body: messageBody || '', data: data || {}, type: type || 'general',
      imageUrl: imageUrl || '', topic, createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return c.json({ success: true });
  } catch (error) {
    return c.json({ error: 'Erreur envoi topic', details: error.message }, 500);
  }
};

module.exports = { registerToken, unregisterToken, sendNotificationToAll, sendNotificationToUser, sendNotificationToTopic };
```

---

## Fichier : src/controllers/textResumeController.js

```javascript
const { db } = require('../config/firebase');
const cloudinary = require('../config/cloudinary');
const r2 = require('../services/r2Service');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

async function fileToUpload(file) {
  return {
    originalname: file.name,
    mimetype: file.type,
    buffer: Buffer.from(await file.arrayBuffer()),
    size: file.size,
  };
}

function generateKey(prefix, file) {
  const ext = file.name.split('.').pop() || 'bin';
  return `${prefix}/${Date.now()}-${Math.round(Math.random() * 1E9)}.${ext}`;
}

async function resolvePdfUrl(data) {
  if (data.pdfKey) { const url = await r2.getDownloadUrl(data.pdfKey); if (url) return url; }
  return data.pdfUrl || '';
}

async function resolveCoverUrl(data) {
  if (data.coverImageKey) { const url = await r2.getDownloadUrl(data.coverImageKey); if (url) return url; }
  return data.coverImageUrl || '';
}

const createTextResume = async (c) => {
  try {
    const body = await c.req.parseBody();
    const title = body['title'];
    if (!title) return c.json({ error: 'Le titre est requis' }, 400);

    const rawPdf = body['pdf'];
    const rawImage = body['image'];
    if (!rawPdf || typeof rawPdf === 'string') return c.json({ error: 'Le fichier PDF est requis' }, 400);

    const now = new Date();
    const mois = body['mois']?.toString() || (now.getMonth() + 1).toString();
    const annee = body['annee']?.toString() || now.getFullYear().toString();

    const data = {
      title, description: body['description'] || '',
      category: body['category'] || 'Non classé',
      mois, annee, typeCulte: body['typeCulte'] || 'Conférence',
      pdfUrl: '', coverImageUrl: '',
      tags: body['tags'] ? (typeof body['tags'] === 'string' ? body['tags'].split(',').map(t => t.trim()) : body['tags']) : [],
      isNew: true, isFeatured: false, downloadCount: 0,
      publishedAt: now, createdAt: now, updatedAt: now,
    };

    const pdfUpload = await fileToUpload(rawPdf);
    const pdfResult = await r2.uploadFile(generateKey('textes_resumes/pdfs', rawPdf), pdfUpload.buffer, pdfUpload.mimetype);
    if (pdfResult.provider === 'r2') { data.pdfKey = pdfResult.key; data.pdfUrl = await r2.getDownloadUrl(pdfResult.key) || ''; }
    else { data.pdfPublicId = pdfResult.key; data.pdfUrl = pdfResult.url || ''; }

    if (rawImage && typeof rawImage !== 'string') {
      const imgUpload = await fileToUpload(rawImage);
      const imgResult = await r2.uploadFile(generateKey('textes_resumes/covers', rawImage), imgUpload.buffer, imgUpload.mimetype);
      if (imgResult.provider === 'r2') { data.coverImageKey = imgResult.key; data.coverImageUrl = await r2.getDownloadUrl(imgResult.key) || ''; }
      else { data.coverImagePublicId = imgResult.key; data.coverImageUrl = imgResult.url || ''; }
    }

    const docRef = await db.collection('textes_resumes').add(data);
    try { await sendNotificationToAllUsers({ title: 'Nouveau résumé disponible', body: title, data: { id: docRef.id, type: 'resume', resumeId: docRef.id }, type: 'resume' }); } catch {}
    return c.json({ id: docRef.id, message: 'Résumé créé', data }, 201);
  } catch (error) {
    return c.json({ error: 'Erreur création', details: error.message }, 500);
  }
};

async function formatTextResume(doc) {
  const d = doc.data();
  const [pdfUrl, coverImageUrl] = await Promise.all([resolvePdfUrl(d), resolveCoverUrl(d)]);
  return {
    id: doc.id, title: d.title || 'Titre non disponible',
    description: d.description || '', category: d.category || 'Non classé',
    pdfUrl, coverImageUrl, tags: d.tags || [],
    mois: d.mois?.toString() || '', annee: d.annee?.toString() || '',
    typeCulte: d.typeCulte || '', isNew: d.isNew || false,
    isFeatured: d.isFeatured || false, downloadCount: d.downloadCount || 0,
    publishedAt: d.publishedAt?.toDate() || new Date(),
    createdAt: d.createdAt?.toDate() || new Date(),
    updatedAt: d.updatedAt?.toDate() || new Date(),
  };
}

const getAllTextResumes = async (c) => {
  try {
    let query = db.collection('textes_resumes');
    const filters = { category: c.req.query('category'), mois: c.req.query('mois'), annee: c.req.query('annee'), typeCulte: c.req.query('typeCulte') };
    Object.entries(filters).forEach(([k, v]) => { if (v) query = query.where(k, '==', v); });

    const sortField = c.req.query('sortBy') || 'publishedAt';
    const order = c.req.query('order') === 'asc' ? 'asc' : 'desc';
    query = query.orderBy(sortField, order);

    const snapshot = await query.get();
    const results = await Promise.all(snapshot.docs.map(doc => formatTextResume(doc)));
    return c.json(results);
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

const getTextResumeById = async (c) => {
  try {
    const id = c.req.param('id');
    const doc = await db.collection('textes_resumes').doc(id).get();
    if (!doc.exists) return c.json({ error: 'Résumé non trouvé' }, 404);
    return c.json(await formatTextResume(doc));
  } catch (error) {
    return c.json({ error: 'Erreur récupération', details: error.message }, 500);
  }
};

async function deleteFiles(data) {
  if (data.pdfKey) await r2.deleteR2File(data.pdfKey);
  else if (data.pdfPublicId) try { await cloudinary.uploader.destroy(data.pdfPublicId, { resource_type: 'raw' }); } catch {}
  if (data.coverImageKey) await r2.deleteR2File(data.coverImageKey);
  else if (data.coverImagePublicId) try { await cloudinary.uploader.destroy(data.coverImagePublicId); } catch {}
}

const deleteTextResume = async (c) => {
  try {
    const id = c.req.param('id');
    const ref = db.collection('textes_resumes').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Résumé non trouvé' }, 404);
    await deleteFiles(doc.data());
    await ref.delete();
    return c.json({ id, message: 'Résumé supprimé' });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const deleteAllTextResumes = async (c) => {
  try {
    const snapshot = await db.collection('textes_resumes').get();
    const ids = [];
    await Promise.all(snapshot.docs.map(async (doc) => { ids.push(doc.id); await deleteFiles(doc.data()); await doc.ref.delete(); }));
    return c.json({ message: `${ids.length} résumé(s) supprimé(s)`, ids });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const deleteTextResumesByFilter = async (c) => {
  try {
    let query = db.collection('textes_resumes');
    ['category', 'mois', 'annee', 'typeCulte'].forEach(f => { const v = c.req.query(f); if (v) query = query.where(f, '==', v); });
    const snapshot = await query.get();
    const ids = [];
    await Promise.all(snapshot.docs.map(async (doc) => { ids.push(doc.id); await deleteFiles(doc.data()); await doc.ref.delete(); }));
    return c.json({ message: `${ids.length} résumé(s) supprimé(s)`, ids });
  } catch (error) {
    return c.json({ error: 'Erreur suppression', details: error.message }, 500);
  }
};

const updateTextResume = async (c) => {
  try {
    const id = c.req.param('id');
    const ct = c.req.header('content-type') || '';
    let body;
    if (ct.includes('multipart/form-data')) body = await c.req.parseBody();
    else body = await c.req.json();

    const ref = db.collection('textes_resumes').doc(id);
    const doc = await ref.get();
    if (!doc.exists) return c.json({ error: 'Résumé non trouvé' }, 404);

    const existing = doc.data();
    const updateData = { updatedAt: new Date() };
    ['title', 'description', 'category', 'typeCulte'].forEach(f => { if (body[f] !== undefined) updateData[f] = body[f]; });
    if (body['mois'] !== undefined) updateData.mois = body['mois'].toString();
    if (body['annee'] !== undefined) updateData.annee = body['annee'].toString();
    if (body['isNew'] !== undefined) updateData.isNew = body['isNew'] === true || body['isNew'] === 'true';
    if (body['isFeatured'] !== undefined) updateData.isFeatured = body['isFeatured'] === true || body['isFeatured'] === 'true';
    if (body['tags'] !== undefined) updateData.tags = typeof body['tags'] === 'string' ? body['tags'].split(',').map(s => s.trim()).filter(Boolean) : body['tags'];

    const rawPdf = body['pdf'];
    if (rawPdf && typeof rawPdf !== 'string') {
      if (existing.pdfKey) await r2.deleteR2File(existing.pdfKey);
      else if (existing.pdfPublicId) try { await cloudinary.uploader.destroy(existing.pdfPublicId, { resource_type: 'raw' }); } catch {}
      const upload = await fileToUpload(rawPdf);
      const result = await r2.uploadFile(generateKey('textes_resumes/pdfs', rawPdf), upload.buffer, upload.mimetype);
      if (result.provider === 'r2') { updateData.pdfKey = result.key; delete updateData.pdfPublicId; updateData.pdfUrl = await r2.getDownloadUrl(result.key) || ''; }
      else { updateData.pdfPublicId = result.key; delete updateData.pdfKey; if (result.url) updateData.pdfUrl = result.url; }
    }

    const rawImage = body['image'];
    if (rawImage && typeof rawImage !== 'string') {
      if (existing.coverImageKey) await r2.deleteR2File(existing.coverImageKey);
      else if (existing.coverImagePublicId) try { await cloudinary.uploader.destroy(existing.coverImagePublicId); } catch {}
      const upload = await fileToUpload(rawImage);
      const result = await r2.uploadFile(generateKey('textes_resumes/covers', rawImage), upload.buffer, upload.mimetype);
      if (result.provider === 'r2') { updateData.coverImageKey = result.key; delete updateData.coverImagePublicId; updateData.coverImageUrl = await r2.getDownloadUrl(result.key) || ''; }
      else { updateData.coverImagePublicId = result.key; delete updateData.coverImageKey; if (result.url) updateData.coverImageUrl = result.url; }
    }

    await ref.update(updateData);
    const updated = await ref.get();
    return c.json({ id, message: 'Résumé mis à jour', data: await formatTextResume(updated) });
  } catch (error) {
    return c.json({ error: 'Erreur mise à jour', details: error.message }, 500);
  }
};

module.exports = { createTextResume, getAllTextResumes, getTextResumeById, updateTextResume, deleteTextResume, deleteAllTextResumes, deleteTextResumesByFilter };
```

---

## Fichier : src/routes/enseignements.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/enseignementController');
const router = new Hono();

router.post('/', ctrl.createEnseignement);
router.get('/', ctrl.getAllEnseignements);
router.put('/:id', ctrl.updateEnseignement);
router.delete('/batch', ctrl.deleteEnseignementsByFilter);
router.delete('/all', ctrl.deleteAllEnseignements);
router.delete('/:id', ctrl.deleteEnseignement);

module.exports = router;
```

---

## Fichier : src/routes/annonces.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/annonceController');
const router = new Hono();

router.post('/', ctrl.createAnnonce);
router.get('/', ctrl.getAllAnnonces);
router.delete('/all', ctrl.deleteAllAnnonces);
router.delete('/:id', ctrl.deleteAnnonce);

module.exports = router;
```

---

## Fichier : src/routes/lives.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/liveController');
const router = new Hono();

router.get('/', ctrl.getAllLiveStreams);
router.get('/active', ctrl.getActiveLive);
router.get('/server-info', ctrl.getServerInfo);
router.get('/:id/viewers', ctrl.getViewerCount);
router.get('/:id', ctrl.getLiveStreamById);
router.post('/', ctrl.createLiveStream);
router.put('/:id', ctrl.updateLiveStream);
router.put('/:id/status', ctrl.updateLiveStreamStatus);
router.post('/:id/join', ctrl.incrementViewerCount);
router.post('/:id/leave', ctrl.decrementViewerCount);
router.delete('/all', ctrl.deleteAllLiveStreams);
router.delete('/:id', ctrl.deleteLiveStream);

module.exports = router;
```

---

## Fichier : src/routes/calendar.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/calendarController');
const router = new Hono();

router.post('/', ctrl.createCalendarEvent);
router.get('/', ctrl.getAllCalendarEvents);
router.get('/year/:year', ctrl.getEventsByYear);
router.get('/:id', ctrl.getCalendarEventById);
router.put('/:id', ctrl.updateCalendarEvent);
router.delete('/all', ctrl.deleteAllCalendarEvents);
router.delete('/:id', ctrl.deleteCalendarEvent);

module.exports = router;
```

---

## Fichier : src/routes/users.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/userController');
const router = new Hono();

router.post('/', ctrl.createOrUpdateUser);
router.get('/', ctrl.getAllUsers);
router.get('/stats', ctrl.getUserStats);
router.get('/:id', ctrl.getUserById);
router.put('/:id', ctrl.updateUser);
router.delete('/all', ctrl.deleteAllUsers);
router.delete('/:id', ctrl.deleteUser);

module.exports = router;
```

---

## Fichier : src/routes/notifications.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/notificationController');
const router = new Hono();

router.post('/tokens', ctrl.registerToken);
router.delete('/tokens', ctrl.unregisterToken);
router.post('/send/all', ctrl.sendNotificationToAll);
router.post('/send/user', ctrl.sendNotificationToUser);
router.post('/send/topic', ctrl.sendNotificationToTopic);

module.exports = router;
```

---

## Fichier : src/routes/textResumes.js

```javascript
const { Hono } = require('hono');
const ctrl = require('../controllers/textResumeController');
const router = new Hono();

router.post('/', ctrl.createTextResume);
router.get('/', ctrl.getAllTextResumes);
router.get('/:id', ctrl.getTextResumeById);
router.put('/:id', ctrl.updateTextResume);
router.delete('/batch', ctrl.deleteTextResumesByFilter);
router.delete('/all', ctrl.deleteAllTextResumes);
router.delete('/:id', ctrl.deleteTextResume);

module.exports = router;
```

---

## Fichier : src/utils/notificationHelper.js

```javascript
const { admin, db } = require('../config/firebase');

async function sendNotificationToAllUsers({ title, body, data, imageUrl, type }) {
  try {
    const fcmTokensSnapshot = await db.collection('fcm_tokens').get();
    const tokens = [];
    fcmTokensSnapshot.forEach(doc => {
      const tokenData = doc.data();
      if (tokenData.token) tokens.push(tokenData.token);
    });

    if (tokens.length === 0) return { success: false, message: 'Aucun token FCM' };

    const message = {
      notification: { title, body, imageUrl: imageUrl || undefined },
      data: { ...data, type: type || 'general' },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    await db.collection('notifications_outbox').add({
      title,
      body,
      data: data || {},
      type: type || 'general',
      imageUrl: imageUrl || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, successCount: response.successCount, failureCount: response.failureCount };
  } catch (error) {
    console.error('Erreur envoi notification:', error.message);
    throw error;
  }
}

async function sendNotificationToTopic({ topic, title, body, data, imageUrl, type }) {
  try {
    const message = {
      notification: { title, body, imageUrl: imageUrl || undefined },
      data: { ...data, type: type || 'general' },
      topic,
    };

    await admin.messaging().send(message);

    await db.collection('notifications_outbox').add({
      title,
      body,
      data: data || {},
      type: type || 'general',
      imageUrl: imageUrl || '',
      topic,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Erreur envoi notification topic:', error.message);
    throw error;
  }
}

module.exports = { sendNotificationToAllUsers, sendNotificationToTopic };
```

---

## Fichier : src/utils/ffmpeg_transcoder.js

```javascript
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class FFmpegTranscoder {
  constructor(streamKey = 'mykog_live') {
    this.streamKey = streamKey;
    this.rtmpUrl = `rtmp://localhost:1935/live/${streamKey}`;
    this.hlsPath = path.join(__dirname, '..', '..', 'hls_output', streamKey);
    this.process = null;
    this.isRunning = false;
    this.retryTimer = null;
    this.maxRetries = 10;
    this.retryCount = 0;
  }

  start() {
    if (this.isRunning) return;
    fs.mkdirSync(this.hlsPath, { recursive: true });
    this.isRunning = true;
    this.retryCount = 0;
    this._spawnFfmpeg();
  }

  _spawnFfmpeg() {
    if (this.process) {
      try { this.process.kill(); } catch {}
    }

    const ffmpegArgs = [
      '-i', this.rtmpUrl,
      '-timeout', '2000000',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-profile:v', 'baseline',
      '-level', '3.0',
      '-pix_fmt', 'yuv420p',
      '-vf', 'scale=360:202:force_original_aspect_ratio=decrease,pad=360:202:(ow-iw)/2:(oh-ih)/2',
      '-r', '20',
      '-g', '40',
      '-keyint_min', '40',
      '-force_key_frames', 'expr:gte(n,n_forced*40)',
      '-sc_threshold', '0',
      '-b:v', '400k',
      '-maxrate', '400k',
      '-bufsize', '800k',
      '-bf', '0',
      '-refs', '1',
      '-tune', 'zerolatency',
      '-x264opts', 'no-mbtree:no-cabac:no-8x8dct:weightp=0:no-deblock',
      '-movflags', '+faststart',
      '-c:a', 'aac',
      '-b:a', '48k',
      '-ar', '44100',
      '-ac', '1',
      '-aac_coder', 'fast',
      '-f', 'hls',
      '-hls_time', '2',
      '-hls_list_size', '10',
      '-hls_flags', 'delete_segments+independent_segments',
      '-hls_segment_type', 'mpegts',
      '-hls_segment_filename', path.join(this.hlsPath, 'segment_%03d.ts'),
      path.join(this.hlsPath, 'index.m3u8'),
    ];

    this.process = spawn('ffmpeg', ffmpegArgs, {
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 0,
    });

    this.process.stderr.on('data', (data) => {
      const output = data.toString();
      if (output.includes('error') || output.includes('Error') || output.includes('Failed')) {
        console.error(`FFmpeg: ${output}`);
      }
    });

    this.process.on('close', (code) => {
      if (code === 0 || code === null) {
        this.isRunning = false;
        return;
      }
      if (this.isRunning && this.retryCount < this.maxRetries) {
        this.retryCount++;
        const delay = Math.min(this.retryCount * 3000, 15000);
        this.retryTimer = setTimeout(() => this._spawnFfmpeg(), delay);
      } else {
        this.isRunning = false;
      }
    });

    this.process.on('error', () => {
      if (this.isRunning && this.retryCount < this.maxRetries) {
        this.retryCount++;
        const delay = Math.min(this.retryCount * 3000, 15000);
        this.retryTimer = setTimeout(() => this._spawnFfmpeg(), delay);
      } else {
        this.isRunning = false;
      }
    });
  }

  stop() {
    this.isRunning = false;
    if (this.retryTimer) {
      clearTimeout(this.retryTimer);
      this.retryTimer = null;
    }
    if (this.process) {
      this.process.kill('SIGTERM');
      setTimeout(() => {
        if (this.process && !this.process.killed) this.process.kill('SIGKILL');
      }, 5000);
    }
  }

  isActive() {
    return this.isRunning && this.process && !this.process.killed;
  }
}

module.exports = FFmpegTranscoder;
```

---

## Fichier : src/utils/stream_helper.js

```javascript
const os = require('os');

const STREAM_CONFIG = {
  DEFAULT_STREAM_KEY: 'mykog_live',
  RTMP_PORT: parseInt(process.env.RTMP_PORT || '1935'),
  HLS_PORT: 8080,
  HLS_PATH: '/hls',
};

function getServerIP() {
  const interfaces = os.networkInterfaces();
  const virtualInterfaces = ['virbr0', 'docker0', 'br-', 'veth', 'lo'];

  for (const name of Object.keys(interfaces)) {
    if (virtualInterfaces.some(vif => name.includes(vif))) continue;
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (iface.address.startsWith('192.168.') && !iface.address.startsWith('192.168.122.')) {
          return iface.address;
        }
      }
    }
  }

  for (const name of Object.keys(interfaces)) {
    if (virtualInterfaces.some(vif => name.includes(vif))) continue;
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (!iface.address.startsWith('172.17.') && !iface.address.startsWith('172.18.') && !iface.address.startsWith('192.168.122.')) {
          return iface.address;
        }
      }
    }
  }

  return 'localhost';
}

function getRTMPUrl(streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  const ip = getServerIP();
  return `rtmp://${ip}:${STREAM_CONFIG.RTMP_PORT}/live/${streamKey}`;
}

function getHLSUrl(streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  const ip = getServerIP();
  const apiPort = process.env.PORT || 3000;
  return `http://${ip}:${apiPort}${STREAM_CONFIG.HLS_PATH}/${streamKey}/index.m3u8`;
}

function getHLSUrlWithIP(ip, streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  const apiPort = process.env.PORT || 3000;
  return `http://${ip}:${apiPort}${STREAM_CONFIG.HLS_PATH}/${streamKey}/index.m3u8`;
}

function getRTMPUrlWithIP(ip, streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  return `rtmp://${ip}:${STREAM_CONFIG.RTMP_PORT}/live/${streamKey}`;
}

function isValidStreamKey(streamKey) {
  if (!streamKey || typeof streamKey !== 'string') return false;
  return /^[a-zA-Z0-9_-]+$/.test(streamKey);
}

function generateStreamKey() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `mykog_${timestamp}_${random}`;
}

module.exports = {
  STREAM_CONFIG,
  getServerIP,
  getRTMPUrl,
  getHLSUrl,
  getHLSUrlWithIP,
  getRTMPUrlWithIP,
  isValidStreamKey,
  generateStreamKey,
};
```

---

## Fichier : src/utils/veilleur.js

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
    console.log(`URL surveillée: ${this.url}`);
    this.ping();
    this.intervalId = setInterval(() => {
      this.ping();
    }, this.intervalMs);
  }

  ping() {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] Ping du serveur...`);
    
    const url = this.url.startsWith('http') ? this.url : `https://${this.url}`;
    const isHttps = url.startsWith('https://');
    const client = isHttps ? https : require('http');
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: '/api/enseignements',
      method: 'GET',
      headers: {
        'User-Agent': 'MyKOG-Veilleur/1.0',
        'X-Veilleur-Ping': 'true'
      },
      timeout: 15000
    };

    const req = client.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        console.log(`Ping réussi - Status: ${res.statusCode} - ${timestamp}`);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`Serveur actif et répond correctement`);
        }
      });
    });

    req.on('error', (err) => {
      console.error(`Erreur de ping: ${err.message}`);
      if (err.code === 'ECONNREFUSED') {
        console.log(`Serveur peut-être en démarrage...`);
      }
    });

    req.on('timeout', () => {
      console.error(`Timeout du ping après 15 secondes`);
      req.destroy();
    });

    req.end();
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      console.log('Veilleur arrêté');
    }
  }
}

module.exports = Veilleur;
```

---

## Fichier : CREATION_TOKEN_CLOUDFLARE_R2.md (racine du projet)

```markdown
# Création du Token API Cloudflare pour R2

## Étape 1 : Connexion au dashboard Cloudflare

1. Va sur https://dash.cloudflare.com
2. Connecte-toi avec ton compte Cloudflare

## Étape 2 : Création du Token API

1. Va sur https://dash.cloudflare.com/profile/api-tokens
2. Clique sur le bouton bleu "Create Token"

## Étape 3 : Utiliser le template R2

1. Dans la section "API Token Templates", cherche "Edit Cloudflare R2"
2. Clique sur "Use template"

## Étape 4 : Configuration du token

- Permissions : R2 → Edit
- Account Resources : Include → Specific account (sélectionne ton compte MyKOG)
- TTL : "Never Expire" (ou une date)

## Étape 5 : Finaliser

1. Clique sur "Continue to summary"
2. Vérifie le résumé
3. Clique sur "Create Token"
4. Copie le token immédiatement ! Format : oDOiNTxNvU4Fn5v...
5. Ajoute-le dans le `.env` : CLOUDFLARE_API_TOKEN=ton_token

## Test

Redémarre le serveur après avoir ajouté le token, les uploads iront vers R2 via l'API Cloudflare.
```

---

## Résumé des routes API (Hono)

### Enseignements `/api/enseignements`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer un enseignement (multipart: image+audio) |
| GET | `/` | Lister tous les enseignements |
| PUT | `/:id` | Mettre à jour un enseignement |
| DELETE | `/batch` | Supprimer par filtre (query: category, mois, annee, typeCulte) |
| DELETE | `/all` | Supprimer tous les enseignements |
| DELETE | `/:id` | Supprimer un enseignement |

### Annonces `/api/annonces`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer une annonce |
| GET | `/` | Lister les annonces |
| DELETE | `/all` | Supprimer toutes les annonces |
| DELETE | `/:id` | Supprimer une annonce |

### Lives `/api/lives`
| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/` | Lister les lives |
| GET | `/active` | Live actif |
| GET | `/server-info` | Infos serveur (IP, ports) |
| GET | `/:id/viewers` | Nombre de viewers |
| GET | `/:id` | Détail d'un live |
| POST | `/` | Créer un live |
| PUT | `/:id` | Mettre à jour un live |
| PUT | `/:id/status` | Changer le statut |
| POST | `/:id/join` | Incrémenter viewers |
| POST | `/:id/leave` | Décrémenter viewers |
| DELETE | `/all` | Supprimer tous les lives |
| DELETE | `/:id` | Supprimer un live |

### Calendar `/api/calendar`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer un événement |
| GET | `/` | Lister les événements |
| GET | `/year/:year` | Filtrer par année |
| GET | `/:id` | Détail d'un événement |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/all` | Supprimer tout |
| DELETE | `/:id` | Supprimer un |

### Users `/api/users`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer/mettre à jour |
| GET | `/` | Lister les utilisateurs |
| GET | `/stats` | Statistiques |
| GET | `/:id` | Détail |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/all` | Supprimer tout |
| DELETE | `/:id` | Supprimer |

### Notifications `/api/notifications`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/tokens` | Enregistrer un token FCM |
| DELETE | `/tokens` | Désenregistrer |
| POST | `/send/all` | Envoyer à tous |
| POST | `/send/user` | Envoyer à un user |
| POST | `/send/topic` | Envoyer à un topic |

### Text Resumes `/api/text-resumes`
| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/` | Créer un résumé (multipart: pdf+image) |
| GET | `/` | Lister (avec filtres query) |
| GET | `/:id` | Détail |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/batch` | Supprimer par filtre |
| DELETE | `/all` | Supprimer tout |
| DELETE | `/:id` | Supprimer |

---

## Dépendances (package.json)

| Package | Version | Rôle |
|---------|---------|------|
| `hono` | ^4.7.0 | Framework web (remplace Express) |
| `@hono/node-server` | ^1.14.0 | Serveur Node.js pour Hono |
| `firebase-admin` | ^13.6.0 | Firebase Admin SDK |
| `@aws-sdk/client-s3` | ^3.1073.0 | Client S3 pour R2 |
| `@aws-sdk/s3-request-presigner` | ^3.1073.0 | Presigned URLs pour R2 |
| `cloudinary` | ^1.41.3 | Fallback upload images/audio |
| `node-media-server` | ^4.2.8 | Serveur RTMP pour live streaming |
| `dotenv` | ^16.4.7 | Variables d'environnement |

---

## Problèmes connus

1. **R2 S3 endpoint bloqué** : `*.r2.cloudflarestorage.com` rejette le TLS. Solution : utiliser l'API Cloudflare v4 avec un token (tuto dans `CREATION_TOKEN_CLOUDFLARE_R2.md`).
2. **Port RTMP 1935 occupé** : Un processus inconnu sur ce serveur bloque le port 1935. Le fallback est sur le port 1936 (configurable via `RTMP_PORT`).
3. **Firebase Admin SDK** : Utilisé en Phase 1 (local Node.js). Pour le déploiement Workers (Phase 2), il faudra le remplacer par Firebase REST API.
