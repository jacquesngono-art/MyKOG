const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');

const {
  isStreamingServerRunning,
  getActiveTranscoders,
} = require('../services/streamingService');
const {
  STREAM_CONFIG,
  getHLSUrl,
  getPublicHlsUrl,
  getRTMPUrl,
  isValidStreamKey,
} = require('../utils/stream_helper');

const HLS_OUTPUT_DIR = path.join(__dirname, '..', 'hls_output');

/**
 * @openapi
 * /api/stream/status:
 *   get:
 *     summary: Vérifier si le serveur RTMP est actif
 *     tags: [Stream]
 *     responses:
 *       200:
 *         description: Statut du serveur de streaming
 */
router.get('/status', (req, res) => {
  const transcoders = getActiveTranscoders();

  res.json({
    running: isStreamingServerRunning(),
    rtmpPort: STREAM_CONFIG.RTMP_PORT,
    hlsPort: STREAM_CONFIG.HLS_PORT,
    hlsPath: STREAM_CONFIG.HLS_PATH,
    activeStreams: Array.from(transcoders.keys()),
    activeTranscoders: transcoders.size,
  });
});

/**
 * @openapi
 * /api/stream/hls/{streamKey}:
 *   get:
 *     summary: Obtenir l'URL HLS pour un streamKey
 *     tags: [Stream]
 *     parameters:
 *       - in: path
 *         name: streamKey
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: URL HLS du stream
 *       400:
 *         description: Clé de stream invalide
 */
router.get('/hls/:streamKey', (req, res) => {
  const { streamKey } = req.params;

  if (!isValidStreamKey(streamKey)) {
    return res.status(400).json({
      error: 'Clé de stream invalide. Utilisez uniquement des caractères alphanumériques, tirets et underscores.',
    });
  }

  const playlistPath = path.join(HLS_OUTPUT_DIR, streamKey, 'index.m3u8');

  res.json({
    streamKey,
    hlsUrl: getHLSUrl(streamKey),
    publicHlsUrl: getPublicHlsUrl(streamKey),
    rtmpUrl: getRTMPUrl(streamKey),
    available: fs.existsSync(playlistPath),
    transcoding: getActiveTranscoders().has(streamKey),
  });
});

module.exports = router;
