#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIVEKIT_DIR="$PROJECT_DIR/livekit_1.9.0_linux_amd64"
CONFIG_FILE="$PROJECT_DIR/livekit.yaml"
PID_FILE="$PROJECT_DIR/.livekit.pid"

echo -e "${BLUE}MyKOG - Démarrage du serveur LiveKit...${NC}"

# Vérifier si le serveur est déjà en cours d'exécution
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${RED}Le serveur LiveKit est déjà en cours d'exécution (PID: $PID)${NC}"
        echo -e "${GREEN}Pour l'arrêter: ./stop_livekit.sh${NC}"
        exit 1
    else
        rm "$PID_FILE"
    fi
fi

# Vérifier que le binaire existe
if [ ! -f "$LIVEKIT_DIR/livekit-server" ]; then
    echo -e "${RED}Binaire LiveKit non trouvé dans $LIVEKIT_DIR${NC}"
    echo -e "${BLUE}Vérifiez que livekit_1.9.0_linux_amd64 est bien copié depuis fred_soutenance_app${NC}"
    exit 1
fi

# Rendre le binaire exécutable si nécessaire
chmod +x "$LIVEKIT_DIR/livekit-server"

# Démarrer le serveur en arrière-plan
cd "$PROJECT_DIR"
nohup "$LIVEKIT_DIR/livekit-server" --config "$CONFIG_FILE" > livekit.log 2>&1 &
LIVEKIT_PID=$!

# Sauvegarder le PID
echo $LIVEKIT_PID > "$PID_FILE"

# Attendre un peu pour vérifier que le serveur démarre bien
sleep 3

if ps -p "$LIVEKIT_PID" > /dev/null 2>&1; then
    echo -e "${GREEN}Serveur LiveKit démarré avec succès (PID: $LIVEKIT_PID)${NC}"
    echo -e "${GREEN}URL WebSocket: ws://localhost:7880${NC}"
    echo -e "${GREEN}API Key: devkey${NC}"
    echo -e "${GREEN}API Secret: secret${NC}"
    echo -e "${BLUE}Logs: tail -f $PROJECT_DIR/livekit.log${NC}"
    echo -e "${BLUE}API Test: curl http://localhost:7880${NC}"
else
    echo -e "${RED}Erreur lors du démarrage du serveur LiveKit${NC}"
    echo -e "${RED}Voir les logs: cat $PROJECT_DIR/livekit.log${NC}"
    rm "$PID_FILE"
    exit 1
fi
