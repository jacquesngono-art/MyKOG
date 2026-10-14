#!/bin/bash

echo "🔍 Test de connectivité pour Gradle"
echo "===================================="
echo ""

echo "1️⃣ Test DNS..."
echo "   - repo.maven.apache.org:"
nslookup repo.maven.apache.org 2>&1 | grep -A 2 "Name:" || echo "   ❌ DNS échoué"
echo "   - dl.google.com:"
nslookup dl.google.com 2>&1 | grep -A 2 "Name:" || echo "   ❌ DNS échoué"
echo ""

echo "2️⃣ Test ping (3 paquets)..."
echo "   - repo.maven.apache.org:"
ping -c 3 repo.maven.apache.org 2>&1 | tail -2
echo "   - dl.google.com:"
ping -c 3 dl.google.com 2>&1 | tail -2
echo ""

echo "3️⃣ Test HTTP/HTTPS..."
echo "   - Maven Central:"
curl -I --connect-timeout 10 https://repo.maven.apache.org/maven2/ 2>&1 | head -3
echo "   - Google Maven:"
curl -I --connect-timeout 10 https://dl.google.com/dl/android/maven2/ 2>&1 | head -3
echo ""

echo "4️⃣ Test téléchargement spécifique (libvlc)..."
curl -I --connect-timeout 30 "https://repo.maven.apache.org/maven2/org/videolan/android/libvlc-all/3.6.3/libvlc-all-3.6.3.aar" 2>&1 | head -3
echo ""

echo "✅ Tests terminés"
echo ""
echo "💡 Si les tests échouent, essayez :"
echo "   1. Vérifier votre connexion internet"
echo "   2. Vérifier votre proxy/firewall"
echo "   3. Utiliser un VPN si nécessaire"
echo "   4. Réessayer plus tard (les serveurs peuvent être surchargés)"

