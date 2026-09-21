const path = require('path');
const fs = require('fs');
const NodeMediaServer = require('node-media-server');
const FFmpegTranscoder = require('../utils/ffmpeg_transcoder');

// Dossier de sortie HLS (servi en HTTP par node-media-server et par Express)
const HLS_OUTPUT_DIR = path.join(__dirname, '..', 'hls_output');

// S'assurer que le dossier existe au démarrage
if (!fs.existsSync(HLS_OUTPUT_DIR)) {
  fs.mkdirSync(HLS_OUTPUT_DIR, { recursive: true });
}

/**
 * Configuration node-media-server
 * - RTMP sur le port 1935 : rtmp://<ip>:1935/live/<streamKey>
 * - HTTP sur le port 8000 : sert les fichiers HLS via /hls/<streamKey>/index.m3u8
 */
const config = {
  bind: '0.0.0.0',
  rtmp: {
    port: 1935,
    chunk_size: 60000,
    gop_cache: true,
    ping: 30,
    ping_timeout: 60,
  },
  http: {
    port: 8000,
    allow_origin: '*',
  },
  static: {
    router: '/hls',
    root: HLS_OUTPUT_DIR,
  },
};

// Instance unique du serveur de streaming
let nms = null;
let serverRunning = false;

// Transcoders FFmpeg actifs : Map<streamKey, FFmpegTranscoder>
const activeTranscoders = new Map();

/**
 * Extraire le streamKey depuis les arguments d'un événement NMS.
 * NMS 4.x passe un objet session (streamName / streamPath),
 * NMS 2.x passait (id, StreamPath, args). On gère les deux.
 */
function resolveStreamKey(...args) {
  for (const arg of args) {
    if (arg && typeof arg === 'object') {
      if (arg.streamName) return arg.streamName;
      if (arg.streamPath) {
        const parts = arg.streamPath.split('/').filter(Boolean);
        if (parts.length > 0) return parts[parts.length - 1];
      }
    } else if (typeof arg === 'string' && arg.includes('/')) {
      const parts = arg.split('/').filter(Boolean);
      if (parts.length > 0) return parts[parts.length - 1];
    }
  }
  return null;
}

/**
 * Démarrer le transcoder FFmpeg pour un streamKey (si pas déjà actif)
 * @param {string} streamKey
 * @returns {FFmpegTranscoder|null}
 */
function startTranscoderForStream(streamKey) {
  if (!streamKey) return null;

  const existing = activeTranscoders.get(streamKey);
  if (existing && existing.isRunning()) {
    console.log(`⚠️ Transcoder déjà actif pour ${streamKey}`);
    return existing;
  }

  try {
    const transcoder = new FFmpegTranscoder(streamKey);
    transcoder.start();
    activeTranscoders.set(streamKey, transcoder);
    console.log(`✅ Transcoder démarré pour: ${streamKey}`);
    return transcoder;
  } catch (error) {
    console.error(`⚠️ Erreur démarrage transcoder pour ${streamKey}: ${error.message}`);
    return null;
  }
}

/**
 * Arrêter le transcoder FFmpeg pour un streamKey
 * @param {string} streamKey
 * @returns {boolean} true si un transcoder a été arrêté
 */
function stopTranscoderForStream(streamKey) {
  const transcoder = activeTranscoders.get(streamKey);
  if (transcoder) {
    transcoder.stop();
    activeTranscoders.delete(streamKey);
    console.log(`🛑 Transcoder arrêté pour: ${streamKey}`);
    return true;
  }
  return false;
}

/**
 * Démarrer le serveur de streaming RTMP/HLS (node-media-server)
 * Écoute sur rtmp://<ip>:1935/live/<streamKey>
 * Sert le HLS sur http://<ip>:8000/hls/<streamKey>/index.m3u8
 *
 * @returns {NodeMediaServer} L'instance du serveur
 */
function startStreamingServer() {
  if (nms) {
    console.log('⚠️ Le serveur de streaming est déjà démarré');
    return nms;
  }

  nms = new NodeMediaServer(config);

  // Un client (OBS) commence à publier → lancer le transcodage HLS
  nms.on('prePublish', (...args) => {
    const streamKey = resolveStreamKey(...args);
    console.log(`📡 [RTMP] prePublish — streamKey: ${streamKey}`);

    if (streamKey) {
      startTranscoderForStream(streamKey);
    }
  });

  nms.on('postPublish', (...args) => {
    const streamKey = resolveStreamKey(...args);
    console.log(`🔴 [RTMP] postPublish — stream publié: ${streamKey}`);
  });

  // Le client arrête de publier → arrêter le transcodage
  nms.on('donePublish', (...args) => {
    const streamKey = resolveStreamKey(...args);
    console.log(`⚫ [RTMP] donePublish — stream terminé: ${streamKey}`);

    if (streamKey) {
      stopTranscoderForStream(streamKey);
    }
  });

  nms.on('prePlay', (...args) => {
    const streamKey = resolveStreamKey(...args);
    console.log(`▶️ [RTMP] prePlay — lecture demandée: ${streamKey}`);
  });

  nms.run();
  serverRunning = true;

  console.log('🚀 Serveur RTMP démarré sur le port 1935');
  console.log('   → OBS: rtmp://<ip>:1935/live/<streamKey>');
  console.log('📺 Serveur HTTP/HLS démarré sur le port 8000');
  console.log('   → HLS: http://<ip>:8000/hls/<streamKey>/index.m3u8');

  return nms;
}

/**
 * Vérifier si le serveur de streaming est actif
 * @returns {boolean}
 */
function isStreamingServerRunning() {
  return serverRunning && nms !== null;
}

/**
 * Obtenir la map des transcoders actifs
 * @returns {Map<string, FFmpegTranscoder>}
 */
function getActiveTranscoders() {
  return activeTranscoders;
}

module.exports = {
  startStreamingServer,
  isStreamingServerRunning,
  getActiveTranscoders,
  startTranscoderForStream,
  stopTranscoderForStream,
};
