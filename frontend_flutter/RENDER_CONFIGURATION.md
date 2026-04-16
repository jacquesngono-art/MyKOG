# Configuration Backend Render pour MyKOG Flutter

## 🎯 Objectif

Configurer votre application Flutter pour utiliser le backend hébergé sur Render : `https://mykog-backend-api.onrender.com`

## 🔄 Changements apportés

### 1. **Configuration API automatique**
- **Priorité absolue** au backend Render
- **Détection automatique** du mode de connexion
- **Basculement intelligent** entre Render et local

### 2. **Modes de connexion disponibles**

| Mode | Description | Priorité |
|------|-------------|----------|
| **Render** | Backend hébergé sur Render | ⭐⭐⭐ (Max) |
| **USB** | Connexion locale via câble USB | ⭐⭐ |
| **WiFi** | Même réseau WiFi que le serveur | ⭐ |

### 3. **Détection automatique**

L'application suit cet ordre de priorité :

1. **Render** - Test si le backend en ligne est accessible
2. **USB** - Test localhost (adb reverse)
3. **WiFi** - Détection IP locale automatique

## 🚀 Utilisation

### Mode automatique (recommandé)

L'application détecte automatiquement le meilleur mode :

```dart
// L'application utilise automatiquement Render si disponible
final baseUrl = await ApiConfig.getBaseUrl();
// Résultat : https://mykog-backend-api.onrender.com
```

### Mode manuel

#### Forcer Render :
```dart
await ApiConfig.setConnectionMode(ApiConfig.modeRender);
```

#### Forcer Local (USB/WiFi) :
```dart
await ApiConfig.setConnectionMode(ApiConfig.modeUsb);
await ApiConfig.setConnectionMode(ApiConfig.modeWifi);
```

## 📱 Interface utilisateur

### 1. **Widget d'état de connexion**

```dart
// Affiche l'état de connexion en temps réel
ConnectionStatusWidget(showDetails: true)
```

### 2. **Widget compact**

```dart
// Version compacte pour la barre d'état
CompactConnectionStatusWidget()
```

### 3. **Écran de paramètres**

```dart
// Écran complet de configuration
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ConnectionSettingsScreen()),
);
```

## 🔧 Configuration détaillée

### Comportement par défaut

- **Mode Release/Web** : Toujours utilise Render
- **Mode Debug** : Détection automatique
- **Priorité** : Render > USB > WiFi

### Tests de connexion

```dart
// Tester Render
final renderWorks = await ApiConfig.testRenderConnection();

// Tester local
final localWorks = await ApiConfig.testConnection(ip: 'localhost');
```

### Informations de connexion

```dart
final info = await ApiConfig.getConnectionInfo();
print('Mode: ${info['mode']}');
print('IP: ${info['ip']}');
print('URL: ${info['baseUrl']}');
print('Connecté: ${info['isConnected']}');
```

## 🌐 URL de l'API

### Backend Render
```
https://mykog-backend-api.onrender.com
```

### Endpoints disponibles
- `GET /api/enseignements`
- `GET /api/annonces`
- `GET /api/lives`
- `GET /api/calendar`
- `GET /api/users`
- `GET /api/notifications`
- `GET /api/text-resumes`

## 📋 Étapes de déploiement

### 1. **Mettre à jour le code**
Les fichiers ont déjà été modifiés pour supporter Render.

### 2. **Tester localement**
```bash
flutter run
# L'application devrait automatiquement détecter Render
```

### 3. **Vérifier les logs**
```dart
// Logs que vous devriez voir
🔍 Détection automatique du mode de connexion...
☁️ Test du mode Render...
✅ Mode Render détecté et configuré: mykog-backend-api.onrender.com
🌐 URL API: https://mykog-backend-api.onrender.com
```

### 4. **Déployer en production**
```bash
flutter build apk --release
# L'application utilisera automatiquement Render
```

## 🛠️ Dépannage

### Problème : L'application utilise toujours le serveur local

**Solution** :
1. Vérifiez que Render est accessible : `curl https://mykog-backend-api.onrender.com/api/enseignements`
2. Réinitialisez la configuration : `ApiConfig.forceReset()`
3. Forcer le mode Render : `ApiConfig.setConnectionMode(ApiConfig.modeRender)`

### Problème : Timeout de connexion Render

**Causes possibles** :
- Backend en veille (cold start)
- Problèmes réseau
- Maintenance Render

**Solutions** :
- Attendre 30-60s (cold start Render)
- Vérifier la connexion internet
- Utiliser le mode local temporairement

### Problème : L'application ne détecte pas Render

**Solution manuelle** :
```dart
// Forcer Render dans le code
await ApiConfig.setIP('mykog-backend-api.onrender.com', mode: ApiConfig.modeRender);
```

## 🔄 Basculement entre modes

### Depuis l'interface
1. Allez dans **Paramètres de Connexion**
2. Sélectionnez **Backend Render (Recommandé)**
3. L'application redémarrera avec la nouvelle configuration

### Depuis le code
```dart
// Basculer vers Render
await ApiConfig.setConnectionMode(ApiConfig.modeRender);

// Basculer vers local
await ApiConfig.setConnectionMode(ApiConfig.modeUsb);
```

## 📊 Monitoring

### Logs de connexion
L'application affiche des logs détaillés :
- `☁️ Mode Render détecté`
- `🔌 Mode USB détecté`
- `📶 Mode WiFi détecté`
- `✅ Connexion réussie`
- `❌ Connexion échouée`

### Widget d'état
- 🟢 **Vert** : Connecté à Render
- 🔴 **Rouge** : Hors ligne
- 🟡 **Orange** : Mode local

## 🎯 Avantages du mode Render

- ✅ **Disponible 24/7** (avec veilleur automatique)
- ✅ **Pas besoin de serveur local**
- ✅ **Accessible de partout**
- ✅ **HTTPS sécurisé**
- ✅ **Mises à jour automatiques**

## 📝 Notes importantes

1. **Le veilleur** sur Render empêche le sleep de 15 minutes
2. **Le mode local** reste disponible pour le développement
3. **L'application bascule** automatiquement si Render est indisponible
4. **Les données** sont synchronisées entre tous les modes

## 🚀 Prochaines étapes

1. ✅ Tester la connexion Render
2. ✅ Vérifier tous les endpoints
3. ✅ Déployer en production
4. 🔄 Monitorer les performances
5. 📱 Optimiser l'expérience utilisateur
