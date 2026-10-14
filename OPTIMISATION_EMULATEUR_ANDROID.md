# Guide d'Optimisation de l'Émulateur Android

## 🚀 Optimisation pour que l'émulateur ne rame plus

### 1. Vérifier la Virtualisation Matérielle

**VT-x / AMD-V (Intel/AMD)**
- Ouvrez le Gestionnaire des tâches → Onglet Performances
- Vérifiez que "Virtualisation" est activée
- Si désactivé: Redémarrez et activez-la dans le BIOS

**HAXM (Hardware Accelerated Execution Manager)**
- Ouvrez Android Studio
- File → Settings → Appearance & Behavior → System Settings → Android SDK
- Onglet "SDK Tools"
- Cochez "Intel x86 Emulator Accelerator (HAXM installer)"
- Cliquez sur Apply et installez

### 2. Configurer l'AVD (Émulateur)

**Créer un émulateur optimisé:**
- Device Manager → Create Virtual Device
- Choisissez un appareil (Pixel 5 ou Pixel 6 recommandé)
- Image système: Choisissez une image avec Play Store
- **IMPORTANT:** Sélectionnez une image **x86_64** (pas ARM)
- Version: Android 10, 11, 12 ou 13 (selon vos besoins)

**Configuration AVD avancée:**
1. Cliquez sur "Show Advanced Settings"
2. Configurez les paramètres suivants:

**RAM:**
- Minimum: 2048 MB
- Recommandé: 4096 MB (4 GB)
- Maximum: 6144 MB (6 GB) si vous avez 16 GB+ de RAM

**VM Heap:**
- 256 MB (suffisant pour la plupart des apps)

**Internal Storage:**
- 2000 MB (2 GB) minimum
- 4000 MB (4 GB) recommandé

**SD Card:**
- Optionnel, 1024 MB (1 GB) si nécessaire

**Graphics:**
- Sélectionnez **"Hardware - GLES 2.0"** ou **"Hardware - GLES 1.1"**
- Si vous avez carte graphique dédiée: Choisissez "Hardware - GLES 2.0"

**Boot Option:**
- Cochez "Cold Boot" uniquement si nécessaire (plus lent)
- Décochez pour démarrage rapide

**Network:**
- Wi-Fi: Activé

**Chromium:**
- WebGL: Activé (si votre app utilise WebGL)

### 3. Optimisations Logicielles

**Activer HAXM/Windows Hypervisor Platform:**
- Si vous utilisez Windows 10/11 avec WSL2:
  - Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK
  - SDK Tools → Cochez "Windows Hypervisor Platform"
  - Désinstallez HAXM s'il est installé

**Utiliser l'accélération GPU:**
- Assurez-vous que vos pilotes graphiques sont à jour
- NVIDIA/AMD: Installez les derniers pilotes

### 4. Désactiver les Animations (Optionnel)

Dans l'émulateur:
- Settings → Developer Options
- Désactivez:
  - Window animation scale
  - Transition animation scale
  - Animator duration scale

### 5. Utiliser des Snapshots

**Créer un snapshot:**
- Émulateur en cours d'exécution
- Cliquez sur l'icône d'appareil photo (⋮) → Save VM snapshot
- Nommez-le "clean_boot" ou similaire

**Charger un snapshot:**
- Device Manager → ⋮ sur l'AVD → Load snapshot
- Sélectionnez votre snapshot
- Démarrage instantané!

### 6. Options de Lancement

**Lancer avec accélération:**
```bash
# Dans Android Studio Terminal
flutter run --enable-software-rendering  # Si problèmes GPU
flutter run --verbose  # Pour voir les problèmes
```

**Lancer avec options spécifiques:**
```bash
# Si plusieurs émulateurs
flutter devices
flutter run -d <device_id>
```

### 7. Configurer Gradle (Pour Flutter)

**gradle.properties** (android/gradle.properties):
```properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
```

### 8. Désactiver les Services Inutiles

Dans l'émulateur:
- Settings → Apps
- Désactivez/arrêtez les apps que vous n'utilisez pas
- Désactivez Google Play Services si pas nécessaire

### 9. Vérifier les Performances

**Commandes utiles:**
```bash
# Vérifier l'état de l'émulateur
adb shell top

# Vérifier la mémoire
adb shell dumpsys meminfo

# Vérifier le GPU
adb shell dumpsys gfxinfo
```

### 10. Dépannage

**Si l'émulateur est toujours lent:**
1. Vérifiez que VT-x/AMD-V est activé dans le BIOS
2. Désactivez les antivirus temporairement
3. Fermez les autres applications gourmandes en RAM
4. Utilisez une image système plus légère (Android 10 au lieu de 13)
5. Réduisez la RAM de l'émulateur à 2048 MB

**Erreurs HAXM:**
- Vérifiez que Windows Defender ou autre antivirus ne bloque pas
- Réinstallez HAXM via SDK Manager

**Erreurs de démarrage:**
- "Cold boot" l'émulateur une fois
- Ensuite utilisez les snapshots

### 11. Alternative: Utiliser un Vrai Appareil

Si l'émulateur reste trop lent:
- Activez le mode développeur sur votre téléphone
- Activez le "USB Debugging"
- Connectez-le via USB
- `flutter devices` pour voir votre appareil
- `flutter run -d <device_id>`

## 📝 Résumé des Paramètres Optimaux

| Paramètre | Valeur Recommandée |
|-----------|-------------------|
| RAM | 4096 MB (4 GB) |
| VM Heap | 256 MB |
| Storage | 4000 MB (4 GB) |
| Graphics | Hardware - GLES 2.0 |
| Image System | x86_64 (pas ARM) |
| CPU Cores | 2-4 cores (auto) |
| Snapshots | Oui (activé) |

## 🔗 Liens Utiles

- [Android Emulator Performance](https://developer.android.com/studio/run/emulator-acceleration)
- [Flutter Performance](https://flutter.dev/docs/perf/rendering/best-practices)
