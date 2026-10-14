#!/bin/bash

echo "📦 Installation de FFmpeg"
echo "========================="

echo ""
echo "1. Mise à jour des paquets..."
sudo apt update

echo ""
echo "2. Installation de FFmpeg..."
sudo apt install -y ffmpeg

echo ""
echo "3. Vérification de l'installation..."
if command -v ffmpeg &> /dev/null; then
    echo "✅ FFmpeg installé avec succès"
    ffmpeg -version | head -3
else
    echo "❌ Erreur: FFmpeg n'est pas installé"
    exit 1
fi

echo ""
echo "✅ Installation terminée"

