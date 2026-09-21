# Analyse complète du Backend MyKOG-Terminal

## 1. Vue d'ensemble

**Backend API** — `/home/zfred/Bureau/Zfred/MyKOG-Terminal/backend-API/`

Stack technique :
- **Runtime** : Node.js (CommonJS)
- **Framework** : Express 5.1.0 (uniquement, aucun Hono)
- **Base de données** : Firestore (Firebase Admin SDK)
- **Stockage média primaire** : Cloudflare R2 (S3-compatible)
- **Stockage média fallback** : Cloudinary
- **Streaming live** : Node-Media-Server (RTMP) + FFmpeg (transcodage HLS)
- **Notifications push** : Firebase Cloud Messaging (FCM)
- **Upload fichiers** : Multer (memory + disk storage)
- **Port** : 3001 (dev) / 10000 (production Render)
- **Type** : CommonJS (`"type": "commonjs"`)

---

## 2. Architecture MVC (Modèle-Vue-Contrôleur)

```
config/          → Configuration (Firebase, Cloudinary)
controllers/     → Logique métier (traitement des requêtes)
middleware/      → Middleware (upload multer)
routes/          → Définition des endpoints Express
services/        → Services externes (Streaming, R2)
utils/           → Utilitaires (FFmpeg, notifications, réseau)
├── server.js    → Point d'entrée (init Express, montage routes, démarrage)
├── veilleur.js  → Keep-alive pour Render
├── .env         → Variables d'environnement
├── render.yaml  → Déploiement Render
└── public/      → Fichiers statiques (dashboard admin HTML)
```

---

## 3. Arborescence des fichiers

```
backend-API/
├── .env                          # Variables d'environnement (Firebase, R2, Render)
├── .env.render                   # Variables pour Render
├── package.json                  # Dépendances et scripts
├── package-lock.json
├── server.js                     # POINT D'ENTRÉE — Initialise Express
├── veilleur.js                   # Classe Veilleur (ping anti-sleep Render)
├── render.yaml                   # Configuration déploiement Render
├── config/
│   ├── firebase.js               # Initialisation Firebase Admin SDK + Firestore
│   └── cloudinary.js             # Configuration Cloudinary (fallback)
├── middleware/
│   └── upload.js                 # Middleware Multer (memoryStorage, 300MB max)
├── controllers/
│   ├── enseignementController.js # CRUD Enseignements (audio + image)
│   ├── annonceController.js      # CRUD Annonces
│   ├── liveController.js         # CRUD Live streams + gestion transcodage
│   ├── calendarController.js     # CRUD Événements calendrier
│   ├── userController.js         # CRUD Utilisateurs + statistiques
│   ├── notificationController.js # Gestion tokens FCM + envoi notifications
│   └── textResumeController.js   # CRUD Textes résumés (PDF + cover)
├── routes/
│   ├── enseignements.js          # Routes /api/enseignements
│   ├── annonces.js               # Routes /api/annonces
│   ├── lives.js                  # Routes /api/lives
│   ├── calendar.js               # Routes /api/calendar
│   ├── users.js                  # Routes /api/users
│   ├── notifications.js          # Routes /api/notifications
│   └── textResumes.js            # Routes /api/text-resumes
├── services/
│   ├── streamingService.js       # Serveur RTMP (Node-Media-Server)
│   └── r2Service.js              # Client S3 Cloudflare R2 + fallback Cloudinary
├── utils/
│   ├── stream_helper.js          # URLs RTMP/HLS, détection IP, validation clés
│   ├── ffmpeg_transcoder.js      # Transcodage RTMP → HLS via FFmpeg
│   ├── notificationHelper.js     # Envoi notifications Firebase avec retry/timeout
│   └── network_detector.js       # Détection IP réseau (hotspot, wifi, ethernet)
├── hls/                          # Dossier HLS live (généré par Node-Media-Server)
├── hls_output/                   # Dossier HLS transcodé (généré par FFmpeg)
└── public/
    └── admin-dashboard.html      # Dashboard admin statique
```

---

## 4. Point d'entrée — server.js

Fichier : `server.js`

```javascript
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const multer = require("multer");
```

**Middleware globaux :**
- `cors()` — CORS activé
- `express.json()` — Parsing JSON
- `express.urlencoded({ extended: true })` — Parsing form-data
- `express.static('public')` — Fichiers statiques (dashboard admin)
- `express.static('hls_output')` — Fichiers HLS sous `/hls`

**Montage des routes :**

| Préfixe | Fichier de routes | Contrôleur associé |
|---|---|---|
| `/api/enseignements` | `routes/enseignements.js` | `enseignementController.js` |
| `/api/annonces` | `routes/annonces.js` | `annonceController.js` |
| `/api/lives` | `routes/lives.js` | `liveController.js` |
| `/api/calendar` | `routes/calendar.js` | `calendarController.js` |
| `/api/users` | `routes/users.js` | `userController.js` |
| `/api/notifications` | `routes/notifications.js` | `notificationController.js` |
| `/api/text-resumes` | `routes/textResumes.js` | `textResumeController.js` |

**Route de test :**
- `GET /` → `{ message: "Serveur Enseignement API opérationnel 🚀" }`

**Gestion erreurs :**
- Erreurs `multer.MulterError` → 400 (fichier trop volumineux)
- Autres → 500 avec message d'erreur

**Démarrage :**
1. `app.listen(PORT)` sur le port configuré
2. `startStreamingServer()` — démarre le serveur RTMP Node-Media-Server
3. En production : démarre le `Veilleur` (ping toutes les 14 min)

---

## 5. Configuration

### 5.1 Firebase (`config/firebase.js`)
- Initialisation Firebase Admin SDK avec credentials depuis `.env`
- Utilise `admin.credential.cert(serviceAccount)` 
- Exporte `admin` (instance Firebase) et `db` (Firestore)
- Firestore configuré avec `ignoreUndefinedProperties: true`
- Vérifie si déjà initialisé pour éviter les doublons

### 5.2 Cloudinary (`config/cloudinary.js`)
- Initialisation Cloudinary v2 avec `cloud_name`, `api_key`, `api_secret`
- Utilisé uniquement comme fallback quand R2 est inaccessible
- Exporte l'instance cloudinary

### 5.3 Variables d'environnement (`.env`)
```
CF_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME, R2_ENDPOINT  → Cloudflare R2
FIREBASE_* → Firebase Admin SDK
PORT=3001
NODE_ENV=development
RENDER_URL=https://mykog-backend-api.onrender.com
```

---

## 6. Middleware — Upload (`middleware/upload.js`)

Utilise `multer` avec `memoryStorage()` :
- Limite : 300 Mo par fichier
- Logge chaque fichier reçu (fieldname, originalname, mimetype, size)
- Accepte tous les types de fichiers (`cb(null, true)`)

---

## 7. Routes et Controllers (7 entités métier)

### 7.1 Enseignements — `/api/enseignements`

**Collection Firestore :** `enseignements`

**Endpoints :**

| Méthode | Chemin | Description | Middleware |
|---|---|---|---|
| POST | `/` | Créer un enseignement | `upload.fields([image, audio])` |
| GET | `/` | Lister tous les enseignements | — |
| PUT | `/:id` | Mettre à jour un enseignement | `upload.fields([image])` |
| DELETE | `/batch` | Supprimer par filtre (query: category, mois, annee) | — |
| DELETE | `/all` | Supprimer tous | — |
| DELETE | `/:id` | Supprimer un enseignement | — |

**Champs d'un enseignement dans Firestore :**
```
title, speaker, description, category, duration,
audioUrl, artworkUrl, tags[], playCount, rating,
isNew, isFeatured, publishedAt, createdAt, updatedAt,
mois, annee, typeCulte,
imageKey (R2) ou imagePublicId (Cloudinary),
audioKey (R2) ou audioPublicId (Cloudinary)
```

**Logique métier clé :**
- Upload image + audio vers R2 via `r2.uploadBuffer()`
- Résolution des URLs signées R2 au moment de la lecture
- Notification push envoyée à la création
- Gestion double provider (R2 primaire, Cloudinary fallback)
- Suppression des fichiers du provider lors de la suppression

### 7.2 Annonces — `/api/annonces`

**Collection Firestore :** `annonces`

**Endpoints :**

| Méthode | Chemin | Description |
|---|---|---|
| POST | `/` | Créer une annonce |
| GET | `/` | Lister toutes les annonces |
| DELETE | `/:id` | Supprimer une annonce |
| DELETE | `/all` | Supprimer toutes |

**Champs :** `nom, description, dateCreation`

**Logique :** Notification push envoyée à tous les utilisateurs à la création

### 7.3 Lives — `/api/lives`

**Collection Firestore :** `liveStreams`

**Endpoints :**

| Méthode | Chemin | Description |
|---|---|---|
| POST | `/` | Créer un live |
| GET | `/` | Lister tous les lives |
| GET | `/active` | Live actuellement actif |
| GET | `/server-info` | Infos serveur (IP, URLs) |
| GET | `/:id` | Live par ID |
| GET | `/:id/viewers` | Nombre de viewers |
| PUT | `/:id` | Mettre à jour un live |
| PUT | `/:id/status` | Changer statut (scheduled/live/ended) |
| POST | `/:id/join` | Incrémenter viewers |
| POST | `/:id/leave` | Décrémenter viewers |
| DELETE | `/all` | Supprimer tous |
| DELETE | `/:id` | Supprimer un live |

**Champs :** `title, description, pastor, thumbnailUrl, streamUrl, streamKey, rtmpUrl, hlsUrl, status, scheduledAt, startedAt, endedAt, viewerCount, peakViewerCount, tags`

**Logique métier clé :**
- Génération automatique URLs RTMP/HLS basées sur l'IP du serveur
- Démarrage/arrêt automatique du transcodage FFmpeg selon le statut
- Gestion des transcoders actifs via `global.__activeTranscoders (Map)`
- Tri des lives : live → scheduled → ended

### 7.4 Calendrier — `/api/calendar`

**Collection Firestore :** `calendar`

**Endpoints :**

| Méthode | Chemin | Description |
|---|---|---|
| POST | `/` | Créer un événement |
| GET | `/` | Lister tous les événements |
| GET | `/year/:year` | Filtrer par année |
| GET | `/:id` | Événement par ID |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/all` | Supprimer tous |
| DELETE | `/:id` | Supprimer un événement |

**Champs :** `id, title, description, startDate, endDate, location, category, color, isAllDay, createdBy, hasAlarm, alarmDaysBefore, alarmHoursBefore, alarmMinutesBefore, createdAt, updatedAt`

**Logique :** Notification push envoyée à la création et mise à jour (non-bloquante)

### 7.5 Utilisateurs — `/api/users`

**Collection Firestore :** `users`

**Endpoints :**

| Méthode | Chemin | Description |
|---|---|---|
| POST | `/` | Créer ou mettre à jour (upsert) |
| GET | `/` | Lister tous |
| GET | `/stats` | Statistiques |
| GET | `/:id` | Utilisateur par ID |
| PUT | `/:id` | Mettre à jour |
| DELETE | `/all` | Supprimer tous |
| DELETE | `/:id` | Supprimer |

**Champs :** `id, name, email, profileImageUrl, favoriteTeachingIds[], downloadedTeachingIds[], recentlyPlayedIds[], notificationsEnabled, fcmTokens[]`

**Statistiques :** totalUsers, usersWithFavorites, usersWithDownloads, totalFavorites, totalDownloads, notificationsEnabled/Disabled

### 7.6 Notifications — `/api/notifications`

**Collections Firestore :** `fcm_tokens`, `notifications_outbox`

**Endpoints :**

| Méthode | Chemin | Description |
|---|---|---|
| POST | `/tokens` | Enregistrer un token FCM |
| DELETE | `/tokens` | Supprimer un token FCM |
| POST | `/send/all` | Notification à tous |
| POST | `/send/user` | Notification à un utilisateur |
| POST | `/send/topic` | Notification à un topic |

**Logique :**
- Création auto d'utilisateur si inexistant lors de l'enregistrement token
- Envoi par batch de 500 tokens (limite FCM)
- Retry 3 fois sur erreur réseau avec timeout 30s
- Suppression automatique des tokens invalides
- Sauvegarde dans `notifications_outbox` pour clients desktop

### 7.7 Textes Résumés — `/api/text-resumes`

**Collection Firestore :** `textes_resumes`

**Endpoints :**

| Méthode | Chemin | Description | Middleware |
|---|---|---|---|
| POST | `/` | Créer un texte résumé | `upload.fields([pdf, image])` |
| GET | `/` | Lister (avec filtres: category, mois, annee, typeCulte, sortBy, order) | — |
| GET | `/:id` | Par ID (incrémente viewCount) | — |
| PUT | `/:id` | Mettre à jour | `upload.fields([pdf, image])` |
| DELETE | `/batch` | Supprimer par filtre | — |
| DELETE | `/all` | Supprimer tous | — |
| DELETE | `/:id` | Supprimer un | — |

**Champs :** `title, speaker, description, category, pdfUrl, coverImageUrl, tags[], viewCount, rating, isNew, isFeatured, publishedAt, createdAt, updatedAt, mois, annee, typeCulte, pdfKey, coverImageKey, fileSize, pageCount`

**Logique :**
- Upload PDF et cover image vers R2
- Validation MIME (PDF uniquement)
- Résolution d'URLs signées R2 à la lecture
- Incrémentation viewCount à chaque consultation
- Utilise `multer.diskStorage` (temporaire) contrairement aux autres contrôleurs
- Notification push à la création

---

## 8. Services

### 8.1 Streaming Service (`services/streamingService.js`)
- Serveur RTMP via `node-media-server`
- Port : 1935
- Écoute les événements : preConnect, postConnect, doneConnect, prePublish, donePublish
- Exporte : `startStreamingServer()`, `stopStreamingServer()`, `getServerInfo()`

### 8.2 R2 Service (`services/r2Service.js`)
- Client S3 Cloudflare R2 via `@aws-sdk/client-s3`
- Timeouts : connexion 15s, socket 120s
- **Fonctions exportées :**
  - `uploadFile(key, body, contentType)` — Upload avec fallback Cloudinary si R2 inaccessible
  - `uploadBuffer(file, prefix)` — Upload depuis buffer avec horodatage
  - `getDownloadUrl(key, expiresIn=604800)` — URL signée (7 jours par défaut)
  - `deleteR2File(key)` — Suppression avec fallback si R2 inaccessible
- Fallback automatique vers Cloudinary en cas d'erreur réseau/handshake

---

## 9. Utilitaires

### 9.1 Stream Helper (`utils/stream_helper.js`)
- Configuration : `RTMP_PORT=1935`, `HLS_PORT=8080`, `HLS_PATH=/hls`
- `getServerIP()` — Détection intelligente de l'IP (priorité 192.168.x.x, exclut les interfaces virtuelles)
- `getRTMPUrl(streamKey)` — Génération URL RTMP complète
- `getHLSUrl(streamKey)` — Génération URL HLS complète
- `getHLSUrlWithIP(ip, streamKey)` — URL HLS avec IP personnalisée
- `getRTMPUrlWithIP(ip, streamKey)` — URL RTMP avec IP personnalisée
- `isValidStreamKey(streamKey)` — Validation regex `^[a-zA-Z0-9_-]+$`
- `generateStreamKey()` — Génération clé aléatoire horodatée

### 9.2 FFmpeg Transcoder (`utils/ffmpeg_transcoder.js`)
- Classe `FFmpegTranscoder` : convertit flux RTMP → HLS
- Arguments FFmpeg : libx264, 360x202, 400kbps, 48kbps audio, segments 2s
- Répertoire de sortie : `hls_output/{streamKey}/`
- Auto-retry jusqu'à 10 tentatives avec délai progressif (3s → 15s)
- Nettoyage : SIGTERM puis SIGKILL après 5s

### 9.3 Notification Helper (`utils/notificationHelper.js`)
- `sendNotificationToAllUsers({title, body, data, imageUrl, type})` — Notification à tous via FCM
- `sendNotificationToTopic(topic, {title, body, data, imageUrl, type})` — Notification par topic
- Retry 3 fois sur erreur réseau avec timeout 30s
- Écrit dans `notifications_outbox` Firestore pour clients desktop
- Suppression des tokens FCM invalides
- Détection des erreurs réseau (EAI_AGAIN, getaddrinfo, timeout)

### 9.4 Network Detector (`utils/network_detector.js`)
- `detectLocalIP()` — Détection IP avec priorité :
  1. Hotspot (ap0)
  2. WiFi (wlan, wlp, wifi)
  3. Ethernet (eth, enp)
  4. Fallback première IP non interne
- `getAllIPs()` — Affiche toutes les interfaces réseau

---

## 10. Veilleur — Anti-sleep Render (`veilleur.js`)

Classe `Veilleur` qui pinge `GET /api/enseignements` à intervalles réguliers (14 min par défaut) pour empêcher Render de mettre le serveur en veille.

- URL cible : `RENDER_URL` ou `http://localhost:PORT`
- Timeout 15s
- Logge chaque ping avec timestamp

---

## 11. Déploiement Render (`render.yaml`)

```yaml
service: web
name: mykog-backend-api
env: node
plan: free
startCommand: node server.js
healthCheckPath: /
domains: mykog-backend-api.onrender.com
```

---

## 12. Comment enregistrer des médias dans Cloudflare R2

Le service R2 est déjà entièrement implémenté dans `services/r2Service.js`. Voici comment l'utiliser :

### Configuration requise (`.env`)
```
CF_ACCOUNT_ID=51818a41cb1910fba33adcc8f6d873e
R2_ACCESS_KEY_ID=votre_access_key
R2_SECRET_ACCESS_KEY=votre_secret_key
R2_BUCKET_NAME=my-kog-media
R2_ENDPOINT=https://{account_id}.r2.cloudflarestorage.com
```

### API exposée par `r2Service.js`

#### Upload depuis un buffer (recommandé pour les fichiers reçus via Multer)
```javascript
const r2 = require('./services/r2Service');

// req.file est un fichier uploadé via Multer memoryStorage
const result = await r2.uploadBuffer(req.file, 'enseignements/images');
// result = { key: 'enseignements/images/123456789-987654321.jpg', provider: 'r2' }
```

#### Upload direct avec clé personnalisée
```javascript
const buffer = fs.readFileSync('mon-fichier.mp4');
const result = await r2.uploadFile('videos/mon-fichier.mp4', buffer, 'video/mp4');
```

#### Obtenir une URL signée (téléchargement)
```javascript
const url = await r2.getDownloadUrl('enseignements/images/123456789-987654321.jpg');
// URL signée valide 7 jours (par défaut)

// Avec expiration personnalisée (en secondes)
const url = await r2.getDownloadUrl('mon-fichier.mp4', 3600); // 1 heure
```

#### Supprimer un fichier
```javascript
await r2.deleteR2File('enseignements/images/123456789-987654321.jpg');
```

### Architecture de fallback

Le `r2Service.js` implémente un **fallback automatique** : si R2 est inaccessible (erreur réseau, handshake, DNS), il bascule automatiquement vers Cloudinary. Les clés de stockage sont :
- R2 : `imageKey`, `audioKey`, `pdfKey`, `coverImageKey`
- Cloudinary : `imagePublicId`, `audioPublicId`, `pdfPublicId`, `coverImagePublicId`

### Exemple complet d'upload dans un contrôleur

```javascript
const r2 = require('../services/r2Service');

// 1. Upload du fichier
const result = await r2.uploadBuffer(req.files.image[0], 'enseignements/images');

// 2. Récupération URL signée (si stocké sur R2)
let url = '';
if (result.provider === 'r2') {
  url = await r2.getDownloadUrl(result.key);
} else {
  url = result.url; // Cloudinary fournit l'URL directement
}

// 3. Sauvegarde de la clé dans Firestore
await db.collection('ma_collection').add({
  imageKey: result.provider === 'r2' ? result.key : null,
  imagePublicId: result.provider === 'cloudinary' ? result.key : null,
  imageUrl: url,
});
```

### Créer un bucket R2 (via dashboard Cloudflare)
1. Aller sur https://dash.cloudflare.com → R2
2. Cliquer "Create bucket"
3. Nom : `my-kog-media` (ou celui de votre choix)
4. Créer les clés d'API dans "Manage R2 API Tokens"
5. Ajouter les permissions : `Object Read & Write`

---

## 13. Dépendances (`package.json`)

```json
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
}
```

**Notes :**
- `@aws-sdk/client-s3` et `@aws-sdk/s3-request-presigner` → Cloudflare R2 (API S3 compatible)
- `livekit-server-sdk` est installé mais pas utilisé dans `backend-API` (utilisé dans backend-hono)
- `swagger-jsdoc` et `swagger-ui-express` sont installés mais pas encore montés dans `server.js`
- `cloudinary` + `multer-storage-cloudinary` → fallback upload

---

## 14. Scripts npm

| Script | Commande |
|---|---|
| `npm start` | `node server.js` |
| `npm run dev` | `nodemon server.js` |
| `npm run veilleur` | Lance le veilleur seul |
| `npm run livekit:start` | `bash start_livekit.sh` |
| `npm run livekit:stop` | `bash stop_livekit.sh` |
| `npm run livekit:logs` | `tail -f livekit.log` |
| `npm run start:all` | LiveKit + serveur |
