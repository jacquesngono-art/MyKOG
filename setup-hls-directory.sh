#!/bin/bash

echo "🔧 Configuration du dossier HLS"
echo "================================"

echo ""
echo "1. Création du dossier parent..."
sudo mkdir -p /var/www/html/hls

echo ""
echo "2. Configuration des permissions..."
sudo chown -R www-data:www-data /var/www/html/hls
sudo chmod -R 755 /var/www/html/hls

echo ""
echo "3. Vérification..."
ls -la /var/www/html/hls/ 2>/dev/null | head -5

echo ""
echo "✅ Dossier HLS configuré avec les bonnes permissions"
echo ""
echo "💡 Le backend peut maintenant créer les sous-dossiers sans erreur de permissions"

