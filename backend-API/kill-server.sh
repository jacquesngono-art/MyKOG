#!/bin/bash

# Script pour arrêter tous les processus Node.js du serveur

echo "🛑 Recherche des processus Node.js..."

# Trouver tous les processus Node.js liés au serveur
PIDS=$(pgrep -f "node.*server.js")

if [ -z "$PIDS" ]; then
    echo "ℹ️ Aucun processus Node.js trouvé"
else
    echo "📌 Processus trouvés: $PIDS"
    for PID in $PIDS; do
        echo "🔪 Arrêt du processus $PID..."
        kill -9 $PID 2>/dev/null
    done
    sleep 1
fi

# Vérifier le port 3000
PORT_PID=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$PORT_PID" ]; then
    echo "📌 Processus sur le port 3000: $PORT_PID"
    kill -9 $PORT_PID 2>/dev/null
    sleep 1
fi

# Vérifier une dernière fois
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "⚠️ Le port 3000 est toujours occupé"
    echo "💡 Tentative avec killall..."
    killall -9 node 2>/dev/null
    sleep 1
fi

# Vérification finale
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "❌ Impossible de libérer le port 3000"
    echo "💡 Essayez manuellement: sudo killall -9 node"
    exit 1
else
    echo "✅ Tous les processus ont été arrêtés"
    echo "✅ Le port 3000 est maintenant libre"
fi

