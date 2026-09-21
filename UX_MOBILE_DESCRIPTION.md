# MyKOG — Description de l'UX Mobile

## Vue d'ensemble

**MyKOG** est une application mobile Flutter (Android/iOS) de streaming spirituel. Elle permet aux utilisateurs d'accéder à une bibliothèque d'enseignements audio, de suivre des cultes en direct (live streaming vidéo HLS), de consulter un calendrier d'événements, de lire des textes résumés (PDF) et de parcourir des livres. Le design s'inspire de Spotify (fond noir, accent doré) et Apple Music.

---

## 1. Architecture technique

| Élément          | Technologie                                     |
|------------------|--------------------------------------------------|
| Framework        | Flutter (SDK ^3.6.0)                             |
| Langage          | Dart                                             |
| State management | Provider (ChangeNotifier)                        |
| Audio            | just_audio + audio_service (background playback) |
| Vidéo live       | video_player + chewie (HLS), fallback VLC        |
| Stockage local   | Hive (NoSQL) + SharedPreferences                 |
| Réseau           | http, dio, cached_network_image                  |
| Push             | Firebase Cloud Messaging + local notifications   |
| PDF              | pdfx                                             |
| Responsive       | flutter_screenutil                               |
| Internationalisation | Système maison via AppLocalizations         |
| Thème            | Material 3, thème clair/sombre, Google Fonts     |

---

## 2. Flux de démarrage (Onboarding)

1. **Splash / Route Selector** — Au lancement, `InitialRouteSelector` vérifie si l'utilisateur a déjà vu l'onboarding et s'il est inscrit.
2. **Onboarding (3 pages)** — Diapositives animées présentant l'app : "Bienvenue sur MyKOG", "Enseignements", "Explore".
3. **Inscription** — Écran de création de compte (nom + téléphone avec sélecteur de pays/drapeau).
4. **Écran de chargement** — Animation avec logo MyKOG + phrases défilantes ("Conduire le peuple dans sa véritable repentance…") + barre de progression.

---

## 3. Navigation principale (Bottom Navigation Bar)

5 onglets accessibles depuis une barre de navigation en bas :

| # | Onglet    | Icône            | Description                                                    |
|---|-----------|------------------|----------------------------------------------------------------|
| 1 | **Accueil** | `home`          | Vue d'accueil personnalisée                                    |
| 2 | **Explorer**| `explore`       | Découverte de contenus                                         |
| 3 | **Live**    | `live_tv`      | Streaming en direct et programmé                               |
| 4 | **Bibliothèque** | `library_music` | Enseignements, téléchargements, textes résumés, livres |
| 5 | **Profil**  | `person`        | Profil utilisateur, paramètres, téléchargements                |

Un **mini-lecteur** (MiniPlayerImproved) est superposé en bas de l'écran, au-dessus de la barre de navigation, pour contrôler la lecture audio en cours.

Des **badges** (points verts) signalent les nouveaux contenus (enseignements récents, événements calendrier).

---

## 4. Écrans détaillés

### 4.1 Accueil (`HomeScreen`)
- **Section Hero** : Salutation personnalisée (Bonjour/Après-midi/Soir) + nom de l'utilisateur + icône calendrier avec badge.
- **Icône calendrier** → ouvre le `CalendarScreen`.
- **Verset du jour** : Carte GlassCard avec citation spirituelle.
- **Récemment écouté** : Carrousel horizontal des 5 derniers enseignements.
- **Mes Favoris** : Section portfolio avec dossiers de favoris (FavoritePackage).
- **Populaires** : Liste verticale d'enseignements populaires avec animations.
- **Mode hors ligne** : Si pas de connexion, filtre uniquement les contenus téléchargés.

### 4.2 Explorer (`BrowseScreen`)
- **Header** : Texte "Découvrir" + sous-titre.
- **Carrousel d'images** : Bannière publicitaire/promotionnelle Cloudinary.
- **Pour Vous** : Liste horizontale d'enseignements recommandés (cartes avec artwork, compteur de lectures).
- **Populaires cette semaine** : Liste horizontale d'enseignements populaires.
- **Catégories** : Grille 2 colonnes de catégories cliquables (Foi, Prière, Amour, Joie, etc.) avec icônes colorées.
- **Lecture directe** : Appuyer sur une carte lance la lecture audio immédiatement.

### 4.3 En Direct (`LiveScreen`)
- **2 onglets** : "En direct" et "Programmé".
- **Live actif** : Carte mise en avant avec badge rouge "LIVE MAINTENANT" animé, compteur de viewers, bouton "Regarder maintenant".
- **Streams en cours** : Cartes avec thumbnail, titre, pasteur, description, compteur de vues.
- **Streams programmés** : Cartes avec info de temps restant (In 2 days, Starting soon, etc.) et bouton notification.
- **Auto-polling** : Vérifie un live actif toutes les 10 secondes.
- **Lecture live** : Ouvre `LivePlayerScreen` avec lecteur vidéo HLS (Chewie + video_player).

### 4.4 Bibliothèque / Enseignements (`TeachingsScreen`)
- **6 onglets** : Tous, Culte d'Impact, Culte Prophétique, Culte d'Enseignement, Téléchargés, Textes Résumés.
- **Barre de recherche** : Recherche par titre, orateur, catégorie, mois, année, description.
- **Filtres horizontal** : Par année et par mois (pills sélectionnables).
- **Liste d'enseignements** : `ModernTeachingTile` avec artwork, titre, orateur, durée, indicateurs "Nouveau"/"À la une".
- **Bouton Livres** : Ouvre `BooksScreen`.
- **Bouton refresh** : Réinitialise le cache et recharge depuis le backend.
- **Bannière hors ligne** : S'affiche quand la connexion est perdue.

### 4.5 Profil (`ProfileScreen`)
- **Photo de profil** : Avatar circulaire avec gradient doré + bouton d'édition.
- **Infos utilisateur** : Nom, email, date d'inscription.
- **Statistiques** : 3 cartes (Favoris, Téléchargés, Récemment écoutés).
- **Paramètres** :
  - Gérer les téléchargements
  - Enseignements favoris
  - Langue (sélecteur avec drapeaux)
  - Mode sombre (switch)
  - Notifications (switch)
  - À propos
  - Déconnexion
- **Configuration réseau** : `ConnectionModeSelector` pour voir/tester la connexion au backend.

### 4.6 Lecture audio (`AudioPlayerScreen`)
- **Header** : Flèche retour + "Now Playing" + icône file d'attente.
- **Album Art** : Grande image circulaire avec ombre dorée.
- **Infos** : Titre, orateur, boutons favoris (❤️) et partage.
- **Barre de progression** : Slider doré avec temps écoulé / temps total.
- **Contrôles** : Shuffle, Recul 10s, Précédent, Play/Pause, Suivant, Avance 10s, Repeat.
- **File d'attente** : Bottom sheet avec liste "Up Next", possibilité de supprimer, réorganiser ou vider la file.
- **Persistance** : L'état audio (morceau en cours, position, file d'attente) est sauvegardé dans Hive et restauré au démarrage (Spotify-like resume).

### 4.7 Lecteur Live (`LivePlayerScreen`)
- **Lecteur vidéo** : Utilise `video_player` + `Chewie` pour le streaming HLS.
- **Fallback VLC** : `flutter_vlc_player` disponible pour les appareils MediaTek (désactivé par défaut).
- **Badge LIVE** : Rouge avec animation clignotante.
- **Compteur de viewers** : Temps réel, mis à jour toutes les 5 secondes.
- **Overlay** : Titre, pasteur, description en bas. Bouton retour et compteur en haut.
- **Gestion d'erreurs** : Messages explicites selon le type d'erreur (Timeout, 404, codec).
- **Join/Leave live** : API appelée pour rejoindre/quitter le live (compteur de viewers).

### 4.8 Calendrier (`CalendarScreen`)
- **Navigation mensuelle** : Mois précédent/suivant + bouton "Aujourd'hui".
- **Grille calendrier** : Jours numérotés avec points de couleur pour les événements.
- **Événements du jour** : Liste des événements pour la date sélectionnée.
- **Événements du mois** : Tous les événements du mois en cours.
- **Détails** : Bottom sheet avec infos (titre, description, date, lieu, catégorie).
- **Actions admin** : Ajout/Modification/Suppression d'événements.
- **Alarmes** : Synchronisation automatique des alarmes pour les événements à venir.

### 4.9 Textes Résumés (`TextResumesScreen`)
- **3 modes d'affichage** : Grille, Cartes, Liste (avec boutons de bascule).
- **Filtres** : Catégorie, Année, Mois, Type de culte (pills déroulantes).
- **Tri** : Plus récent, Plus ancien, Titre (A-Z), Orateur (A-Z), Plus consulté.
- **Recherche** : Par titre, orateur, catégorie, description.
- **Visiteur PDF** : `TextResumeViewerScreen` avec `pdfx` pour lire les résumés en PDF.

### 4.10 Livres (`BooksScreen`)
- **2 modes d'affichage** : Grille (cartes) et Liste.
- **Recherche** : Par titre, auteur, catégorie.
- **Cartes livre** : Icône livre, titre, auteur, taille du fichier, nombre de pages.
- **Action** : Copie le lien PDF dans le presse-papiers.

### 4.11 Gestion des téléchargements (`DownloadsManagementScreen`)
- **Statistiques** : Carte avec espace utilisé, nombre d'enseignements et fichiers.
- **Informations** : Téléchargements actifs, enseignements téléchargés, espace de stockage.
- **Actions** : Actualiser les stats, Supprimer tous les téléchargements (avec confirmation).

### 4.12 Sélection des favoris (`FavoriteSelectionScreen`)
- **Sélection multiple** : Checkbox circulaire pour chaque enseignement.
- **Recherche** : Filtrer les enseignements.
- **Sélection tout/déselectionner tout**.
- **Création de package** : Nommer le groupe de favoris (ex: "Mes enseignements préférés").
- **Badge "déjà favori"** : Indique si l'enseignement est déjà dans les favoris.

### 4.13 Langue (`LanguageSelectionScreen`)
- **4 langues** : Français, Anglais, Allemand, Espagnol.
- **Affichage** : Drapeau + nom natif + nom anglais.
- **Changement** : Dialogue de chargement + SnackBar de confirmation.

---

## 5. Fonctionnalités transverses

### 5.1 Audio
- **Background playback** : via `just_audio_background` + `audio_service` (notification Android persistante).
- **Persistance Spotify-like** : Sauvegarde dans Hive de l'état audio (morceau, position, file d'attente).
- **Contrôle de vitesse** : Non implémenté dans l'UI mais le provider supporte.
- **Queue / Shuffle / Repeat** : File d'attente, mode aléatoire, répétition (off/one/all).

### 5.2 Gestion de la connectivité
- Détection temps réel de la connexion via `connectivity_plus`.
- Mode hors ligne : Affiche uniquement les contenus téléchargés.
- Bannières d'avertissement orange dans les vues concernées.
- Fallback automatique vers les données locales si l'API est inaccessible.

### 5.3 Notifications Push
- Firebase Cloud Messaging (FCM).
- Notifications locales pour les alarmes d'événements.
- Badges pour nouveaux contenus via `BadgeService`.

### 5.4 Internationalisation (i18n)
- 4 langues : Français, Anglais, Allemand, Espagnol.
- Système maison basé sur `AppLocalizations` avec `LocalizationsDelegate`.

### 5.5 Thème
- **Sombre (défaut)** : Fond noir (#000000), accent doré (#d4af37), texte blanc.
- **Clair** : Fond blanc, accent doré, texte noir.
- Police : Poppins (titres) + Inter (corps) via Google Fonts.

### 5.6 Responsive Design
- `flutter_screenutil` pour le dimensionnement proportionnel (w/h/sp).
- Composants responsives : `ResponsiveWrapper`, `ResponsiveSpacing`, `ResponsiveButton`.

---

## 6. Modèles de données

- **Teaching** : id, title, speaker, description, category, duration, audioUrl, artworkUrl, tags, playCount, isNew, isFeatured, publishedAt, mois, annee, typeCulte.
- **MyKOGUser** : id, name, email, profileImageUrl, createdAt, favoriteTeachingIds, downloadedTeachingIds, recentlyPlayedIds.
- **FavoritePackage** : id, name, teachingIds, createdAt.
- **LiveStream** : id, title, description, streamUrl, thumbnailUrl, pastor, viewerCount, scheduledAt.
- **CalendarEvent** : id, title, description, startDate, endDate, location, category, color, hasAlarm, isAllDay.
- **TextResume** : id, title, speaker, description, pdfUrl, coverImageUrl, viewCount, category, mois, annee, typeCulte, fileSize, fileSizeText.
- **Book** : id, title, author, pdfUrl, fileSize, pageCount, category.

---

## 7. Services et API

| Service                  | Rôle                                      |
|--------------------------|-------------------------------------------|
| `AudioService`           | Moteur audio (just_audio + rxdart streams)|
| `AudioHandler`           | Handler audio_service (background)        |
| `AudioNotificationService`| Notifications de lecture audio           |
| `TeachingService`        | CRUD enseignements + cache local          |
| `TeachingApiService`     | API REST enseignements                    |
| `LiveStreamService`      | Récupération des streams live             |
| `LiveApiService`         | API REST live (join/leave/viewer count)   |
| `CalendarService`        | CRUD événements calendrier                |
| `CalendarApiService`     | API REST calendrier                       |
| `BookService`            | Récupération des livres                   |
| `TextResumeApiService`   | API REST textes résumés                   |
| `UserService`            | Gestion utilisateur local                 |
| `UserApiService`         | API REST utilisateur                      |
| `DownloadService`        | Téléchargement et stockage local fichiers |
| `FileStorageService`     | Gestion fichiers (taille, stats)          |
| `HiveStorageService`     | Persistance NoSQL locale (Hive)           |
| `StorageService`         | Persistance simple (SharedPreferences)    |
| `ConnectivityService`    | Détection connexion réseau                |
| `NotificationService`    | Firebase Cloud Messaging                  |
| `BadgeService`           | Gestion des badges de nouveaux contenus   |
| `AlarmService`           | Alarmes pour événements calendrier        |
| `FirstLaunchService`     | Gestion du premier lancement              |
| `NavigationService`      | Service de navigation global              |

---

## 8. Package de favoris

Système unique de **dossiers de favoris** (FavoritePackage) permettant de regrouper plusieurs enseignements dans un package nommé (ex: "Enseignements sur la foi"). Ces packages sont affichés sur l'écran d'accueil sous forme de cartes portfolio.

---

## 9. Dépendances principales

```yaml
provider: # State management
just_audio + just_audio_background + audio_service: # Audio
video_player + chewie + flutter_vlc_player: # Vidéo HLS
firebase_core + firebase_messaging: # Push notifications
hive + hive_flutter: # Stockage local NoSQL
pdfx: # Lecteur PDF
cached_network_image: # Images avec cache
flutter_screenutil: # Design responsive
flutter_animate: # Animations fluides
google_fonts: # Typographie (Poppins + Inter)
connectivity_plus: # Détection réseau
dio + http: # Requêtes HTTP
```
