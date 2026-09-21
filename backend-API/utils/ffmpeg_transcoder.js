const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Dossier de sortie HLS : backend-API/hls_output/<streamKey>/index.m3u8
const HLS_OUTPUT_DIR = path.join(__dirname, '..', 'hls_output');

// Binaire FFmpeg (peut être surchargé via FFMPEG_PATH dans .env)
const FFMPEG_BIN = process.env.FFMPEG_PATH || 'ffmpeg';

// Nombre max de tentatives de redémarrage en cas d'erreur
const MAX_RETRIES = 10;
const RETRY_DELAY_MS = 3000;

/**
 * Service de transcodage FFmpeg pour compatibilité universelle
 * Convertit automatiquement le stream RTMP en HLS avec les paramètres optimaux
 */
class FFmpegTranscoder {
  constructor(streamKey = 'mykog_live') {
    this.streamKey = streamKey;
    this.rtmpUrl = `rtmp://localhost:1935/live/${streamKey}`;
    this.hlsPath = path.join(HLS_OUTPUT_DIR, streamKey);
    this.process = null;
    this._isRunning = false;
    this._stopping = false;
    this.retryCount = 0;
    this.retryTimer = null;
  }

  /**
   * Démarrer le transcodage
   */
  start() {
    if (this._isRunning) {
      console.log(`⚠️ Transcoder déjà en cours pour ${this.streamKey}`);
      return;
    }

    this._stopping = false;

    // Créer le dossier HLS si nécessaire
    try {
      if (!fs.existsSync(this.hlsPath)) {
        fs.mkdirSync(this.hlsPath, { recursive: true });
        console.log(`✅ Dossier HLS créé: ${this.hlsPath}`);
      }
    } catch (err) {
      console.error(`❌ Impossible de créer le dossier HLS: ${err.message}`);
      throw new Error(`Impossible de créer le dossier HLS: ${err.message}`);
    }

    console.log(`🎬 Démarrage du transcodage FFmpeg pour: ${this.streamKey}`);
    console.log(`📡 Source RTMP: ${this.rtmpUrl}`);
    console.log(`📺 Destination HLS: ${this.hlsPath}`);

    this._spawn();
  }

  /**
   * Lancer le process FFmpeg
   * @private
   */
  _spawn() {
    // Paramètres FFmpeg pour compatibilité MAXIMALE (MediaTek et appareils bas de gamme)
    // Résolution ULTRA-BASSE (360x202) pour forcer la compatibilité MediaTek
    const ffmpegArgs = [
      '-i', this.rtmpUrl,
      // Vidéo - Paramètres ULTRA-compatibles pour MediaTek
      '-c:v', 'libx264',
      '-preset', 'ultrafast',          // Encodage le plus rapide possible
      '-profile:v', 'baseline',        // CRITIQUE pour compatibilité Android
      '-level', '3.0',                 // Level 3.0 (maximum compatible pour MediaTek)
      '-pix_fmt', 'yuv420p',           // Format pixel compatible (obligatoire)
      '-vf', 'scale=360:202:force_original_aspect_ratio=decrease,pad=360:202:(ow-iw)/2:(oh-ih)/2', // FORCER redimensionnement à 360x202
      '-r', '20',                      // FPS réduit à 20 (très compatible)
      '-g', '40',                      // GOP size (2 secondes à 20fps)
      '-keyint_min', '40',
      '-force_key_frames', 'expr:gte(n,n_forced*40)', // Forcer keyframes toutes les 40 frames
      '-sc_threshold', '0',            // Pas de détection de scène
      '-b:v', '400k',                  // Débit très réduit pour MediaTek
      '-maxrate', '400k',
      '-bufsize', '800k',
      '-bf', '0',                      // Pas de B-frames (CRITIQUE)
      '-refs', '1',                    // Une seule référence (CRITIQUE)
      '-tune', 'zerolatency',          // Latence zéro
      '-x264opts', 'no-mbtree:no-cabac:no-8x8dct:weightp=0:no-deblock', // Désactiver TOUTES les fonctionnalités avancées
      '-movflags', '+faststart',       // Optimisation pour streaming
      // Audio - Paramètres simplifiés pour MediaTek
      '-c:a', 'aac',
      '-b:a', '48k',                   // Débit audio minimal
      '-ar', '44100',                  // Sample rate standard (plus compatible)
      '-ac', '1',                      // Mono (plus compatible que stéréo)
      '-aac_coder', 'fast',            // Encodeur AAC rapide
      // HLS
      '-f', 'hls',
      '-hls_time', '2',                // Durée des segments (2s)
      '-hls_list_size', '10',          // 10 segments dans la playlist
      '-hls_flags', 'delete_segments+independent_segments', // Supprimer les anciens segments + segments indépendants
      '-hls_segment_type', 'mpegts',   // Type de segment explicite
      '-hls_segment_filename', path.join(this.hlsPath, 'segment_%03d.ts'),
      path.join(this.hlsPath, 'index.m3u8')
    ];

    try {
      this.process = spawn(FFMPEG_BIN, ffmpegArgs, {
        stdio: ['ignore', 'pipe', 'pipe']
      });
    } catch (error) {
      console.error(`❌ Erreur spawn FFmpeg: ${error.message}`);
      this._scheduleRetry();
      return;
    }

    this._isRunning = true;

    // Logger stdout
    this.process.stdout.on('data', (data) => {
      const output = data.toString();
      if (output.includes('error') || output.includes('Error')) {
        console.error(`❌ FFmpeg stdout: ${output}`);
      }
    });

    // Logger stderr (FFmpeg écrit sur stderr par défaut)
    this.process.stderr.on('data', (data) => {
      const output = data.toString();
      if (output.includes('error') || output.includes('Error') || output.includes('Failed')) {
        console.error(`❌ FFmpeg stderr: ${output}`);
      } else if (output.includes('frame=')) {
        // Afficher la progression toutes les 100 frames
        const frameMatch = output.match(/frame=\s*(\d+)/);
        if (frameMatch && parseInt(frameMatch[1]) % 100 === 0) {
          console.log(`📹 FFmpeg transcoding: ${frameMatch[1]} frames`);
        }
      }
    });

    this.process.on('close', (code) => {
      this._isRunning = false;
      this.process = null;

      if (this._stopping) {
        console.log(`✅ FFmpeg arrêté proprement pour ${this.streamKey}`);
        return;
      }

      if (code !== 0 && code !== null) {
        console.error(`❌ FFmpeg s'est arrêté avec le code: ${code}`);
        this._scheduleRetry();
      } else {
        console.log(`✅ FFmpeg transcodage terminé pour ${this.streamKey}`);
      }
    });

    this.process.on('error', (error) => {
      console.error(`❌ Erreur FFmpeg: ${error.message}`);
      this._isRunning = false;
      this.process = null;
      if (!this._stopping) {
        this._scheduleRetry();
      }
    });

    console.log(`✅ Transcoder démarré pour ${this.streamKey}`);
  }

  /**
   * Planifier une nouvelle tentative de démarrage (max MAX_RETRIES)
   * @private
   */
  _scheduleRetry() {
    if (this._stopping) {
      return;
    }

    if (this.retryCount >= MAX_RETRIES) {
      console.error(`❌ Nombre maximum de tentatives atteint (${MAX_RETRIES}) pour ${this.streamKey}. Abandon.`);
      return;
    }

    this.retryCount++;
    console.log(`🔁 Nouvelle tentative FFmpeg (${this.retryCount}/${MAX_RETRIES}) pour ${this.streamKey} dans ${RETRY_DELAY_MS / 1000}s...`);

    this.retryTimer = setTimeout(() => {
      if (!this._stopping) {
        this._spawn();
      }
    }, RETRY_DELAY_MS);
  }

  /**
   * Arrêter le transcodage
   */
  stop() {
    this._stopping = true;

    // Annuler une éventuelle tentative de retry en attente
    if (this.retryTimer) {
      clearTimeout(this.retryTimer);
      this.retryTimer = null;
    }

    if (this.process && this._isRunning) {
      console.log(`🛑 Arrêt du transcodage pour ${this.streamKey}`);
      this.process.kill('SIGTERM');
      this._isRunning = false;

      // Attendre un peu puis forcer l'arrêt si nécessaire
      const proc = this.process;
      setTimeout(() => {
        if (proc && !proc.killed) {
          proc.kill('SIGKILL');
        }
      }, 5000);
    }

    this.process = null;
    this.retryCount = 0;
  }

  /**
   * Vérifier si le transcodage est en cours
   * @returns {boolean}
   */
  isRunning() {
    return this._isRunning && this.process !== null && !this.process.killed;
  }

  /**
   * Alias de compatibilité (ancienne API)
   * @returns {boolean}
   */
  isActive() {
    return this.isRunning();
  }
}

module.exports = FFmpegTranscoder;
