const { db } = require('../config/firebase');
const livekit = require('../services/livekitService');

const STREAM_CONFIG = {
  DEFAULT_STREAM_KEY: 'mykog_live',
};

function isValidStreamKey(streamKey) {
  if (!streamKey || typeof streamKey !== 'string') return false;
  return /^[a-zA-Z0-9_-]+$/.test(streamKey);
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'string') {
    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}

function generateStreamKey() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `mykog_${timestamp}_${random}`;
}

function formatLiveStream(id, data, includeLiveKit = false) {
  const streamKey = data.streamKey || STREAM_CONFIG.DEFAULT_STREAM_KEY;
  const roomName = livekit.generateRoomName(streamKey);
  const result = {
    id,
    title: data.title || 'Live Stream',
    description: data.description || '',
    pastor: data.pastor || 'Unknown',
    thumbnailUrl: data.thumbnailUrl || '',
    streamKey,
    roomName,
    status: data.status || 'scheduled',
    scheduledAt: toDate(data.scheduledAt),
    startedAt: toDate(data.startedAt),
    endedAt: toDate(data.endedAt),
    viewerCount: data.viewerCount || 0,
    peakViewerCount: data.peakViewerCount || 0,
    tags: data.tags || [],
    createdAt: toDate(data.createdAt) || new Date(),
    updatedAt: toDate(data.updatedAt) || new Date(),
  };
  if (includeLiveKit) {
    result.livekitUrl = livekit.getLiveKitUrl();
    if (data.whipUrl) result.whipUrl = data.whipUrl;
    if (data.ingressStreamKey) result.ingressStreamKey = data.ingressStreamKey;
  }
  return result;
}

// Créer un live stream
const createLiveStream = async (req, res) => {
  try {
    const { title, description, pastor, thumbnailUrl, streamKey, scheduledAt } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'Le titre est requis' });
    }
    if (!pastor || !pastor.trim()) {
      return res.status(400).json({ error: 'Le pasteur est requis' });
    }
    if (title.length > 200) {
      return res.status(400).json({ error: 'Le titre ne peut pas dépasser 200 caractères' });
    }
    if (description && description.length > 2000) {
      return res.status(400).json({ error: 'La description ne peut pas dépasser 2000 caractères' });
    }

    let finalStreamKey = streamKey || generateStreamKey();
    if (streamKey && !isValidStreamKey(streamKey)) {
      return res.status(400).json({
        error: 'Clé de stream invalide. Utilisez uniquement des caractères alphanumériques, tirets et underscores.',
      });
    }

    const roomName = livekit.generateRoomName(finalStreamKey);
    const now = new Date();
    const isLiveNow = (req.body.status || 'scheduled') === 'live';

    const liveStreamData = {
      title,
      description: description || '',
      pastor,
      thumbnailUrl: thumbnailUrl || '',
      streamKey: finalStreamKey,
      roomName,
      status: req.body.status || 'scheduled',
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      startedAt: isLiveNow ? now : null,
      endedAt: null,
      viewerCount: 0,
      peakViewerCount: 0,
      tags: req.body.tags || [],
      ingressId: null,
      whipUrl: null,
      ingressStreamKey: null,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection('liveStreams').add(liveStreamData);

    // Créer un Ingress WHIP pour OBS
    let ingressInfo = null;
    try {
      ingressInfo = await livekit.createWhipIngress(roomName, `live-${docRef.id}`, `broadcaster-${docRef.id}`);
      await docRef.update({
        ingressId: ingressInfo.ingressId,
        whipUrl: ingressInfo.url,
        ingressStreamKey: ingressInfo.streamKey,
      });
    } catch (err) {
      console.error('Erreur création Ingress WHIP:', err.message);
    }

    res.status(201).json({
      id: docRef.id,
      message: 'Live stream créé avec succès',
      data: formatLiveStream(docRef.id, liveStreamData, true),
      livekit: {
        url: livekit.getLiveKitUrl(),
        roomName,
        whipUrl: ingressInfo ? ingressInfo.url : `http://185.98.128.123:3001/whip`,
        streamKey: ingressInfo ? ingressInfo.streamKey : null,
        ingressId: ingressInfo ? ingressInfo.ingressId : null,
      },
    });
  } catch (error) {
    console.error('Erreur lors de la création du live:', error);
    res.status(500).json({
      error: 'Erreur lors de la création du live stream',
      details: error.message,
    });
  }
};

// Récupérer tous les live streams
const getAllLiveStreams = async (req, res) => {
  try {
    const snapshot = await db.collection('liveStreams').get();
    const liveStreams = [];

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const formatted = formatLiveStream(doc.id, data, true);
      // Compter les participants réels via LiveKit si le live est actif
      if (formatted.status === 'live') {
        try {
          const count = await livekit.getParticipantCount(formatted.roomName);
          formatted.viewerCount = count;
        } catch {}
      }
      liveStreams.push(formatted);
    }

    liveStreams.sort((a, b) => {
      const statusOrder = { live: 0, scheduled: 1, ended: 2 };
      return (statusOrder[a.status] || 3) - (statusOrder[b.status] || 3);
    });

    res.json(liveStreams);
  } catch (error) {
    console.error('Erreur lors de la récupération des lives:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des live streams' });
  }
};

// Récupérer un live stream par ID
const getLiveStreamById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('liveStreams').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    res.json(formatLiveStream(doc.id, doc.data(), true));
  } catch (error) {
    console.error('Erreur lors de la récupération du live:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération du live stream' });
  }
};

// Obtenir le live actif (status = 'live')
const getActiveLive = async (req, res) => {
  try {
    const snapshot = await db.collection('liveStreams').get();
    const activeLives = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.status === 'live') {
        activeLives.push({
          id: doc.id,
          data,
          startedAt: data.startedAt?.toDate() || new Date(0),
        });
      }
    });

    activeLives.sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime());

    if (activeLives.length === 0) {
      return res.status(404).json({ error: 'Aucun live actif', data: null });
    }

    const mostRecent = activeLives[0];
    const formatted = formatLiveStream(mostRecent.id, mostRecent.data, true);

    try {
      formatted.viewerCount = await livekit.getParticipantCount(formatted.roomName);
    } catch {}

    res.json(formatted);
  } catch (error) {
    console.error('Erreur lors de la récupération du live actif:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération du live actif',
      details: error.message,
    });
  }
};

// Obtenir un token viewer pour rejoindre un live
const getViewerToken = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body || {};
    const doc = await db.collection('liveStreams').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const data = doc.data();
    if (data.status !== 'live') {
      return res.status(400).json({ error: 'Le live n\'est pas encore actif' });
    }

    const roomName = data.roomName || livekit.generateRoomName(data.streamKey);
    const identity = userId ? `viewer-${userId}` : `viewer-${Date.now()}`;

    const token = await livekit.createViewerToken(roomName, identity);

    res.json({
      id,
      token,
      url: livekit.getLiveKitUrl(),
      roomName,
      identity,
    });
  } catch (error) {
    console.error('Erreur génération token viewer:', error);
    res.status(500).json({
      error: 'Erreur lors de la génération du token',
      details: error.message,
    });
  }
};

// Obtenir un token publisher pour diffuser (OBS / app desktop)
const getPublisherToken = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('liveStreams').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const data = doc.data();
    const roomName = data.roomName || livekit.generateRoomName(data.streamKey);

    // Si un Ingress existe déjà, retourner ses infos
    if (data.ingressId && data.whipUrl) {
      return res.json({
        id,
        url: livekit.getLiveKitUrl(),
        roomName,
        whipUrl: data.whipUrl,
        streamKey: data.ingressStreamKey,
        ingressId: data.ingressId,
      });
    }

    // Sinon créer un Ingress WHIP à la volée
    try {
      const ingress = await livekit.createWhipIngress(roomName, `live-${id}`, `broadcaster-${id}`);
      await doc.ref.update({
        ingressId: ingress.ingressId,
        whipUrl: ingress.url,
        ingressStreamKey: ingress.streamKey,
      });
      return res.json({
        id,
        url: livekit.getLiveKitUrl(),
        roomName,
        whipUrl: ingress.url,
        streamKey: ingress.streamKey,
        ingressId: ingress.ingressId,
      });
    } catch (err) {
      // Fallback: token publisher direct (WebRTC nat, sans OBS)
      const token = await livekit.createPublisherToken(roomName, `broadcaster-${id}`);
      return res.json({
        id,
        token,
        url: livekit.getLiveKitUrl(),
        roomName,
        whipUrl: `http://185.98.128.123:3001/whip`,
      });
    }
  } catch (error) {
    console.error('Erreur génération token publisher:', error);
    res.status(500).json({
      error: 'Erreur lors de la génération du token',
      details: error.message,
    });
  }
};

// Mettre à jour un live stream
const updateLiveStream = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, pastor, thumbnailUrl, streamKey, status } = req.body;

    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const now = new Date();
    const updateData = { updatedAt: now };

    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (pastor !== undefined) updateData.pastor = pastor;
    if (thumbnailUrl !== undefined) updateData.thumbnailUrl = thumbnailUrl;

    if (streamKey !== undefined) {
      if (!isValidStreamKey(streamKey)) {
        return res.status(400).json({
          error: 'Clé de stream invalide. Utilisez uniquement des caractères alphanumériques, tirets et underscores.',
        });
      }
      updateData.streamKey = streamKey;
      updateData.roomName = livekit.generateRoomName(streamKey);
    }

    if (status !== undefined) {
      if (!['scheduled', 'live', 'ended'].includes(status)) {
        return res.status(400).json({ error: 'Status invalide. Doit être: scheduled, live, ou ended' });
      }
      updateData.status = status;

      const currentData = doc.data();
      const previousStatus = currentData.status;

      if (status === 'live' && !currentData.startedAt) {
        updateData.startedAt = now;
      } else if (status === 'ended') {
        updateData.endedAt = now;
        // Supprimer la room LiveKit
        const roomName = currentData.roomName || livekit.generateRoomName(currentData.streamKey);
        await livekit.deleteRoom(roomName);
      }
    }

    await ref.update(updateData);
    const updatedDoc = await ref.get();

    res.json({
      id,
      message: 'Live stream mis à jour avec succès',
      data: formatLiveStream(id, updatedDoc.data(), true),
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du live:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour du live stream',
      details: error.message,
    });
  }
};

// Mettre à jour le statut d'un live stream
const updateLiveStreamStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['scheduled', 'live', 'ended'].includes(status)) {
      return res.status(400).json({ error: 'Status invalide. Doit être: scheduled, live, ou ended' });
    }

    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const now = new Date();
    const updateData = { status, updatedAt: now };
    const currentData = doc.data();
    const previousStatus = currentData.status;
    const roomName = currentData.roomName || livekit.generateRoomName(currentData.streamKey);

    if (status === 'live' && !currentData.startedAt) {
      updateData.startedAt = now;
    } else if (status === 'ended') {
      updateData.endedAt = now;
      if (previousStatus === 'live') {
        await livekit.deleteRoom(roomName);
      }
    }

    await ref.update(updateData);

    res.json({ id, message: `Statut mis à jour: ${status}`, data: updateData });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du statut' });
  }
};

// Incrémenter le nombre de viewers
const incrementViewerCount = async (req, res) => {
  try {
    const { id } = req.params;
    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const data = doc.data();
    const newCount = (data.viewerCount || 0) + 1;
    const peak = Math.max(newCount, data.peakViewerCount || 0);

    await ref.update({ viewerCount: newCount, peakViewerCount: peak, updatedAt: new Date() });

    res.json({ id, viewerCount: newCount, peakViewerCount: peak, message: 'Viewer count incrémenté' });
  } catch (error) {
    console.error('Erreur incrémentation viewers:', error);
    res.status(500).json({ error: 'Erreur lors de l\'incrémentation du compteur' });
  }
};

// Décrémenter le nombre de viewers
const decrementViewerCount = async (req, res) => {
  try {
    const { id } = req.params;
    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const data = doc.data();
    const newCount = Math.max((data.viewerCount || 0) - 1, 0);

    await ref.update({ viewerCount: newCount, updatedAt: new Date() });

    res.json({ id, viewerCount: newCount, message: 'Viewer count décrémenté' });
  } catch (error) {
    console.error('Erreur décrémentation viewers:', error);
    res.status(500).json({ error: 'Erreur lors de la décrémentation du compteur' });
  }
};

// Obtenir le nombre de viewers
const getViewerCount = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('liveStreams').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const data = doc.data();
    const roomName = data.roomName || livekit.generateRoomName(data.streamKey);
    let count = data.viewerCount || 0;

    if (data.status === 'live') {
      try {
        count = await livekit.getParticipantCount(roomName);
      } catch {}
    }

    res.json({
      id,
      viewerCount: count,
      peakViewerCount: data.peakViewerCount || 0,
      status: data.status || 'scheduled',
    });
  } catch (error) {
    console.error('Erreur récupération compteur:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération du compteur' });
  }
};

// Obtenir les infos serveur (URL LiveKit)
const getServerInfo = (req, res) => {
  try {
    res.json({
      livekitUrl: livekit.getLiveKitUrl(),
      whipUrl: 'http://185.98.128.123:3001/whip',
      defaultStreamKey: STREAM_CONFIG.DEFAULT_STREAM_KEY,
    });
  } catch (error) {
    console.error('Erreur infos serveur:', error);
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
    const ref = db.collection('liveStreams').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const data = doc.data();
    const roomName = data.roomName || livekit.generateRoomName(data.streamKey);
    if (data.ingressId) await livekit.deleteIngress(data.ingressId);
    await livekit.deleteRoom(roomName);
    await ref.delete();

    res.json({ id, message: 'Live stream supprimé avec succès' });
  } catch (error) {
    console.error('Erreur suppression live:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression du live stream' });
  }
};

// Supprimer tous les live streams
const deleteAllLiveStreams = async (req, res) => {
  try {
    const snapshot = await db.collection('liveStreams').get();
    const ids = [];

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const roomName = data.roomName || livekit.generateRoomName(data.streamKey);
      if (data.ingressId) await livekit.deleteIngress(data.ingressId);
      await livekit.deleteRoom(roomName);
      await doc.ref.delete();
      ids.push(doc.id);
    }

    res.json({ message: `${ids.length} live stream(s) supprimé(s)`, ids });
  } catch (error) {
    console.error('Erreur suppression tous les lives:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression des live streams' });
  }
};

module.exports = {
  createLiveStream,
  getAllLiveStreams,
  getLiveStreamById,
  getActiveLive,
  getViewerToken,
  getPublisherToken,
  getServerInfo,
  updateLiveStream,
  updateLiveStreamStatus,
  incrementViewerCount,
  decrementViewerCount,
  getViewerCount,
  deleteLiveStream,
  deleteAllLiveStreams,
};
