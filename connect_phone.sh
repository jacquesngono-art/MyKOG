#!/bin/bash

echo "🔍 Vérification d'ADB..."
if ! command -v adb &> /dev/null
then
    echo "❌ ADB n'est pas installé."
    exit 1
fi

echo "📱 Détection des appareils USB..."
USB_DEVICES=$(adb devices | grep -w "device" | awk '{print $1}')

if [ -z "$USB_DEVICES" ]; then
    echo "⚠ Aucun appareil détecté en USB. Connecte ton téléphone et active le debug USB."
    exit 1
fi

echo "✔ Appareils USB détectés :"
echo "$USB_DEVICES"
echo

for DEVICE in $USB_DEVICES; do
    echo "➡ Traitement du device : $DEVICE"

    echo "   📡 Récupération de l'adresse IP..."
    DEVICE_IP=$(adb -s $DEVICE shell ip -f inet addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

    if [ -z "$DEVICE_IP" ]; then
        echo "   ❌ Impossible de récupérer l'IP du téléphone."
        continue
    fi

    echo "   ✔ IP détectée : $DEVICE_IP"

    echo "   🔌 Activation du mode ADB TCP..."
    adb -s $DEVICE tcpip 5555 >/dev/null 2>&1
    sleep 1

    echo "   🌐 Connexion au téléphone via WiFi..."
    adb connect "$DEVICE_IP:5555"

    echo
done

echo "📋 Liste finale des devices connectés :"
adb devices

