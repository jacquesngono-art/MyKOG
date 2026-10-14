#!/bin/bash

# Script pour arrêter et redémarrer le serveur Node.js

echo "🛑 Arrêt du serveur Node.js sur le port 3000..."

# Trouver et tuer le processus sur le port 3000
PID=$(lsof -ti:3000 2>/dev/null)

if [ -z "$PID" ]; then
    # Essayer avec fuser
    PID=$(fuser 3000/tcp 2>/dev/null | awk '{print $1}')
fi

if [ -z "$PID" ]; then
    # Essayer avec netstat/ss
    PID=$(ss -tlnp 2>/dev/null | grep :3000 | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | head -1)
fi

if [ ! -z "$PID" ]; then
    echo "📌 Processus trouvé: PID $PID"
    echo "🔪 Arrêt du processus..."
    kill -9 $PID 2>/dev/null
    sleep 1
    
    # Vérifier qu'il est bien arrêté
    if lsof -ti:3000 >/dev/null 2>&1; then
        echo "⚠️ Le processus résiste, tentative de force..."
        killall -9 node 2>/dev/null
        sleep 1
    fi
    
    echo "✅ Processus arrêté"
else
    echo "ℹ️ Aucun processus trouvé sur le port 3000"
fi

# Vérifier une dernière fois
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "❌ Le port 3000 est toujours occupé"
    echo "💡 Essayez manuellement: sudo killall -9 node"
    exit 1
fi

echo ""
echo "🚀 Démarrage du serveur..."
echo ""

# Démarrer le serveur
cd "$(dirname "$0")"
node server.js

