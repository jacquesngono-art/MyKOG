const { AccessToken, RoomServiceClient, IngressClient, IngressInput } = require('livekit-server-sdk');

const LIVEKIT_URL = process.env.LIVEKIT_URL || 'wss://vps123057.serveur-vps.net';
const API_KEY = process.env.LIVEKIT_API_KEY;
const API_SECRET = process.env.LIVEKIT_API_SECRET;

let roomService = null;
let ingressClient = null;

function getRoomService() {
  if (!roomService) {
    if (!API_KEY || !API_SECRET) {
      throw new Error('LiveKit non configuré (LIVEKIT_API_KEY / LIVEKIT_API_SECRET manquants)');
    }
    const host = LIVEKIT_URL.replace(/^wss?:\/\//, '').replace(/^https?:\/\//, '');
    roomService = new RoomServiceClient(`https://${host}`, API_KEY, API_SECRET);
  }
  return roomService;
}

function getIngressClient() {
  if (!ingressClient) {
    if (!API_KEY || !API_SECRET) {
      throw new Error('LiveKit non configuré (LIVEKIT_API_KEY / LIVEKIT_API_SECRET manquants)');
    }
    const host = LIVEKIT_URL.replace(/^wss?:\/\//, '').replace(/^https?:\/\//, '');
    ingressClient = new IngressClient(`https://${host}`, API_KEY, API_SECRET);
  }
  return ingressClient;
}

function getLiveKitUrl() {
  return LIVEKIT_URL;
}

function generateRoomName(streamKey) {
  return streamKey || 'mykog_live';
}

async function createPublisherToken(roomName, identity) {
  if (!API_KEY || !API_SECRET) {
    throw new Error('LiveKit non configuré');
  }
  const at = new AccessToken(API_KEY, API_SECRET, {
    identity: identity || 'broadcaster',
    ttl: 3600,
  });
  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: true,
    canSubscribe: false,
    canPublishData: true,
  });
  return at.toJwt();
}

async function createViewerToken(roomName, identity) {
  if (!API_KEY || !API_SECRET) {
    throw new Error('LiveKit non configuré');
  }
  const at = new AccessToken(API_KEY, API_SECRET, {
    identity: identity || `viewer-${Date.now()}`,
    ttl: 7200,
  });
  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: false,
    canSubscribe: true,
    canPublishData: false,
  });
  return at.toJwt();
}

async function listRooms() {
  try {
    return await getRoomService().listRooms();
  } catch (err) {
    console.error('Erreur listRooms LiveKit:', err.message);
    return [];
  }
}

async function getRoomInfo(roomName) {
  try {
    const rooms = await getRoomService().listRooms([roomName]);
    return rooms[0] || null;
  } catch (err) {
    console.error('Erreur getRoomInfo LiveKit:', err.message);
    return null;
  }
}

async function deleteRoom(roomName) {
  try {
    await getRoomService().deleteRoom(roomName);
    return true;
  } catch (err) {
    console.error('Erreur deleteRoom LiveKit:', err.message);
    return false;
  }
}

async function getParticipantCount(roomName) {
  const room = await getRoomInfo(roomName);
  return room ? room.numParticipants : 0;
}

async function createWhipIngress(roomName, name, identity) {
  try {
    const ingress = await getIngressClient().createIngress(IngressInput.WHIP_INPUT, {
      name: name || 'mykog-whip',
      roomName,
      participantIdentity: identity || 'broadcaster',
      participantName: 'Broadcaster',
      enableTranscoding: false,
    });
    return {
      ingressId: ingress.ingressId,
      url: ingress.url,
      streamKey: ingress.streamKey,
      state: ingress.state,
    };
  } catch (err) {
    console.error('Erreur createWhipIngress:', err.message);
    throw err;
  }
}

async function createRtmpIngress(roomName, name, identity) {
  try {
    const ingress = await getIngressClient().createIngress(IngressInput.RTMP_INPUT, {
      name: name || 'mykog-rtmp',
      roomName,
      participantIdentity: identity || 'broadcaster',
      participantName: 'Broadcaster',
      enableTranscoding: true,
    });
    return {
      ingressId: ingress.ingressId,
      url: ingress.url,
      streamKey: ingress.streamKey,
      state: ingress.state,
    };
  } catch (err) {
    console.error('Erreur createRtmpIngress:', err.message);
    throw err;
  }
}

async function listIngress(roomName) {
  try {
    return await getIngressClient().listIngress({ roomName });
  } catch (err) {
    console.error('Erreur listIngress:', err.message);
    return [];
  }
}

async function deleteIngress(ingressId) {
  try {
    await getIngressClient().deleteIngress(ingressId);
    return true;
  } catch (err) {
    console.error('Erreur deleteIngress:', err.message);
    return false;
  }
}

module.exports = {
  getLiveKitUrl,
  generateRoomName,
  createPublisherToken,
  createViewerToken,
  listRooms,
  getRoomInfo,
  deleteRoom,
  getParticipantCount,
  createWhipIngress,
  createRtmpIngress,
  listIngress,
  deleteIngress,
};
