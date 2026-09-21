const { db } = require('../config/firebase');
const cloudinary = require('../config/cloudinary');
const storage = require('../services/storageService');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

const isKeyProvider = (p) => p === 'b2' || p === 's3';

async function resolveImageUrl(docData) {
  if (docData.imageKey) {
    const url = await storage.getDownloadUrl(docData.imageKey);
    if (url) return url;
  }
  return docData.artworkUrl || '';
}

async function resolveAudioUrl(docData) {
  if (docData.audioKey) {
    const url = await storage.getDownloadUrl(docData.audioKey);
    if (url) return url;
  }
  return docData.audioUrl || '';
}

const createEnseignement = async (req, res) => {
  try {
    const { title, speaker, description, category, tags } = req.body;

    if (!req.files || !req.files.image || !req.files.audio) {
      return res.status(400).json({ error: 'Image et audio sont requis' });
    }

    if (!title || !speaker || !category) {
      return res.status(400).json({ error: 'Title, speaker et category sont requis' });
    }

    const mois = req.body.mois?.toString();
    const annee = req.body.annee?.toString();
    if (!mois || !annee) {
      return res.status(400).json({ error: 'mois et annee sont requis' });
    }

    const imageResult = await storage.uploadBuffer(req.files.image[0], 'enseignements/images');
    const audioResult = await storage.uploadBuffer(req.files.audio[0], 'enseignements/audios');

    const now = new Date();
    const publishedAt = now;

    let artworkUrl = imageResult.url || '';
    let audioUrl = audioResult.url || '';

    if (isKeyProvider(imageResult.provider)) {
      artworkUrl = await storage.getDownloadUrl(imageResult.key) || '';
    }
    if (isKeyProvider(audioResult.provider)) {
      audioUrl = await storage.getDownloadUrl(audioResult.key) || '';
    }

    const enseignementData = {
      title,
      speaker,
      description: description || '',
      category,
      duration: parseInt(req.body.duration) || 0,
      audioUrl,
      artworkUrl,
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      playCount: 0,
      rating: 0.0,
      isNew: true,
      isFeatured: false,
      publishedAt,
      createdAt: now,
      updatedAt: now,
      mois,
      annee,
      typeCulte: req.body.typeCulte || 'Conférence',
    };

    if (isKeyProvider(imageResult.provider)) {
      enseignementData.imageKey = imageResult.key;
    } else {
      enseignementData.imagePublicId = imageResult.key;
    }
    if (isKeyProvider(audioResult.provider)) {
      enseignementData.audioKey = audioResult.key;
    } else {
      enseignementData.audioPublicId = audioResult.key;
    }

    const docRef = await db.collection('enseignements').add(enseignementData);

    try {
      await sendNotificationToAllUsers({
        title: '📚 Nouvel enseignement disponible',
        body: `${title} - ${speaker || 'Nouveau contenu'}`,
        data: { id: docRef.id, type: 'teaching', teachingId: docRef.id },
        imageUrl: artworkUrl,
        type: 'teaching',
      });
    } catch (notifError) {
      console.error('Erreur envoi notification enseignement:', notifError);
    }

    res.status(201).json({
      id: docRef.id,
      message: 'Enseignement créé avec succès',
      data: enseignementData,
    });

  } catch (error) {
    console.error('Erreur lors de la création:', error);
    res.status(500).json({
      error: 'Erreur lors de la création de l\'enseignement',
      details: error.message,
    });
  }
};

async function formatEnseignement(doc) {
  const data = doc.data();
  const [artworkUrl, audioUrl] = await Promise.all([
    resolveImageUrl(data),
    resolveAudioUrl(data),
  ]);
  return {
    id: doc.id,
    title: data.title || 'Titre non disponible',
    speaker: data.speaker || 'Orateur non disponible',
    description: data.description || '',
    category: data.category || 'Non classé',
    duration: data.duration || 0,
    audioUrl,
    artworkUrl,
    tags: data.tags || [],
    playCount: data.playCount || 0,
    rating: data.rating || 0.0,
    isNew: data.isNew || false,
    isFeatured: data.isFeatured || false,
    publishedAt: data.publishedAt?.toDate() || new Date(),
    createdAt: data.createdAt?.toDate() || new Date(),
    updatedAt: data.updatedAt?.toDate() || new Date(),
    mois: data.mois?.toString() || (new Date().getMonth() + 1).toString(),
    annee: data.annee?.toString() || new Date().getFullYear().toString(),
    typeCulte: data.typeCulte?.toString() || 'Conférence',
  };
}

const getAllEnseignements = async (req, res) => {
  try {
    let query = db.collection('enseignements');
    const filters = ['category', 'mois', 'annee', 'typeCulte'];
    filters.forEach(f => { if (req.query[f]) query = query.where(f, '==', req.query[f]); });
    const snapshot = await query.get();
    const enseignements = await Promise.all(
      snapshot.docs.map(doc => formatEnseignement(doc))
    );
    res.json(enseignements);
  } catch (error) {
    console.error('Erreur lors de la récupération:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des enseignements' });
  }
};

const updateEnseignement = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, speaker, description, playCount, rating, isNew, isFeatured, tags, category, typeCulte, mois, annee } = req.body;

    const enseignementRef = db.collection('enseignements').doc(id);
    const enseignementDoc = await enseignementRef.get();

    if (!enseignementDoc.exists) {
      return res.status(404).json({ error: 'Enseignement non trouvé' });
    }

    const existingData = enseignementDoc.data();
    const updateData = { updatedAt: new Date() };

    if (title !== undefined) updateData.title = title;
    if (speaker !== undefined) updateData.speaker = speaker;
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (typeCulte !== undefined) updateData.typeCulte = typeCulte;
    if (mois !== undefined) updateData.mois = mois.toString();
    if (annee !== undefined) updateData.annee = annee.toString();
    if (playCount !== undefined) updateData.playCount = playCount;
    if (rating !== undefined) updateData.rating = rating;
    if (isNew !== undefined) updateData.isNew = isNew;
    if (isFeatured !== undefined) updateData.isFeatured = isFeatured;
    if (tags !== undefined) {
      updateData.tags = typeof tags === 'string'
        ? tags.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0)
        : tags;
    }

    if (req.files && req.files.image && req.files.image[0]) {
      if (existingData.imageKey) {
        await storage.deleteFile(existingData.imageKey);
      } else if (existingData.imagePublicId) {
        try { await cloudinary.uploader.destroy(existingData.imagePublicId); } catch {}
      }

      const result = await storage.uploadBuffer(req.files.image[0], 'enseignements/images');
      if (isKeyProvider(result.provider)) {
        updateData.imageKey = result.key;
        delete updateData.imagePublicId;
        updateData.artworkUrl = await storage.getDownloadUrl(result.key) || '';
      } else {
        updateData.imagePublicId = result.key;
        delete updateData.imageKey;
        if (result.url) updateData.artworkUrl = result.url;
      }
    }

    await enseignementRef.update(updateData);

    const updatedDoc = await enseignementRef.get();
    const formatted = await formatEnseignement(updatedDoc);

    res.json({ id, message: 'Enseignement mis à jour avec succès', data: formatted });

  } catch (error) {
    console.error('Erreur lors de la mise à jour:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour de l\'enseignement',
      details: error.message,
    });
  }
};

async function deleteFiles(data) {
  if (data.imageKey) {
    await storage.deleteFile(data.imageKey);
  } else if (data.imagePublicId) {
    try { await cloudinary.uploader.destroy(data.imagePublicId); } catch {}
  }
  if (data.audioKey) {
    await storage.deleteFile(data.audioKey);
  } else if (data.audioPublicId) {
    try { await cloudinary.uploader.destroy(data.audioPublicId, { resource_type: 'video' }); } catch {}
  }
}

const deleteEnseignement = async (req, res) => {
  try {
    const { id } = req.params;
    const enseignementRef = db.collection('enseignements').doc(id);
    const enseignementDoc = await enseignementRef.get();

    if (!enseignementDoc.exists) {
      return res.status(404).json({ error: 'Enseignement non trouvé' });
    }

    await deleteFiles(enseignementDoc.data());
    await enseignementRef.delete();

    res.json({ id, message: 'Enseignement supprimé avec succès' });

  } catch (error) {
    console.error('Erreur lors de la suppression:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression de l\'enseignement',
      details: error.message,
    });
  }
};

const deleteAllEnseignements = async (req, res) => {
  try {
    const snapshot = await db.collection('enseignements').get();
    const ids = [];
    const deletePromises = snapshot.docs.map(async (doc) => {
      ids.push(doc.id);
      await deleteFiles(doc.data());
      await doc.ref.delete();
    });
    await Promise.all(deletePromises);
    res.json({ message: `${ids.length} enseignement(s) supprimé(s)`, ids });
  } catch (error) {
    res.status(500).json({ error: 'Erreur lors de la suppression', details: error.message });
  }
};

const deleteEnseignementsByFilter = async (req, res) => {
  try {
    let query = db.collection('enseignements');
    const filters = ['category', 'mois', 'annee', 'typeCulte'];
    filters.forEach(f => { if (req.query[f]) query = query.where(f, '==', req.query[f]); });
    const snapshot = await query.get();
    const ids = [];
    const deletePromises = snapshot.docs.map(async (doc) => {
      ids.push(doc.id);
      await deleteFiles(doc.data());
      await doc.ref.delete();
    });
    await Promise.all(deletePromises);
    res.json({ message: `${ids.length} enseignement(s) supprimé(s)`, ids });
  } catch (error) {
    res.status(500).json({ error: 'Erreur lors de la suppression', details: error.message });
  }
};

module.exports = {
  createEnseignement,
  getAllEnseignements,
  updateEnseignement,
  deleteEnseignement,
  deleteAllEnseignements,
  deleteEnseignementsByFilter,
};