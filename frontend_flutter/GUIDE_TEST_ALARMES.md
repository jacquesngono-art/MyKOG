# 🔔 Guide de Test des Alarmes

## ✅ Modifications Apportées

### 1. Configuration du Son d'Alarme
- **Son système Android** : Utilisation de `content://settings/system/alarm_alert` pour utiliser le son d'alarme système de l'appareil
- **Catégorie alarme** : Configuration avec `AndroidNotificationCategory.alarm` pour que Android traite l'alarme comme une vraie alarme
- **Importance maximale** : `Importance.max` pour garantir que l'alarme sonne même en mode silencieux

### 2. Affichage Plein Écran
- **Full Screen Intent** : Activé pour afficher l'alarme même si l'écran est verrouillé (Android 10+)
- **Permission ajoutée** : `USE_FULL_SCREEN_INTENT` dans le manifest Android

### 3. Comportement de l'Alarme
- **Ongoing** : L'alarme continue jusqu'à ce que l'utilisateur l'arrête
- **Auto-cancel désactivé** : L'alarme ne se ferme pas automatiquement
- **Vibration activée** : L'appareil vibre en même temps que la sonnerie
- **LED activée** : La LED de l'appareil clignote en rouge

## 🧪 Comment Tester

### Test 1 : Alarme dans 1 minute
1. Créez un événement dans le calendrier avec :
   - **Date** : Dans 1 minute
   - **Alarme activée** : Oui
   - **Minutes avant** : 0 (ou 1 pour tester immédiatement)

2. Attendez que l'alarme se déclenche

3. **Comportement attendu** :
   - ✅ Sonnerie d'alarme système audible
   - ✅ Notification plein écran (même si l'écran est verrouillé)
   - ✅ Vibration
   - ✅ LED clignotante (si disponible)

### Test 2 : Alarme avec écran verrouillé
1. Verrouillez l'écran de votre appareil
2. Créez un événement avec alarme dans 1 minute
3. Attendez que l'alarme se déclenche

4. **Comportement attendu** :
   - ✅ L'alarme s'affiche en plein écran même si l'écran est verrouillé
   - ✅ Sonnerie audible

## ⚠️ Notes Importantes

### Permissions Android
- **Android 10+** : La permission `USE_FULL_SCREEN_INTENT` est requise pour afficher les alarmes en plein écran
- **Android 12+** : Les permissions `SCHEDULE_EXACT_ALARM` et `USE_EXACT_ALARM` sont requises pour les alarmes précises

### Son d'Alarme
- Le son utilisé est le **son d'alarme système** configuré dans les paramètres Android de l'appareil
- Si aucun son d'alarme n'est configuré dans les paramètres système, Android utilisera le son par défaut
- Pour changer le son, l'utilisateur doit modifier le son d'alarme dans les paramètres système Android

### Mode Silencieux
- Avec `Importance.max`, l'alarme devrait sonner même si l'appareil est en mode silencieux
- Cependant, certains appareils peuvent avoir des restrictions supplémentaires

## 🔧 Dépannage

### L'alarme ne sonne pas
1. Vérifiez que les permissions sont accordées :
   - `SCHEDULE_EXACT_ALARM`
   - `USE_EXACT_ALARM`
   - `USE_FULL_SCREEN_INTENT` (Android 10+)

2. Vérifiez que le son d'alarme système est activé dans les paramètres Android

3. Vérifiez les logs Flutter pour voir si l'alarme est bien planifiée :
   ```
   🔔 Planification alarme:
   ✅ Alarme planifiée avec succès
   ```

4. Vérifiez que l'alarme n'est pas dans le passé (les logs afficheront un avertissement)

### L'alarme ne s'affiche pas en plein écran
1. Vérifiez que vous êtes sur Android 10 ou supérieur
2. Vérifiez que la permission `USE_FULL_SCREEN_INTENT` est dans le manifest
3. Sur certains appareils, l'utilisateur doit autoriser explicitement les notifications plein écran dans les paramètres système

### Le son n'est pas celui attendu
- Le son utilisé est celui configuré dans les paramètres système Android
- Pour utiliser un son personnalisé, il faudrait ajouter un fichier son dans `android/app/src/main/res/raw/` et utiliser `RawResourceAndroidNotificationSound`

## 📱 Configuration Recommandée

Pour une meilleure expérience utilisateur :
1. **Autoriser les notifications plein écran** dans les paramètres système Android
2. **Configurer un son d'alarme audible** dans les paramètres système Android
3. **Désactiver l'optimisation de batterie** pour l'application MyKOG (pour garantir que les alarmes se déclenchent)

