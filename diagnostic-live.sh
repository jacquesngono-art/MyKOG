#!/bin/bash

echo "🔍 DIAGNOSTIC COMPLET DU SYSTÈME LIVE STREAMING"
echo "================================================"

echo ""
echo "1. Vérification Nginx..."
sudo systemctl status nginx --no-pager | head -5

echo ""
echo "2. Vérification des ports..."
sudo ss -tuln | grep -E '1935|8080'

echo ""
echo "3. Vérification des permissions HLS..."
if [ -d "/var/www/html/hls" ]; then
    ls -la /var/www/html/hls/
    if [ -d "/var/www/html/hls/mykog_live" ]; then
        echo "✅ Dossier mykog_live existe"
        ls -la /var/www/html/hls/mykog_live/ | head -5
    else
        echo "❌ Dossier mykog_live n'existe pas (OBS pas encore connecté?)"
    fi
else
    echo "❌ Dossier /var/www/html/hls n'existe pas"
fi

echo ""
echo "4. Test URL HLS locale..."
curl -I http://localhost:8080/hls/mykog_live/index.m3u8 2>&1 | head -3

echo ""
echo "5. IP du serveur..."
ip addr show | grep "inet " | grep -v 127.0.0.1 | head -3

echo ""
echo "6. Test backend server-info..."
curl -s http://localhost:3000/api/lives/server-info | python3 -m json.tool 2>/dev/null || echo "❌ Backend non accessible"

echo ""
echo "7. Test live actif..."
curl -s http://localhost:3000/api/lives/active | python3 -m json.tool 2>/dev/null || echo "❌ Aucun live actif"

echo ""
echo "✅ Diagnostic terminé"

