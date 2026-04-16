# Configuration Firebase pour les Push Notifications

## 📋 Prérequis

1. Un projet Firebase créé sur [Firebase Console](https://console.firebase.google.com/)
2. Firebase Cloud Messaging (FCM) activé dans votre projet
3. Les fichiers de configuration Firebase

## 🔧 Configuration Android

### 1. Télécharger `google-services.json`

1. Allez dans Firebase Console > Paramètres du projet
2. Dans l'onglet "Vos applications", cliquez sur l'icône Android
3. Ajoutez votre package name (ex: `com.mykog.app`)
4. Téléchargez le fichier `google-services.json`
5. Placez-le dans `android/app/google-services.json`

### 2. Configurer `build.gradle`

Ajoutez dans `android/build.gradle` (niveau projet) :

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Ajoutez dans `android/app/build.gradle` :

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

## 🍎 Configuration iOS

### 1. Télécharger `GoogleService-Info.plist`

1. Allez dans Firebase Console > Paramètres du projet
2. Dans l'onglet "Vos applications", cliquez sur l'icône iOS
3. Ajoutez votre Bundle ID
4. Téléchargez le fichier `GoogleService-Info.plist`
5. Placez-le dans `ios/Runner/GoogleService-Info.plist`

### 2. Configurer les capacités

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez le target "Runner"
3. Allez dans "Signing & Capabilities"
4. Ajoutez "Push Notifications"
5. Ajoutez "Background Modes" et cochez "Remote notifications"

### 3. Configurer les permissions

Dans `ios/Runner/Info.plist`, ajoutez :

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## ✅ Vérification

1. Lancez l'application
2. Vérifiez dans les logs que le token FCM est généré
3. Testez l'envoi d'une notification depuis le dashboard admin

## 📝 Notes importantes

- Les notifications fonctionnent uniquement sur des appareils physiques (pas sur les simulateurs iOS)
- Pour Android, les notifications fonctionnent aussi sur les émulateurs
- Assurez-vous que les permissions de notification sont accordées par l'utilisateur

