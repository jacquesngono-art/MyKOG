# Backend API — MyKOG

## Stack

| Technologie | Usage |
|---|---|
| **Express.js 5.1** | Serveur HTTP |
| **Firebase Admin SDK** (Firestore) | Base de données NoSQL |
| **Cloudinary** | Stockage d'images, audios, PDFs |

| **Firebase Cloud Messaging (FCM)** | Notifications push |
| **Multer** | Upload fichiers temporaires |

---

## Informations générales

- **Base URL** : `http://localhost:3000/api`
- **Port** : `3000` (configurable via `PORT`)
- **Format** : JSON
- **Auth** : Aucune (le frontend n'a pas besoin de token)
- **Upload fichiers** : `multipart/form-data` (via Multer → Cloudinary)
- **Timeout conseillé** : 30s (certaines requêtes upload peuvent être longues)

---

## Ressources

### 1. Enseignements

Endpoints : `/api/enseignements`

Collection Firestore : `enseignements`

#### GET `/api/enseignements`

Récupère tous les enseignements.

**Réponse** : `Enseignement[]`

```ts
interface Enseignement {
  id: string;
  title: string;            // Requis
  speaker: string;          // Requis
  description: string;
  category: string;         // Requis
  duration: number;         // secondes
  audioUrl: string;         // URL Cloudinary
  artworkUrl: string;       // URL Cloudinary (image)
  tags: string[];
  playCount: number;
  rating: number;           // 0.0 - 5.0
  isNew: boolean;
  isFeatured: boolean;
  publishedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  mois: string;             // "1" - "12"
  annee: string;            // ex: "2026"
  typeCulte: string;        // ex: "Culte de Louange"
}
```

#### POST `/api/enseignements`

Crée un enseignement avec fichiers audio + image.

**Content-Type** : `multipart/form-data`

**Champs** :
| Champ | Type | Requis |
|---|---|---|
| `title` | string | Oui |
| `speaker` | string | Oui |
| `category` | string | Oui |
| `description` | string | Non |
| `duration` | number (secondes) | Non |
| `tags` | string (séparés par `,`) | Non |
| `mois` | string | Non (défaut: mois actuel) |
| `annee` | string | Non (défaut: année actuelle) |
| `typeCulte` | string | Non (défaut: "Culte de Louange") |
| `image` | file (jpg/png) | **Oui** (max 50MB) |
| `audio` | file (mp3) | **Oui** (max 50MB) |

**Réponse** `201` :
```ts
{
  id: string,
  message: "Enseignement créé avec succès",
  data: Enseignement
}
```

#### PUT `/api/enseignements/:id`

Met à jour un enseignement.

**Content-Type** : `multipart/form-data` (si upload image) ou `application/json`

**Champs** (tous optionnels) :
| Champ | Type |
|---|---|
| `title` | string |
| `speaker` | string |
| `description` | string |
| `category` | string |
| `playCount` | number |
| `rating` | number |
| `isNew` | boolean |
| `isFeatured` | boolean |
| `tags` | string ou string[] |
| `typeCulte` | string |
| `mois` | string |
| `annee` | string |
| `image` | file (optionnel - remplace l'image Cloudinary) |

#### DELETE `/api/enseignements/:id`

Supprime un enseignement (supprime aussi les fichiers Cloudinary).

**Réponse** : `{ id, message }`

#### DELETE `/api/enseignements/all`

Supprime tous les enseignements.

**Réponse** : `{ message, deleted: number }`

---

### 2. Annonces

Endpoints : `/api/annonces`

Collection Firestore : `annonces`

#### GET `/api/annonces`

```ts
interface Annonce {
  id: string;
  nom: string;
  description: string;
  dateCreation: Date;
}
```

#### POST `/api/annonces`

```ts
// Body (JSON) :
{ nom: string, description: string }

// Response 201 :
{ id: string, message: string, data: Annonce }
```

#### DELETE `/api/annonces/all`

Supprime toutes les annonces.

---

### 3. Lives / Streaming

Endpoints : `/api/lives`

Collection Firestore : `liveStreams`

#### GET `/api/lives`

Trie : live → scheduled → ended.

```ts
interface LiveStream {
  id: string;
  title: string;
  description: string;
  pastor: string;
  thumbnailUrl: string;
  streamUrl: string;        // URL HLS
  streamKey: string;
  rtmpUrl: string;          // URL RTMP pour OBS
  hlsUrl: string;           // URL HLS générée
  status: "scheduled" | "live" | "ended";
  scheduledAt: Date | null;
  startedAt: Date | null;
  endedAt: Date | null;
  viewerCount: number;
  peakViewerCount: number;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}
```

#### GET `/api/lives/active`

Retourne le live actif le plus récent (status="live").

**Réponse** : `LiveStream`
**404** si aucun live actif : `{ error: "Aucun live actif", data: null }`

#### GET `/api/lives/server-info`

```ts
{ serverIP: string, rtmpUrl: string, hlsUrl: string, streamKey: string, rtmpPort: number, hlsPort: number, hlsPath: string }
```

#### GET `/api/lives/:id`

#### GET `/api/lives/:id/viewers`

```ts
{ id: string, viewerCount: number, peakViewerCount: number, status: string }
```

#### POST `/api/lives`

```ts
// Body (JSON) :
{
  title: string,           // Requis
  pastor: string,          // Requis
  description?: string,
  thumbnailUrl?: string,
  scheduledAt?: string,    // ISO date
  streamUrl?: string,       // HLS custom
  streamKey?: string,       // custom stream key
  serverIP?: string,        // custom IP
  tags?: string[],
  status?: "scheduled" | "live" | "ended"  // défaut: "scheduled"
}

// Response 201 :
{ id: string, message: string, data: LiveStream }
```

#### PUT `/api/lives/:id`

Met à jour un live. Mêmes champs que POST (tous optionnels).
Gère aussi la génération des URLs si `streamKey` ou `serverIP` change.

#### PUT `/api/lives/:id/status`

```ts
// Body :
{ status: "scheduled" | "live" | "ended" }
```
Déclenche automatiquement le démarrage/arrêt du transcodage FFmpeg.

#### POST `/api/lives/:id/join`

Incrémente `viewerCount`. **Réponse** : `{ id, viewerCount, peakViewerCount }`

#### POST `/api/lives/:id/leave`

Décrémente `viewerCount` (min 0). **Réponse** : `{ id, viewerCount }`

#### DELETE `/api/lives/:id`

#### DELETE `/api/lives/all`

---

### 4. Calendrier

Endpoints : `/api/calendar`

Collection Firestore : `calendar`

#### GET `/api/calendar`

Tous les événements triés par `startDate` asc.

#### GET `/api/calendar/year/:year`

Filtre par année (ex: 2026).

#### GET `/api/calendar/:id`

#### POST `/api/calendar`

```ts
// Body (JSON) :
{
  title: string,            // Requis
  startDate: string,        // Requis (ISO date)
  endDate?: string,         // ISO date
  description?: string,
  location?: string,
  category?: string,
  color?: string,           // ex: "#3B82F6"
  isAllDay?: boolean,
  createdBy?: string,
  hasAlarm?: boolean,
  alarmDaysBefore?: number,
  alarmHoursBefore?: number,
  alarmMinutesBefore?: number
}
// L'ID est généré côté serveur (non fourni par le client)
```

**Réponse** `201` : l'objet événement complet avec son `id`.

#### PUT `/api/calendar/:id`

Tous les champs du POST sont optionnels en update.

#### DELETE `/api/calendar/:id`

#### DELETE `/api/calendar/all`

---

### 5. Utilisateurs

Endpoints : `/api/users`

Collection Firestore : `users`

#### GET `/api/users`

Liste de tous les utilisateurs triés par `createdAt` desc.

```ts
interface User {
  id: string;
  name: string;
  email: string;
  profileImageUrl?: string;
  favoriteTeachingIds: string[];
  downloadedTeachingIds: string[];
  recentlyPlayedIds: string[];
  notificationsEnabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

#### GET `/api/users/stats`

```ts
{
  totalUsers: number,
  usersWithFavorites: number,
  usersWithDownloads: number,
  totalFavorites: number,
  totalDownloads: number,
  notificationsEnabled: number,
  notificationsDisabled: number
}
```

#### GET `/api/users/:id`

#### POST `/api/users`

Upsert (crée ou met à jour selon que `id` existe).

```ts
// Body :
{
  id: string,              // Requis
  name: string,            // Requis
  email: string,           // Requis
  profileImageUrl?: string,
  favoriteTeachingIds?: string[],
  downloadedTeachingIds?: string[],
  recentlyPlayedIds?: string[],
  notificationsEnabled?: boolean
}
```

**Réponse** : `201` (création) ou `200` (mise à jour) — retourne l'objet User.

#### PUT `/api/users/:id`

Mise à jour partielle. Mêmes champs que POST (tous optionnels sauf ceux dans `params`).

#### DELETE `/api/users/:id`

#### DELETE `/api/users/all`

---

### 6. Textes Résumés (PDF)

Endpoints : `/api/text-resumes`

Collection Firestore : `textes_resumes`

#### GET `/api/text-resumes`

Paramètres de filtre optionnels en query string :
- `category` — filtre par catégorie
- `mois` — filtre par mois
- `annee` — filtre par année
- `typeCulte` — filtre par type de culte
- `sortBy` — `publishedAt` (défaut), `title`, `speaker`, `viewCount`
- `order` — `desc` (défaut) ou `asc`

```ts
interface TextResume {
  id: string;
  title: string;
  speaker: string;
  description: string;
  category: string;
  pdfUrl: string;           // URL Cloudinary
  coverImageUrl: string;    // URL Cloudinary
  tags: string[];
  viewCount: number;
  rating: number;
  isNew: boolean;
  isFeatured: boolean;
  publishedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  mois: string;
  annee: string;
  typeCulte: string;
  fileSize: number;         // bytes
  pageCount: number;
}
```

#### GET `/api/text-resumes/:id`

Incrémente automatiquement `viewCount`.

#### POST `/api/text-resumes`

**Content-Type** : `multipart/form-data`

| Champ | Type | Requis |
|---|---|---|
| `title` | string | Oui |
| `speaker` | string | Oui |
| `category` | string | Oui |
| `description` | string | Non |
| `tags` | string (séparés par `,`) | Non |
| `mois` | string | Non (défaut: mois actuel) |
| `annee` | string | Non (défaut: année actuelle) |
| `typeCulte` | string | Non |
| `pdf` | file (.pdf) | **Oui** (max 50MB) |
| `image` | file (.jpg/.png) | Non (cover) |

#### PUT `/api/text-resumes/:id`

**Content-Type** : `multipart/form-data`

Tous les champs optionnels. Peut remplacer `pdf` et/ou `image`.
Supprime les anciens fichiers Cloudinary correspondants.

#### DELETE `/api/text-resumes/:id`

Supprime le document + ses fichiers Cloudinary (PDF + cover).

#### DELETE `/api/text-resumes/all`

---

### 7. Notifications Push (FCM)

Endpoints : `/api/notifications`

#### POST `/api/notifications/tokens`

Enregistre un token FCM.

```ts
// Body : { userId: string, fcmToken: string }
// Response 200 : { message: "Token enregistré avec succès" }
```

#### DELETE `/api/notifications/tokens`

Supprime un token FCM.

```ts
// Body : { userId: string, fcmToken: string }
```

#### POST `/api/notifications/send/all`

```ts
// Body :
{
  title: string,
  body: string,
  data?: Record<string, string>,
  imageUrl?: string
}
// Response : { message, sent: number, failed: number, total: number }
```

#### POST `/api/notifications/send/user`

```ts
// Body :
{
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
  imageUrl?: string
}
```

#### POST `/api/notifications/send/topic`

```ts
// Body :
{
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>,
  imageUrl?: string
}
```

**Note** : Les notifications push sont envoyées automatiquement par le backend lors de la création d'un enseignement, d'une annonce, d'un événement calendrier, ou d'un texte résumé. Le frontend n'a pas besoin d'appeler manuellement ces endpoints pour les créations.

---

## Debug / Santé

#### GET `/`

```ts
{ message: "Serveur Enseignement API opérationnel 🚀" }
```

---

## Gestion des erreurs

Format standard des erreurs :

```ts
{
  error: string,       // Message d'erreur lisible
  details?: string     // Détail technique (en dev)
}
```

| Code | Cas |
|---|---|
| `400` | Champs requis manquants, fichier invalide |
| `404` | Ressource non trouvée |
| `500` | Erreur interne (Firestore, Cloudinary, etc.) |

Erreur Multer (upload trop volumineux) :
```ts
{ error: "Fichier trop volumineux" }   // 50MB max
```

---

## Upload fichiers — Règles

| Type | Field Name | Format | Taille max | Destination |
|---|---|---|---|---|
| Image cours | `image` | jpg/png | 50MB | Cloudinary `enseignements/images` |
| Audio cours | `audio` | mp3 | 50MB | Cloudinary `enseignements/audios` |
| PDF texte résumé | `pdf` | pdf | 50MB | Cloudinary `textes_resumes/pdfs` |
| Cover texte résumé | `image` | jpg/png | 50MB | Cloudinary `textes_resumes/covers` |

**Important** : Envoyer en `multipart/form-data` uniquement pour les endpoints qui acceptent des fichiers. Les autres endpoints utilisent du JSON standard (`application/json`).

---

## Patterns à suivre pour le frontend

1. **URL de base** : Utiliser `NEXT_PUBLIC_API_URL` (`http://localhost:3000/api` par défaut)
2. **Timeouts** : 30s pour les requêtes normales, prévoir plus long pour les uploads
3. **Erreurs réseau** : Le client actuel utilise `AbortController` — bien gérer les timeouts
4. **Format Dates** : Le backend renvoie les dates Firestore converties en objets Date JS ou ISO strings selon le contrôleur. Toujours normaliser avec `toISOString()` côté frontend si besoin.
5. **Upload** : Utiliser `FormData` avec `fetch` — NE PAS setter `Content-Type` manuellement (le navigateur le déduit avec le boundary)
6. **Multicast** : Les notifications `send/all` envoient à **tous** les tokens FCM enregistrés — attention aux volumes
