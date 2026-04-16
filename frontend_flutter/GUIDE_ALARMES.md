# 🔔 Guide des Alarmes - Calendrier MyKOG

## ✅ Corrections apportées

### 1. Synchronisation automatique des alarmes
- Les alarmes sont maintenant synchronisées automatiquement lors du chargement des événements dans l'écran calendrier
- Les alarmes sont synchronisées au démarrage de l'application
- Les alarmes sont planifiées immédiatement après la création d'un événement

### 2. Configuration du son d'alarme
- Utilisation du son d'alarme par défaut du système Android
- Canal de notification configuré avec `Importance.max` pour une sonnerie audible
- Vibration activée

### 3. Permissions Android
- Ajout des permissions `SCHEDULE_EXACT_ALARM` et `USE_EXACT_ALARM` pour les alarmes précises
- Permission `POST_NOTIFICATIONS` pour Android 13+

## 📋 Comment tester les alarmes

### Étape 1 : Créer un événement avec alarme depuis le dashboard admin

1. Connectez-vous au dashboard admin
2. Allez dans "Calendrier"
3. Créez un nouvel événement
4. Activez l'alarme
5. Configurez le moment de déclenchement (ex: 0 jours, 0 heures, 1 minute avant)
6. Sauvegardez l'événement

### Étape 2 : Synchroniser les alarmes dans l'application mobile

**Option A : Ouvrir l'écran calendrier**
- Ouvrez l'application mobile
- Allez dans l'écran "Calendrier" (icône calendrier dans le header de l'écran d'accueil)
- Les alarmes seront automatiquement synchronisées

**Option B : Redémarrer l'application**
- Fermez complètement l'application
- Relancez l'application
- Les alarmes seront synchronisées au démarrage

### Étape 3 : Vérifier les logs

Dans les logs de l'application (via `flutter run` ou Android Studio), vous devriez voir :
```
🔔 Planification alarme:
   - Événement: [Nom de l'événement]
   - Date événement: [Date]
   - Date déclenchement calculée: [Date]
   - Maintenant: [Date actuelle]
   - Différence: [X] minutes
✅ Alarme planifiée avec succès pour [Nom] à [Date]
```

## 🔍 Dépannage

### L'alarme ne se déclenche pas

1. **Vérifier que l'alarme est planifiée**
   - Regardez les logs de l'application
   - Vérifiez que vous voyez "✅ Alarme planifiée avec succès"

2. **Vérifier la date de déclenchement**
   - L'alarme doit être dans le futur
   - Vérifiez les logs pour voir la date de déclenchement calculée

3. **Vérifier les permissions**
   - Allez dans Paramètres Android > Applications > MyKOG > Notifications
   - Assurez-vous que les notifications sont activées
   - Pour Android 12+, vérifiez que "Alarmes exactes" est activé

4. **Tester avec une alarme proche**
   - Créez un événement qui commence dans 1-2 minutes
   - Configurez l'alarme pour 1 minute avant
   - L'alarme devrait se déclencher dans 1 minute

5. **Vérifier le fuseau horaire**
   - Le fuseau horaire est actuellement configuré sur "Europe/Paris"
   - Si vous êtes dans un autre fuseau horaire, modifiez `alarm_service.dart` ligne 112

### L'alarme se déclenche mais sans son

1. **Vérifier le volume**
   - Assurez-vous que le volume de l'appareil n'est pas en mode silencieux
   - Vérifiez le volume des notifications dans les paramètres Android

2. **Vérifier le canal de notification**
   - Allez dans Paramètres Android > Applications > MyKOG > Notifications
   - Vérifiez que le canal "MyKOG Alarmes" est activé
   - Vérifiez que le son est activé pour ce canal

3. **Vérifier le mode "Ne pas déranger"**
   - Désactivez le mode "Ne pas déranger" si activé
   - Certains modes peuvent bloquer les alarmes

## 📝 Notes importantes

- Les alarmes fonctionnent même si l'application est en arrière-plan
- Les alarmes fonctionnent même si l'appareil est en veille (avec les permissions appropriées)
- Les alarmes sont annulées automatiquement si l'événement est supprimé
- Les alarmes sont mises à jour automatiquement si l'événement est modifié

## 🔧 Configuration avancée

### Changer le fuseau horaire

Dans `lib/services/alarm_service.dart`, ligne 112 :
```dart
final location = tz.getLocation('Europe/Paris'); // Changez ici
```

### Changer le son d'alarme

Pour utiliser un son personnalisé :
1. Placez votre fichier audio dans `android/app/src/main/res/raw/`
2. Modifiez `alarm_service.dart` ligne 52 et 108 :
```dart
sound: RawResourceAndroidNotificationSound('nom_de_votre_fichier'),
```

