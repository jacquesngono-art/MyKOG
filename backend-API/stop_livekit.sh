#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$PROJECT_DIR/.livekit.pid"

echo -e "${YELLOW}MyKOG - Arrêt du serveur LiveKit...${NC}"

# Vérifier si le fichier PID existe
if [ ! -f "$PID_FILE" ]; then
    echo -e "${RED}Aucun fichier PID trouvé. Le serveur LiveKit n'est probablement pas en cours d'exécution.${NC}"
    exit 1
fi

# Lire le PID
PID=$(cat "$PID_FILE")

# Vérifier si le processus existe
if ps -p "$PID" > /dev/null 2>&1; then
    echo -e "${BLUE}Arrêt du processus LiveKit (PID: $PID)...${NC}"
    kill "$PID"
    
    # Attendre un peu
    sleep 2
    
    # Vérifier si le processus est encore en cours d'exécution
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Le processus ne répond pas, arrêt forcé...${NC}"
        kill -9 "$PID"
        sleep 1
    fi
    
    # Vérifier final
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Serveur LiveKit arrêté avec succès${NC}"
    else
        echo -e "${RED}Impossible d'arrêter le processus LiveKit${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Le processus LiveKit (PID: $PID) n'est pas en cours d'exécution${NC}"
fi

# Supprimer le fichier PID
rm "$PID_FILE"

echo -e "${GREEN}Nettoyage terminé${NC}"
