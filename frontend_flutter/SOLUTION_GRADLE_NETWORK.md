# 🔧 Solution : Erreur de téléchargement Gradle

## ❌ Problème

Gradle ne peut pas télécharger les dépendances depuis les dépôts Maven :
- `repo.maven.apache.org: Échec temporaire dans la résolution du nom`
- `dl.google.com: Le réseau n'est pas accessible`
- `Got socket exception during request`

## ✅ Solutions appliquées

### 1. Timeouts augmentés

Dans `android/gradle.properties`, j'ai ajouté :
```properties
systemProp.http.connectionTimeout=60000
systemProp.http.socketTimeout=60000
systemProp.https.connectionTimeout=60000
systemProp.https.socketTimeout=60000
```

### 2. Miroirs alternatifs

Dans `android/build.gradle.kts`, j'ai ajouté des miroirs :
- Aliyun Maven (Chine)
- JCenter
- Maven Central Alternative

### 3. Configuration optimisée

- Daemon activé
- Build parallèle
- Configure on demand

## 🧪 Tester la connexion

```bash
cd frontend_flutter
./test-gradle-connection.sh
```

## 🚀 Réessayer la compilation

```bash
cd frontend_flutter
flutter clean
flutter pub get
flutter run
```

## 🔄 Si le problème persiste

### Option 1 : Utiliser un proxy (si vous en avez un)

Ajoutez dans `android/gradle.properties` :
```properties
systemProp.http.proxyHost=proxy.example.com
systemProp.http.proxyPort=8080
systemProp.https.proxyHost=proxy.example.com
systemProp.https.proxyPort=8080
```

### Option 2 : Télécharger manuellement les dépendances

1. Identifier les dépendances manquantes dans l'erreur
2. Les télécharger manuellement depuis le navigateur
3. Les placer dans `~/.gradle/caches/modules-2/files-2.1/`

### Option 3 : Utiliser un VPN

Si vous êtes dans une région avec restrictions réseau, utilisez un VPN.

### Option 4 : Compiler hors ligne (si dépendances déjà téléchargées)

```bash
# Activer le mode hors ligne
echo "org.gradle.offline=true" >> android/gradle.properties
```

## 📝 Vérifications

1. ✅ Connexion internet active
2. ✅ DNS fonctionnel
3. ✅ Pas de firewall bloquant
4. ✅ Timeouts suffisants (60s)
5. ✅ Miroirs alternatifs configurés

## ⚠️ Note

Si votre connexion est très lente (latence > 1s), la compilation peut prendre beaucoup de temps. 
Laissez Gradle télécharger toutes les dépendances une première fois, puis les builds suivants seront plus rapides.

