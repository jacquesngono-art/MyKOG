#!/bin/bash

echo "🔧 Correction des permissions HLS"
echo "=================================="

echo ""
echo "1. Correction des permissions du dossier HLS..."
sudo chown -R www-data:www-data /var/www/html/hls
sudo chmod -R 755 /var/www/html/hls

echo ""
echo "2. Vérification des permissions..."
ls -la /var/www/html/hls/ 2>/dev/null | head -5

echo ""
echo "✅ Permissions corrigées"

