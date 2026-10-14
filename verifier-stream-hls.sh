#!/bin/bash

echo "🔍 Vérification du Stream HLS"
echo "=============================="

echo ""
echo "1. Vérification des fichiers HLS..."
if [ -d "/var/www/html/hls/mykog_live" ]; then
    echo "✅ Dossier existe"
    echo ""
    echo "Contenu du dossier:"
    ls -lah /var/www/html/hls/mykog_live/ | head -10
    
    if [ -f "/var/www/html/hls/mykog_live/index.m3u8" ]; then
        echo ""
        echo "✅ Fichier index.m3u8 existe"
        echo ""
        echo "Contenu du fichier .m3u8:"
        head -20 /var/www/html/hls/mykog_live/index.m3u8
    else
        echo "❌ Fichier index.m3u8 n'existe pas"
    fi
else
    echo "❌ Dossier /var/www/html/hls/mykog_live n'existe pas"
    echo "   → OBS n'a probablement pas encore créé les fichiers"
fi

echo ""
echo "2. Test de l'URL HLS..."
curl -I http://192.168.100.6:8080/hls/mykog_live/index.m3u8 2>&1 | head -5

echo ""
echo "3. Informations sur le stream (si disponible)..."
if [ -f "/var/www/html/hls/mykog_live/index.m3u8" ]; then
    echo "Première ligne du .m3u8:"
    head -1 /var/www/html/hls/mykog_live/index.m3u8
    echo ""
    echo "Nombre de segments .ts:"
    ls /var/www/html/hls/mykog_live/*.ts 2>/dev/null | wc -l
    echo "segments trouvés"
fi

echo ""
echo "✅ Vérification terminée"

