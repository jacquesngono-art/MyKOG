const os = require('os');

/**
 * Configuration des streams RTMP/HLS
 */
const STREAM_CONFIG = {
  // Clé de stream par défaut
  DEFAULT_STREAM_KEY: process.env.DEFAULT_STREAM_KEY || 'mykog_live',

  // Port RTMP (node-media-server)
  RTMP_PORT: parseInt(process.env.RTMP_PORT || '1935', 10),

  // Port HTTP pour HLS.
  // Priorité : HLS_PORT > PUBLIC_PORT > PORT > 8000 (port HTTP de node-media-server)
  HLS_PORT: parseInt(
    process.env.HLS_PORT ||
    process.env.PUBLIC_PORT ||
    process.env.PORT ||
    '8000',
    10
  ),

  // Chemin HLS servi en HTTP
  HLS_PATH: '/hls',
};

/**
 * Obtenir l'IP du serveur (SERVER_IP en env, sinon détection automatique)
 */
function getServerIP() {
  if (process.env.SERVER_IP) {
    return process.env.SERVER_IP;
  }

  const interfaces = os.networkInterfaces();

  // Interfaces virtuelles à ignorer
  const virtualInterfaces = ['virbr0', 'docker0', 'br-', 'veth', 'lo'];

  // Chercher l'IP sur l'interface WiFi ou Ethernet réelle
  for (const name of Object.keys(interfaces)) {
    // Ignorer les interfaces virtuelles
    if (virtualInterfaces.some(vif => name.includes(vif))) {
      continue;
    }

    for (const iface of interfaces[name]) {
      // Ignorer les adresses internes et IPv6
      if (iface.family === 'IPv4' && !iface.internal) {
        // Préférer les IPs qui commencent par 192.168 (sauf 192.168.122.x qui est virbr0)
        if (iface.address.startsWith('192.168.') &&
            !iface.address.startsWith('192.168.122.')) {
          return iface.address;
        }
      }
    }
  }

  // Fallback : première IP non interne et non virtuelle
  for (const name of Object.keys(interfaces)) {
    if (virtualInterfaces.some(vif => name.includes(vif))) {
      continue;
    }

    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        // Éviter les IPs Docker et virbr0
        if (!iface.address.startsWith('172.17.') &&
            !iface.address.startsWith('172.18.') &&
            !iface.address.startsWith('192.168.122.')) {
          return iface.address;
        }
      }
    }
  }

  return 'localhost';
}

/**
 * Générer l'URL RTMP pour OBS
 * @param {string} streamKey - Clé de stream (optionnel, utilise la clé par défaut si non fournie)
 * @returns {string} URL RTMP complète
 */
function getRTMPUrl(streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  const ip = getServerIP();
  return `rtmp://${ip}:${STREAM_CONFIG.RTMP_PORT}/live/${streamKey}`;
}

/**
 * Générer l'URL HLS pour la lecture dans l'app
 * @param {string} streamKey - Clé de stream (optionnel, utilise la clé par défaut si non fournie)
 * @returns {string} URL HLS complète
 */
function getHLSUrl(streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  const ip = getServerIP();
  return `http://${ip}:${STREAM_CONFIG.HLS_PORT}${STREAM_CONFIG.HLS_PATH}/${streamKey}/index.m3u8`;
}

/**
 * Générer l'URL HLS avec IP personnalisée
 * @param {string} ip - IP du serveur
 * @param {string} streamKey - Clé de stream
 * @returns {string} URL HLS complète
 */
function getHLSUrlWithIP(ip, streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  return `http://${ip}:${STREAM_CONFIG.HLS_PORT}${STREAM_CONFIG.HLS_PATH}/${streamKey}/index.m3u8`;
}

/**
 * Générer l'URL RTMP avec IP personnalisée
 * @param {string} ip - IP du serveur
 * @param {string} streamKey - Clé de stream
 * @returns {string} URL RTMP complète
 */
function getRTMPUrlWithIP(ip, streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  return `rtmp://${ip}:${STREAM_CONFIG.RTMP_PORT}/live/${streamKey}`;
}

/**
 * Générer l'URL HLS "publique" (pour les clients externes).
 * Utilise RENDER_URL si défini, sinon SERVER_IP/IP détectée + PUBLIC_PORT ou PORT.
 * @param {string} streamKey - Clé de stream
 * @returns {string} URL HLS publique
 */
function getPublicHlsUrl(streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY) {
  // Si une URL publique est configurée (ex: Render), l'utiliser directement
  if (process.env.RENDER_URL) {
    const base = process.env.RENDER_URL.replace(/\/+$/, '');
    return `${base}${STREAM_CONFIG.HLS_PATH}/${streamKey}/index.m3u8`;
  }

  const ip = getServerIP();
  const port = process.env.PUBLIC_PORT || process.env.PORT || STREAM_CONFIG.HLS_PORT;
  return `http://${ip}:${port}${STREAM_CONFIG.HLS_PATH}/${streamKey}/index.m3u8`;
}

/**
 * Valider une clé de stream
 * @param {string} streamKey - Clé à valider
 * @returns {boolean} True si valide
 */
function isValidStreamKey(streamKey) {
  if (!streamKey || typeof streamKey !== 'string') {
    return false;
  }

  // La clé doit contenir uniquement des caractères alphanumériques, tirets et underscores
  return /^[a-zA-Z0-9_-]+$/.test(streamKey);
}

/**
 * Générer une clé de stream aléatoire
 * @returns {string} Clé de stream générée
 */
function generateStreamKey() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `mykog_${timestamp}_${random}`;
}

// Alias camelCase (compatibilité avec les conventions de nommage)
const getRtmpUrl = getRTMPUrl;
const getHlsUrl = getHLSUrl;

module.exports = {
  STREAM_CONFIG,
  getServerIP,
  getRTMPUrl,
  getHLSUrl,
  getRtmpUrl,
  getHlsUrl,
  getHLSUrlWithIP,
  getRTMPUrlWithIP,
  getPublicHlsUrl,
  isValidStreamKey,
  generateStreamKey,
};
