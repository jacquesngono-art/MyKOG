#!/bin/bash

echo "🔍 Test de détection IP"
echo "======================"

echo ""
echo "1. IP détectée par le backend:"
cd /home/zfred/Bureau/Zfred/MyKOG-Terminal/backend-API
node -e "const {getServerIP, getHLSUrl} = require('./utils/stream_helper'); const ip = getServerIP(); console.log('IP:', ip); console.log('URL HLS:', getHLSUrl());"

echo ""
echo "2. Test endpoint server-info:"
curl -s http://localhost:3000/api/lives/server-info | python3 -m json.tool 2>/dev/null || echo "Backend non accessible"

echo ""
echo "3. Test URL HLS directe:"
curl -I http://192.168.100.6:8080/hls/mykog_live/index.m3u8 2>&1 | head -3

echo ""
echo "✅ Tests terminés"

