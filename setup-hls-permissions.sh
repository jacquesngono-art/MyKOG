#!/bin/bash

echo "🔧 Configuration des permissions HLS"
echo "===================================="

echo ""
echo "1. Création du dossier HLS..."
sudo mkdir -p /var/www/html/hls
sudo mkdir -p /var/www/html/hls/mykog_live

echo ""
echo "2. Configuration des permissions..."
sudo chown -R www-data:www-data /var/www/html/hls
sudo chmod -R 755 /var/www/html/hls

echo ""
echo "3. Vérification des permissions..."
ls -la /var/www/html/hls/

echo ""
echo "✅ Permissions configurées avec succès"

