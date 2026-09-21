#!/bin/bash

# Script de transcodage FFmpeg pour compatibilité universelle
# Ce script prend le stream RTMP et le convertit en HLS avec les paramètres optimaux

STREAM_KEY=${1:-mykog_live}
RTMP_URL="rtmp://localhost:1935/live/${STREAM_KEY}"
HLS_PATH="/var/www/html/hls/${STREAM_KEY}"
HLS_URL="http://localhost:8080/hls/${STREAM_KEY}"

# Créer le dossier HLS si nécessaire
mkdir -p "${HLS_PATH}"

echo "🎬 Démarrage du transcodage pour: ${STREAM_KEY}"
echo "📡 Source RTMP: ${RTMP_URL}"
echo "📺 Destination HLS: ${HLS_PATH}"

# Transcodage avec paramètres de compatibilité universelle
ffmpeg -i "${RTMP_URL}" \
  -c:v libx264 \
  -preset veryfast \
  -profile:v baseline \
  -level 3.1 \
  -pix_fmt yuv420p \
  -s 854x480 \
  -r 30 \
  -g 60 \
  -keyint_min 60 \
  -sc_threshold 0 \
  -b:v 1500k \
  -maxrate 1500k \
  -bufsize 3000k \
  -bf 0 \
  -refs 1 \
  -c:a aac \
  -b:a 128k \
  -ar 48000 \
  -ac 2 \
  -f hls \
  -hls_time 2 \
  -hls_list_size 5 \
  -hls_flags delete_segments \
  -hls_segment_filename "${HLS_PATH}/segment_%03d.ts" \
  "${HLS_PATH}/index.m3u8" \
  2>&1 | tee /tmp/ffmpeg-${STREAM_KEY}.log

echo "❌ FFmpeg s'est arrêté"

