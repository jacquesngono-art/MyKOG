# Guide de Connexion USB et WiFi

Ce guide explique comment configurer l'application pour fonctionner avec un câble USB ou via WiFi.

## 🔌 Connexion USB (Câble)

### Avantages
- Connexion stable et rapide
- Pas besoin de réseau WiFi
- Débogage plus facile

### Configuration

1. **Connecter le téléphone via USB**
   ```bash
   # Vérifier que l'appareil est détecté
   adb devices
   ```

2. **Configurer le port forwarding**
   ```bash
   # Depuis le dossier frontend_flutter
   ./setup-usb-connection.sh
   ```
   
   Ou manuellement :
   ```bash
   adb reverse tcp:3000 tcp:3000
   ```

3. **Vérifier la configuration**
   ```bash
   adb reverse --list
   ```
   Vous devriez voir : `tcp:3000 tcp:3000`

4. **Lancer l'application**
   ```bash
   flutter run
   ```

L'application détectera automatiquement le mode USB et utilisera `localhost:3000` pour se connecter au backend.

### Désactiver le port forwarding
```bash
adb reverse --remove tcp:3000
```

## 📶 Connexion WiFi

### Avantages
- Pas besoin de câble
- Plusieurs appareils peuvent se connecter
- Test sur plusieurs téléphones simultanément

### Configuration

1. **S'assurer que le téléphone et l'ordinateur sont sur le même réseau WiFi**

2. **Trouver l'IP de l'ordinateur**
   ```bash
   # Linux
   ip addr show | grep "inet " | grep -v 127.0.0.1
   
   # Ou
   hostname -I
   ```

3. **L'application détectera automatiquement l'IP WiFi**

   Si l'IP n'est pas détectée automatiquement, vous pouvez la définir manuellement dans l'application ou via le code :
   ```dart
   await ApiConfig.setIP('192.168.100.6', mode: ApiConfig.modeWifi);
   ```

4. **Vérifier que le backend est accessible**
   ```bash
   # Depuis le téléphone ou un autre appareil sur le même réseau
   curl http://192.168.100.6:3000/api/enseignements
   ```

## 🔄 Basculer entre USB et WiFi

L'application détecte automatiquement le mode de connexion :

- **USB** : Si `localhost:3000` est accessible (avec `adb reverse`)
- **WiFi** : Sinon, utilise l'IP du réseau local

### Forcer un mode spécifique

```dart
// Forcer le mode USB
await ApiConfig.setConnectionMode(ApiConfig.modeUsb);
await ApiConfig.setIP('localhost', mode: ApiConfig.modeUsb);

// Forcer le mode WiFi
await ApiConfig.setConnectionMode(ApiConfig.modeWifi);
await ApiConfig.setIP('192.168.100.6', mode: ApiConfig.modeWifi);
```

### Réinitialiser la configuration

```dart
// Réinitialiser et détecter automatiquement
await ApiConfig.forceReset();
```

## 🐛 Dépannage

### Problème : "Connection closed before full header was received"

**Cause** : Le mode de connexion n'est pas correctement configuré.

**Solution USB** :
1. Vérifier que `adb reverse` est configuré :
   ```bash
   adb reverse --list
   ```
2. Si vide, exécuter :
   ```bash
   ./setup-usb-connection.sh
   ```

**Solution WiFi** :
1. Vérifier que le téléphone et l'ordinateur sont sur le même réseau
2. Vérifier que le firewall n'bloque pas le port 3000 :
   ```bash
   sudo ufw allow 3000
   ```
3. Vérifier que le backend écoute sur toutes les interfaces :
   ```bash
   # Le backend doit écouter sur 0.0.0.0:3000, pas seulement localhost
   ```

### Problème : L'application utilise toujours la mauvaise IP

**Solution** :
```dart
// Réinitialiser complètement
await ApiConfig.forceReset();
```

### Problème : localhost ne fonctionne pas en USB

**Vérifications** :
1. `adb devices` doit montrer votre appareil
2. `adb reverse tcp:3000 tcp:3000` doit être exécuté
3. Le backend doit être démarré sur le port 3000
4. Tester depuis le téléphone :
   ```bash
   adb shell
   curl http://localhost:3000/api/enseignements
   ```

## 📝 Notes

- Le mode est sauvegardé dans les préférences de l'application
- La détection automatique se fait au démarrage de l'application
- Vous pouvez basculer entre USB et WiFi sans redémarrer l'application (après configuration)

