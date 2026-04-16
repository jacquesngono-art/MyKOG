#!/bin/bash

# Script pour configurer la connexion USB (adb reverse) pour le développement Flutter
# Ce script configure le port forwarding pour que l'app sur le téléphone puisse accéder
# au backend sur l'ordinateur via localhost:3000

echo "🔌 Configuration de la connexion USB (adb reverse)"
echo "=================================================="
echo ""

# Vérifier si adb est installé
if ! command -v adb &> /dev/null; then
    echo "❌ Erreur: adb n'est pas installé ou n'est pas dans le PATH"
    echo "   Installez Android Platform Tools:"
    echo "   sudo apt-get install android-tools-adb"
    exit 1
fi

# Vérifier si un appareil est connecté
DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICES" -eq 0 ]; then
    echo "❌ Aucun appareil Android connecté via USB"
    echo "   Connectez votre téléphone via USB et activez le débogage USB"
    exit 1
fi

echo "✅ Appareil(s) détecté(s): $DEVICES"
echo ""

# Port du backend
PORT=3000

# Vérifier si le port forwarding existe déjà
EXISTING=$(adb reverse --list | grep "tcp:$PORT" | wc -l)

if [ "$EXISTING" -gt 0 ]; then
    echo "⚠️  Port forwarding existant détecté, suppression..."
    adb reverse --remove tcp:$PORT
    sleep 1
fi

# Configurer le port forwarding
echo "🔧 Configuration du port forwarding: tcp:$PORT -> tcp:$PORT"
adb reverse tcp:$PORT tcp:$PORT

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding configuré avec succès!"
    echo ""
    echo "📱 Votre application peut maintenant utiliser:"
    echo "   - localhost:$PORT"
    echo "   - 127.0.0.1:$PORT"
    echo ""
    echo "🌐 Backend accessible sur: http://localhost:$PORT"
    echo ""
    echo "💡 Pour vérifier: adb reverse --list"
    echo "💡 Pour supprimer: adb reverse --remove tcp:$PORT"
else
    echo "❌ Erreur lors de la configuration du port forwarding"
    exit 1
fi

