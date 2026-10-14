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
  return STREAM_CONFIG.DEFAULT_STREAM_KEY;
}

// Réutiliser l'Ingress existant pour la room (clé permanente), sinon le créer une fois
async function getOrCreateIngress(roomName, name, identity) {
  try {
    const existing = await livekit.listIngress(roomName);
    const found = (existing || []).find(i => i.roomName === roomName && i.streamKey);
    if (found) {
      return { ingressId: found.ingressId, url: found.url, streamKey: found.streamKey };
    }
  } catch (err) {
    console.error('Erreur listIngress:', err.message);
  }
  return await livekit.createRtmpIngress(roomName, name, identity);
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

    // Ingress RTMP permanent — réutilisé entre les lives (clé OBS stable)
    let ingressInfo = null;
    try {
      ingressInfo = await getOrCreateIngress(roomName, `live-${docRef.id}`, `broadcaster-${docRef.id}`);
      await docRef.update({
        ingressId: ingressInfo.ingressId,
        whipUrl: ingressInfo.url,
        ingressStreamKey: ingressInfo.streamKey,
      });
    } catch (err) {
      console.error('Erreur création Ingress RTMP:', err.message);
    }

    res.status(201).json({
      id: docRef.id,
      message: 'Live stream créé avec succès',
      data: formatLiveStream(docRef.id, liveStreamData, true),
      livekit: {
        url: livekit.getLiveKitUrl(),
        roomName,
        whipUrl: ingressInfo ? ingressInfo.url : `rtmp://185.98.128.123:1935/live`,
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

    // Sinon créer/réutiliser l'Ingress RTMP permanent
    try {
      const ingress = await getOrCreateIngress(roomName, `live-${id}`, `broadcaster-${id}`);
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
        whipUrl: `rtmp://185.98.128.123:1935/live`,
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

// Obtenir les infos serveur (URL LiveKit + clé de stream permanente pour OBS)
const getServerInfo = async (req, res) => {
  try {
    const roomName = livekit.generateRoomName(STREAM_CONFIG.DEFAULT_STREAM_KEY);
    let streamKey = null;
    let ingressId = null;
    try {
      const ingress = await getOrCreateIngress(roomName, 'mykog-rtmp', 'broadcaster');
      streamKey = ingress.streamKey;
      ingressId = ingress.ingressId;
    } catch (err) {
      console.error('Erreur getOrCreateIngress (server-info):', err.message);
    }
    res.json({
      livekitUrl: livekit.getLiveKitUrl(),
      rtmpUrl: 'rtmp://185.98.128.123:1935/live',
      whipUrl: 'https://vps123057.serveur-vps.net/whip',
      defaultStreamKey: STREAM_CONFIG.DEFAULT_STREAM_KEY,
      streamKey,
      ingressId,
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

// === Fin automatique d'un live quand le broadcaster s'arrête (OBS) ===
// Supprime le doc Firestore, ses commentaires et la room LiveKit.
// L'Ingress permanent n'est JAMAIS supprimé (clé OBS stable).

// Crée/réactive un doc live quand OBS démarre (ingress_started)
async function ensureLiveForRoom(roomName) {
  try {
    const snapshot = await db.collection('liveStreams').where('roomName', '==', roomName).get();
    if (!snapshot.empty) {
      for (const doc of snapshot.docs) {
        if (doc.data().status !== 'live') {
          await doc.ref.update({ status: 'live', startedAt: new Date(), updatedAt: new Date() });
        }
      }
      return;
    }
    const now = new Date();
    await db.collection('liveStreams').add({
      title: 'MyKOG — En direct',
      description: 'Diffusion en direct',
      pastor: 'MyKOG',
      streamUrl: `${livekit.getLiveKitUrl()}/${roomName}`,
      thumbnailUrl: '',
      status: 'live',
      scheduledAt: now,
      startedAt: now,
      createdAt: now,
      updatedAt: now,
      viewerCount: 0,
      streamKey: STREAM_CONFIG.DEFAULT_STREAM_KEY,
      livekitUrl: livekit.getLiveKitUrl(),
      roomName,
      ingressId: STREAM_CONFIG.INGRESS_ID || null,
    });
    console.log(`Live auto-créé pour room ${roomName} (broadcaster démarré)`);
  } catch (err) {
    console.error('Erreur ensureLiveForRoom:', err.message);
  }
}

async function endLiveByRoomName(roomName, reason = 'stream_ended') {
  try {
    const snapshot = await db.collection('liveStreams').where('roomName', '==', roomName).get();
    for (const doc of snapshot.docs) {
      if (doc.data().status !== 'live') continue;
      // Supprimer tous les commentaires du live
      const comments = await doc.ref.collection('comments').get();
      for (const c of comments.docs) await c.ref.delete();
      await doc.ref.delete();
      console.log(`Live ${doc.id} supprimé (${reason})`);
    }
    await livekit.deleteRoom(roomName);
  } catch (err) {
    console.error('Erreur endLiveByRoomName:', err.message);
  }
}

// Endpoint webhook LiveKit — événements ingress_ended / room_finished
const livekitWebhook = async (req, res) => {
  try {
    const receiver = livekit.getWebhookReceiver();
    const authHeader = req.get('Authorization') || '';
    const rawBody = Buffer.isBuffer(req.body) ? req.body.toString('utf-8') : (req.body || '');
    const event = await receiver.receive(rawBody, authHeader);

    const roomName = event.ingressInfo?.roomName || event.room?.name;
    if (event.event === 'ingress_started' && roomName) {
      console.log(`Webhook ingress_started → live actif (room: ${roomName})`);
      await ensureLiveForRoom(roomName);
    } else if (
      event.event === 'participant_joined' &&
      (event.participant?.identity || '').startsWith('broadcaster') &&
      roomName
    ) {
      // Secours: le broadcaster a rejoint sans ingress_started
      await ensureLiveForRoom(roomName);
    } else if (
      (event.event === 'ingress_ended' || event.event === 'room_finished') &&
      roomName
    ) {
      console.log(`Webhook ${event.event} → fin du live (room: ${roomName})`);
      await endLiveByRoomName(roomName, event.event);
    }
    res.json({ received: true });
  } catch (err) {
    console.error('Webhook LiveKit invalide:', err.message);
    res.status(400).json({ error: 'Webhook invalide' });
  }
};

// Watcher de secours: si le broadcaster a disparu de la room pendant ~90s
const _roomWatch = new Map(); // roomName -> { seen, missed }
const WATCH_INTERVAL_MS = 30000;
const WATCH_MAX_MISSES = 3;

async function _sweepLiveRooms() {
  try {
    const snapshot = await db.collection('liveStreams').where('status', '==', 'live').get();
    for (const doc of snapshot.docs) {
      const roomName = doc.data().roomName;
      if (!roomName) continue;

      const participants = await livekit.listParticipants(roomName);
      const hasBroadcaster = (participants || []).some(p =>
        (p.identity || '').startsWith('broadcaster')
      );

      const st = _roomWatch.get(roomName) || { seen: false, missed: 0 };
      if (hasBroadcaster) {
        st.seen = true;
        st.missed = 0;
      } else if (st.seen) {
        st.missed++;
        if (st.missed >= WATCH_MAX_MISSES) {
          _roomWatch.delete(roomName);
          console.log(`Watcher: broadcaster absent → fin du live (room: ${roomName})`);
          await endLiveByRoomName(roomName, 'broadcaster_left');
          continue;
        }
      }
      _roomWatch.set(roomName, st);
    }

    // Secours: room avec un broadcaster mais sans doc Firestore
    const rooms = await livekit.listRooms();
    const liveRoomNames = new Set(snapshot.docs.map(d => d.data().roomName));
    for (const room of rooms || []) {
      const roomName = room.name;
      if (!roomName || liveRoomNames.has(roomName)) continue;
      const participants = await livekit.listParticipants(roomName);
      const hasBroadcaster = (participants || []).some(p =>
        (p.identity || '').startsWith('broadcaster')
      );
      if (hasBroadcaster) {
        console.log(`Watcher: broadcaster sans doc → création live (room: ${roomName})`);
        await ensureLiveForRoom(roomName);
      }
    }
  } catch (err) {
    console.error('Erreur watcher rooms:', err.message);
  }
}
setInterval(_sweepLiveRooms, WATCH_INTERVAL_MS).unref();

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
  livekitWebhook,
};
