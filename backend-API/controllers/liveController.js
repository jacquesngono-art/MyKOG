const { db } = require('../config/firebase');
const {
  STREAM_CONFIG,
  getServerIP,
  getHLSUrl,
  getRTMPUrl,
  getHLSUrlWithIP,
  getRTMPUrlWithIP,
  isValidStreamKey,
  generateStreamKey
} = require('../utils/stream_helper');
const {
  startTranscoderForStream,
  stopTranscoderForStream,
} = require('../services/streamingService');

// Créer un live stream
const createLiveStream = async (req, res) => {
  try {
    const { title, description, pastor, thumbnailUrl, streamUrl, streamKey, scheduledAt, serverIP } = req.body;

    // Vérifier les champs requis
    if (!title || !pastor) {
      return res.status(400).json({
        error: 'Title et pastor sont requis'
      });
    }

    const now = new Date();

    // Générer ou utiliser la clé de stream
    let finalStreamKey = streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;

    // Si une clé personnalisée est fournie, la valider
    if (streamKey && !isValidStreamKey(streamKey)) {
      return res.status(400).json({
        error: 'Clé de stream invalide. Utilisez uniquement des caractères alphanumériques, tirets et underscores.'
      });
    }

    // Générer les URLs RTMP et HLS
    const rtmpUrl = serverIP
      ? getRTMPUrlWithIP(serverIP, finalStreamKey)
      : getRTMPUrl(finalStreamKey);

    const hlsUrl = serverIP
      ? getHLSUrlWithIP(serverIP, finalStreamKey)
      : getHLSUrl(finalStreamKey);

    // Utiliser l'URL HLS fournie ou générer automatiquement
    const finalStreamUrl = (streamUrl && streamUrl.trim() !== '') ? streamUrl : hlsUrl;

    // Créer l'objet live stream
    const liveStreamData = {
      title: title,
      description: description || '',
      pastor: pastor,
      thumbnailUrl: thumbnailUrl || '',
      streamUrl: finalStreamUrl, // URL HLS pour la lecture
      streamKey: finalStreamKey, // Clé de streaming pour OBS
      rtmpUrl: rtmpUrl, // URL RTMP pour OBS
      hlsUrl: hlsUrl, // URL HLS générée
      status: req.body.status || 'scheduled', // scheduled, live, ended
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      startedAt: null,
      endedAt: null,
      viewerCount: 0,
      peakViewerCount: 0,
      tags: req.body.tags || [],
      createdAt: now,
      updatedAt: now,
    };

    // Sauvegarder dans Firestore
    const docRef = await db.collection('liveStreams').add(liveStreamData);

    // Démarrer le transcodage automatique si le statut est "live"
    if (liveStreamData.status === 'live') {
      try {
        startTranscoderForStream(finalStreamKey);
      } catch (error) {
        console.error(`⚠️ Erreur démarrage transcoder: ${error.message}`);
        // Ne pas faire échouer la création du live si le transcoder ne démarre pas
      }
    }

    res.status(201).json({
      id: docRef.id,
      message: 'Live stream créé avec succès',
      data: liveStreamData
    });

  } catch (error) {
    console.error('Erreur lors de la création du live:', error);
    res.status(500).json({
      error: 'Erreur lors de la création du live stream',
      details: error.message
    });
  }
};

// Récupérer tous les live streams
const getAllLiveStreams = async (req, res) => {
  try {
    const liveStreamsSnapshot = await db.collection('liveStreams').get();
    const liveStreams = [];

    liveStreamsSnapshot.forEach(doc => {
      const data = doc.data();
      const streamKey = data.streamKey || 'mykog_live';

      // Utiliser l'IP actuelle pour les URLs
      const currentHlsUrl = getHLSUrl(streamKey);
      const currentRtmpUrl = getRTMPUrl(streamKey);

      liveStreams.push({
        id: doc.id,
        title: data.title || 'Live Stream',
        description: data.description || '',
        pastor: data.pastor || 'Unknown',
        thumbnailUrl: data.thumbnailUrl || '',
        streamUrl: currentHlsUrl, // Toujours utiliser l'IP actuelle
        streamKey: streamKey,
        rtmpUrl: currentRtmpUrl, // Toujours utiliser l'IP actuelle
        hlsUrl: currentHlsUrl, // Toujours utiliser l'IP actuelle
        status: data.status || 'scheduled',
        scheduledAt: data.scheduledAt?.toDate() || null,
        startedAt: data.startedAt?.toDate() || null,
        endedAt: data.endedAt?.toDate() || null,
        viewerCount: data.viewerCount || 0,
        peakViewerCount: data.peakViewerCount || 0,
        tags: data.tags || [],
        createdAt: data.createdAt?.toDate() || new Date(),
        updatedAt: data.updatedAt?.toDate() || new Date(),
      });
    });

    // Trier: live en premier, puis scheduled, puis ended
    liveStreams.sort((a, b) => {
      const statusOrder = { live: 0, scheduled: 1, ended: 2 };
      return (statusOrder[a.status] || 3) - (statusOrder[b.status] || 3);
    });

    res.json(liveStreams);
  } catch (error) {
    console.error('Erreur lors de la récupération des lives:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des live streams'
    });
  }
};

// Récupérer un live stream par ID
const getLiveStreamById = async (req, res) => {
  try {
    const { id } = req.params;
    const liveStreamDoc = await db.collection('liveStreams').doc(id).get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    const data = liveStreamDoc.data();
    res.json({
      id: liveStreamDoc.id,
      ...data,
      scheduledAt: data.scheduledAt?.toDate(),
      startedAt: data.startedAt?.toDate(),
      endedAt: data.endedAt?.toDate(),
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du live:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération du live stream'
    });
  }
};

// Mettre à jour un live stream (complet)
const updateLiveStream = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, pastor, thumbnailUrl, streamUrl, streamKey, status, serverIP } = req.body;

    const liveStreamRef = db.collection('liveStreams').doc(id);
    const liveStreamDoc = await liveStreamRef.get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    const now = new Date();
    const updateData = {
      updatedAt: now,
    };

    // Mettre à jour les champs fournis
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (pastor !== undefined) updateData.pastor = pastor;
    if (thumbnailUrl !== undefined) updateData.thumbnailUrl = thumbnailUrl;

    // Gérer la clé de stream et les URLs
    const currentData = liveStreamDoc.data();
    let finalStreamKey = streamKey || currentData.streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;

    // Valider la clé si fournie
    if (streamKey && !isValidStreamKey(streamKey)) {
      return res.status(400).json({
        error: 'Clé de stream invalide. Utilisez uniquement des caractères alphanumériques, tirets et underscores.'
      });
    }

    // Générer les URLs si la clé change ou si l'IP change
    if (streamKey || serverIP) {
      const rtmpUrl = serverIP
        ? getRTMPUrlWithIP(serverIP, finalStreamKey)
        : getRTMPUrl(finalStreamKey);

      const hlsUrl = serverIP
        ? getHLSUrlWithIP(serverIP, finalStreamKey)
        : getHLSUrl(finalStreamKey);

      updateData.streamKey = finalStreamKey;
      updateData.rtmpUrl = rtmpUrl;
      updateData.hlsUrl = hlsUrl;

      // Mettre à jour l'URL de stream si non fournie explicitement
      if (!streamUrl) {
        updateData.streamUrl = hlsUrl;
      }
    }

    if (streamUrl !== undefined) updateData.streamUrl = streamUrl;

    // Gérer le statut
    if (status !== undefined) {
      if (!['scheduled', 'live', 'ended'].includes(status)) {
        return res.status(400).json({
          error: 'Status invalide. Doit être: scheduled, live, ou ended'
        });
      }
      updateData.status = status;

      // Ajouter timestamps selon le statut
      const previousStatus = currentData.status;
      const liveStreamKey = currentData.streamKey || finalStreamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;

      if (status === 'live' && !currentData.startedAt) {
        updateData.startedAt = now;
        // Démarrer le transcodage si on passe à "live"
        if (previousStatus !== 'live') {
          try {
            startTranscoderForStream(liveStreamKey);
          } catch (error) {
            console.error(`⚠️ Erreur démarrage transcoder: ${error.message}`);
          }
        }
      } else if (status === 'ended') {
        updateData.endedAt = now;
        // Arrêter le transcodage si on passe à "ended"
        if (previousStatus === 'live') {
          stopTranscoderForStream(liveStreamKey);
        }
      }
    }

    await liveStreamRef.update(updateData);

    // Récupérer le document mis à jour
    const updatedDoc = await liveStreamRef.get();
    const updatedData = updatedDoc.data();

    res.json({
      id: id,
      message: 'Live stream mis à jour avec succès',
      data: {
        id: updatedDoc.id,
        ...updatedData,
        scheduledAt: updatedData.scheduledAt?.toDate(),
        startedAt: updatedData.startedAt?.toDate(),
        endedAt: updatedData.endedAt?.toDate(),
        createdAt: updatedData.createdAt?.toDate(),
        updatedAt: updatedData.updatedAt?.toDate(),
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour du live:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour du live stream',
      details: error.message
    });
  }
};

// Mettre à jour le statut d'un live stream
const updateLiveStreamStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['scheduled', 'live', 'ended'].includes(status)) {
      return res.status(400).json({
        error: 'Status invalide. Doit être: scheduled, live, ou ended'
      });
    }

    const liveStreamRef = db.collection('liveStreams').doc(id);
    const liveStreamDoc = await liveStreamRef.get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    const now = new Date();
    const updateData = {
      status: status,
      updatedAt: now,
    };

    const currentData = liveStreamDoc.data();
    const previousStatus = currentData.status;
    const streamKey = currentData.streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;

    // Ajouter timestamps selon le statut
    if (status === 'live' && !currentData.startedAt) {
      updateData.startedAt = now;
      // Démarrer le transcodage si on passe à "live"
      if (previousStatus !== 'live') {
        try {
          startTranscoderForStream(streamKey);
        } catch (error) {
          console.error(`⚠️ Erreur démarrage transcoder: ${error.message}`);
        }
      }
    } else if (status === 'ended') {
      updateData.endedAt = now;
      // Arrêter le transcodage si on passe à "ended"
      if (previousStatus === 'live') {
        stopTranscoderForStream(streamKey);
      }
    }

    await liveStreamRef.update(updateData);

    res.json({
      id: id,
      message: `Statut mis à jour: ${status}`,
      data: updateData
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour du statut'
    });
  }
};

// Incrémenter le nombre de viewers (appelé quand un utilisateur rejoint)
const incrementViewerCount = async (req, res) => {
  try {
    const { id } = req.params;

    const liveStreamRef = db.collection('liveStreams').doc(id);
    const liveStreamDoc = await liveStreamRef.get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    const currentData = liveStreamDoc.data();
    const newViewerCount = (currentData.viewerCount || 0) + 1;
    const peakViewerCount = Math.max(newViewerCount, currentData.peakViewerCount || 0);

    await liveStreamRef.update({
      viewerCount: newViewerCount,
      peakViewerCount: peakViewerCount,
      updatedAt: new Date(),
    });

    res.json({
      id: id,
      viewerCount: newViewerCount,
      peakViewerCount: peakViewerCount,
      message: 'Viewer count incrémenté'
    });

  } catch (error) {
    console.error('Erreur lors de l\'incrémentation des viewers:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'incrémentation du compteur'
    });
  }
};

// Décrémenter le nombre de viewers (appelé quand un utilisateur quitte)
const decrementViewerCount = async (req, res) => {
  try {
    const { id } = req.params;

    const liveStreamRef = db.collection('liveStreams').doc(id);
    const liveStreamDoc = await liveStreamRef.get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    const currentData = liveStreamDoc.data();
    const newViewerCount = Math.max((currentData.viewerCount || 0) - 1, 0);

    await liveStreamRef.update({
      viewerCount: newViewerCount,
      updatedAt: new Date(),
    });

    res.json({
      id: id,
      viewerCount: newViewerCount,
      message: 'Viewer count décrémenté'
    });

  } catch (error) {
    console.error('Erreur lors de la décrémentation des viewers:', error);
    res.status(500).json({
      error: 'Erreur lors de la décrémentation du compteur'
    });
  }
};

// Obtenir le nombre de viewers en temps réel
const getViewerCount = async (req, res) => {
  try {
    const { id } = req.params;

    const liveStreamDoc = await db.collection('liveStreams').doc(id).get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    const data = liveStreamDoc.data();
    res.json({
      id: id,
      viewerCount: data.viewerCount || 0,
      peakViewerCount: data.peakViewerCount || 0,
      status: data.status || 'scheduled',
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du compteur:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération du compteur'
    });
  }
};

// Obtenir le live actif (status = 'live')
const getActiveLive = async (req, res) => {
  try {
    // Récupérer tous les lives et filtrer côté serveur pour éviter l'index Firestore
    const liveStreamsSnapshot = await db.collection('liveStreams').get();

    // Filtrer les lives actifs et trier par startedAt
    const activeLives = [];
    liveStreamsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.status === 'live') {
        activeLives.push({
          id: doc.id,
          data: data,
          startedAt: data.startedAt?.toDate() || new Date(0)
        });
      }
    });

    // Trier par startedAt (le plus récent en premier)
    activeLives.sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime());

    if (activeLives.length === 0) {
      return res.status(404).json({
        error: 'Aucun live actif',
        data: null
      });
    }

    // Prendre le live le plus récent
    const mostRecent = activeLives[0];
    const data = mostRecent.data;

    // Utiliser l'IP actuelle du serveur pour les URLs
    const streamKey = data.streamKey || 'mykog_live';

    // Générer les URLs avec l'IP actuelle
    const currentHlsUrl = getHLSUrl(streamKey);
    const currentRtmpUrl = getRTMPUrl(streamKey);

    res.json({
      id: mostRecent.id,
      title: data.title || 'Live en cours',
      description: data.description || '',
      pastor: data.pastor || 'MyKOG',
      thumbnailUrl: data.thumbnailUrl || '',
      streamUrl: currentHlsUrl, // Toujours utiliser l'IP actuelle
      streamKey: streamKey,
      rtmpUrl: currentRtmpUrl, // Toujours utiliser l'IP actuelle
      hlsUrl: currentHlsUrl, // Toujours utiliser l'IP actuelle
      status: data.status || 'live',
      viewerCount: data.viewerCount || 0,
      peakViewerCount: data.peakViewerCount || 0,
      scheduledAt: data.scheduledAt?.toDate() || null,
      startedAt: data.startedAt?.toDate() || null,
      endedAt: data.endedAt?.toDate() || null,
      tags: data.tags || [],
      createdAt: data.createdAt?.toDate() || new Date(),
      updatedAt: data.updatedAt?.toDate() || new Date(),
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du live actif:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération du live actif',
      details: error.message
    });
  }
};

// Obtenir les infos serveur (IP + URLs RTMP/HLS)
const getServerInfo = (req, res) => {
  try {
    const ip = getServerIP();
    const streamKey = STREAM_CONFIG.DEFAULT_STREAM_KEY;

    res.json({
      serverIP: ip,
      rtmpUrl: getRTMPUrlWithIP(ip, streamKey),
      hlsUrl: getHLSUrlWithIP(ip, streamKey),
      streamKey,
      rtmpPort: STREAM_CONFIG.RTMP_PORT,
      hlsPort: STREAM_CONFIG.HLS_PORT,
      hlsPath: STREAM_CONFIG.HLS_PATH,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des infos serveur:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des informations serveur',
      details: error.message,
    });
  }
};

// Supprimer un live stream
const deleteLiveStream = async (req, res) => {
  try {
    const { id } = req.params;

    const liveStreamRef = db.collection('liveStreams').doc(id);
    const liveStreamDoc = await liveStreamRef.get();

    if (!liveStreamDoc.exists) {
      return res.status(404).json({
        error: 'Live stream non trouvé'
      });
    }

    // Arrêter le transcoder si le live était en cours
    const data = liveStreamDoc.data();
    if (data.status === 'live' && data.streamKey) {
      stopTranscoderForStream(data.streamKey);
    }

    await liveStreamRef.delete();

    res.json({
      id: id,
      message: 'Live stream supprimé avec succès'
    });

  } catch (error) {
    console.error('Erreur lors de la suppression:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression du live stream'
    });
  }
};

// Supprimer tous les live streams
const deleteAllLiveStreams = async (req, res) => {
  try {
    const liveStreamsSnapshot = await db.collection('liveStreams').get();

    if (liveStreamsSnapshot.empty) {
      return res.json({
        message: 'Aucun live stream à supprimer',
        deleted: 0
      });
    }

    // Arrêter les transcoders des lives en cours
    liveStreamsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.status === 'live' && data.streamKey) {
        stopTranscoderForStream(data.streamKey);
      }
    });

    // Suppression par batch (max 500 opérations par batch Firestore)
    const BATCH_LIMIT = 500;
    let deleted = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of liveStreamsSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;
      deleted++;

      if (batchCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    res.json({
      message: 'Tous les live streams ont été supprimés',
      deleted: deleted
    });

  } catch (error) {
    console.error('Erreur lors de la suppression de tous les lives:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression des live streams',
      details: error.message
    });
  }
};

module.exports = {
  createLiveStream,
  getAllLiveStreams,
  getLiveStreamById,
  getActiveLive,
  getServerInfo,
  updateLiveStream,
  updateLiveStreamStatus,
  incrementViewerCount,
  decrementViewerCount,
  getViewerCount,
  deleteLiveStream,
  deleteAllLiveStreams,
};
