const { db } = require('../config/firebase');
const cloudinary = require('../config/cloudinary');
const storage = require('../services/storageService');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

function generateKey(prefix, file) {
  const ext = file.originalname.split('.').pop() || 'bin';
  return `${prefix}/${Date.now()}-${Math.round(Math.random() * 1E9)}.${ext}`;
}

async function resolvePdfUrl(docData) {
  if (docData.pdfKey) {
    try { return await storage.getDownloadUrl(docData.pdfKey); } catch {}
  }
  return docData.pdfUrl || '';
}

async function resolveCoverUrl(docData) {
  if (docData.coverImageKey) {
    try { return await storage.getDownloadUrl(docData.coverImageKey); } catch {}
  }
  return docData.coverImageUrl || '';
}

const createTextResume = async (req, res) => {
  try {
    const { title, speaker, description, category, tags, mois, annee, typeCulte } = req.body;

    if (!req.files || !req.files.pdf) {
      return res.status(400).json({ error: 'Fichier PDF requis' });
    }

    const pdfFile = req.files.pdf[0];

    if (!pdfFile.mimetype.includes('pdf')) {
      return res.status(400).json({ error: 'Le fichier doit être un PDF' });
    }

    if (!title || !speaker || !category) {
      return res.status(400).json({ error: 'Title, speaker et category sont requis' });
    }

    const pdfKey = generateKey('textes_resumes/pdfs', pdfFile);
    await storage.uploadFile(pdfKey, pdfFile.buffer, pdfFile.mimetype);

    let coverImageKey = '';
    if (req.files.image && req.files.image[0]) {
      const imageFile = req.files.image[0];
      coverImageKey = generateKey('textes_resumes/covers', imageFile);
      await storage.uploadFile(coverImageKey, imageFile.buffer, imageFile.mimetype);
    }

    const now = new Date();
    const publishedAt = now;

    const pdfUrl = await storage.getDownloadUrl(pdfKey);
    const coverImageUrl = coverImageKey ? await storage.getDownloadUrl(coverImageKey) : '';

    const textResumeData = {
      title,
      speaker,
      description: description || '',
      category,
      pdfUrl,
      coverImageUrl: coverImageUrl || '',
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      viewCount: 0,
      rating: 0.0,
      isNew: true,
      isFeatured: false,
      publishedAt,
      createdAt: now,
      updatedAt: now,
      mois: mois?.toString() || (now.getMonth() + 1).toString(),
      annee: annee?.toString() || now.getFullYear().toString(),
      typeCulte: typeCulte || 'Conférence',
      pdfKey,
      coverImageKey: coverImageKey || '',
      fileSize: pdfFile.size,
      pageCount: 0,
    };

    const docRef = await db.collection('textes_resumes').add(textResumeData);

    try {
      await sendNotificationToAllUsers({
        title: '📄 Nouveau texte résumé disponible',
        body: `${title} - ${speaker || 'Nouveau contenu'}`,
        data: { id: docRef.id, type: 'text_resume', textResumeId: docRef.id },
        imageUrl: coverImageUrl,
        type: 'text_resume',
      });
    } catch (notifError) {
      console.error('Erreur envoi notification texte résumé:', notifError);
    }

    res.status(201).json({
      id: docRef.id,
      message: 'Texte résumé créé avec succès',
      data: textResumeData,
    });

  } catch (error) {
    console.error('Erreur lors de la création:', error);
    res.status(500).json({
      error: 'Erreur lors de la création du texte résumé',
      details: error.message,
    });
  }
};

async function formatTextResume(doc) {
  const data = doc.data();
  const [pdfUrl, coverImageUrl] = await Promise.all([
    resolvePdfUrl(data),
    resolveCoverUrl(data),
  ]);
  return {
    id: doc.id,
    title: data.title || 'Titre non disponible',
    speaker: data.speaker || 'Auteur non disponible',
    description: data.description || '',
    category: data.category || 'Non classé',
    pdfUrl,
    coverImageUrl,
    tags: data.tags || [],
    viewCount: data.viewCount || 0,
    rating: data.rating || 0.0,
    isNew: data.isNew || false,
    isFeatured: data.isFeatured || false,
    publishedAt: data.publishedAt?.toDate()?.toISOString() || new Date().toISOString(),
    createdAt: data.createdAt?.toDate()?.toISOString() || new Date().toISOString(),
    updatedAt: data.updatedAt?.toDate()?.toISOString() || new Date().toISOString(),
    mois: data.mois?.toString() || (new Date().getMonth() + 1).toString(),
    annee: data.annee?.toString() || new Date().getFullYear().toString(),
    typeCulte: data.typeCulte?.toString() || 'Conférence',
    fileSize: data.fileSize || 0,
    pageCount: data.pageCount || 0,
  };
}

const getAllTextResumes = async (req, res) => {
  try {
    const { category, mois, annee, typeCulte, sortBy = 'publishedAt', order = 'desc' } = req.query;

    let query = db.collection('textes_resumes');

    if (category && category !== 'All') query = query.where('category', '==', category);
    if (mois && mois !== 'All') query = query.where('mois', '==', mois);
    if (annee && annee !== 'All') query = query.where('annee', '==', annee);
    if (typeCulte && typeCulte !== 'All') query = query.where('typeCulte', '==', typeCulte);

    const sortField = sortBy === 'title' ? 'title'
      : sortBy === 'speaker' ? 'speaker'
        : sortBy === 'viewCount' ? 'viewCount'
          : 'publishedAt';

    query = query.orderBy(sortField, order === 'asc' ? 'asc' : 'desc');

    const snapshot = await query.get();
    const textResumes = await Promise.all(
      snapshot.docs.map(doc => formatTextResume(doc))
    );

    res.json(textResumes);
  } catch (error) {
    console.error('Erreur lors de la récupération:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des textes résumés' });
  }
};

const getTextResumeById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('textes_resumes').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Texte résumé non trouvé' });
    }

    const formatted = await formatTextResume(doc);

    await db.collection('textes_resumes').doc(id).update({
      viewCount: (doc.data().viewCount || 0) + 1,
      updatedAt: new Date(),
    });

    res.json(formatted);
  } catch (error) {
    console.error('Erreur lors de la récupération:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération du texte résumé' });
  }
};

const updateTextResume = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, speaker, description, category, tags, isNew, isFeatured, viewCount, rating } = req.body;

    const textResumeRef = db.collection('textes_resumes').doc(id);
    const textResumeDoc = await textResumeRef.get();

    if (!textResumeDoc.exists) {
      return res.status(404).json({ error: 'Texte résumé non trouvé' });
    }

    const updateData = { updatedAt: new Date() };

    if (title !== undefined) updateData.title = title;
    if (speaker !== undefined) updateData.speaker = speaker;
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (tags !== undefined) updateData.tags = tags;
    if (isNew !== undefined) updateData.isNew = isNew;
    if (isFeatured !== undefined) updateData.isFeatured = isFeatured;
    if (viewCount !== undefined) updateData.viewCount = viewCount;
    if (rating !== undefined) updateData.rating = rating;

    const oldData = textResumeDoc.data();

    if (req.files && req.files.pdf) {
      const pdfFile = req.files.pdf[0];
      if (!pdfFile.mimetype.includes('pdf')) {
        return res.status(400).json({ error: 'Le fichier doit être un PDF' });
      }

      if (oldData.pdfKey) {
        try { await storage.deleteFile(oldData.pdfKey); } catch (e) { console.error('Erreur suppression ancien PDF B2:', e.message); }
      } else if (oldData.pdfPublicId) {
        try { await cloudinary.uploader.destroy(oldData.pdfPublicId, { resource_type: 'raw' }); } catch {}
      }

      const pdfKey = generateKey('textes_resumes/pdfs', pdfFile);
      await storage.uploadFile(pdfKey, pdfFile.buffer, pdfFile.mimetype);
      updateData.pdfKey = pdfKey;
      updateData.pdfUrl = await storage.getDownloadUrl(pdfKey);
      updateData.fileSize = pdfFile.size;
    }

    if (req.files && req.files.image) {
      const imageFile = req.files.image[0];

      if (oldData.coverImageKey) {
        try { await storage.deleteFile(oldData.coverImageKey); } catch (e) { console.error('Erreur suppression ancienne cover B2:', e.message); }
      } else if (oldData.coverImagePublicId) {
        try { await cloudinary.uploader.destroy(oldData.coverImagePublicId); } catch {}
      }

      const coverImageKey = generateKey('textes_resumes/covers', imageFile);
      await storage.uploadFile(coverImageKey, imageFile.buffer, imageFile.mimetype);
      updateData.coverImageKey = coverImageKey;
      updateData.coverImageUrl = await storage.getDownloadUrl(coverImageKey);
    }

    await textResumeRef.update(updateData);

    const updatedDoc = await textResumeRef.get();
    const formatted = await formatTextResume(updatedDoc);

    res.json({ id, message: 'Texte résumé mis à jour avec succès', data: formatted });

  } catch (error) {
    console.error('Erreur lors de la mise à jour:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour du texte résumé',
      details: error.message,
    });
  }
};

async function deleteTextResumeFiles(data) {
  if (data.pdfKey) {
    try { await storage.deleteFile(data.pdfKey); } catch (e) { console.error('Erreur suppression B2 PDF:', e.message); }
  } else if (data.pdfPublicId) {
    try { await cloudinary.uploader.destroy(data.pdfPublicId, { resource_type: 'raw' }); } catch {}
  }
  if (data.coverImageKey) {
    try { await storage.deleteFile(data.coverImageKey); } catch (e) { console.error('Erreur suppression B2 cover:', e.message); }
  } else if (data.coverImagePublicId) {
    try { await cloudinary.uploader.destroy(data.coverImagePublicId); } catch {}
  }
}

const deleteTextResume = async (req, res) => {
  try {
    const { id } = req.params;
    const textResumeDoc = await db.collection('textes_resumes').doc(id).get();

    if (!textResumeDoc.exists) {
      return res.status(404).json({ error: 'Texte résumé non trouvé' });
    }

    await deleteTextResumeFiles(textResumeDoc.data());
    await db.collection('textes_resumes').doc(id).delete();

    res.json({ message: 'Texte résumé supprimé avec succès' });

  } catch (error) {
    console.error('Erreur lors de la suppression:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression du texte résumé',
      details: error.message,
    });
  }
};

const deleteAllTextResumes = async (req, res) => {
  try {
    const snapshot = await db.collection('textes_resumes').get();
    const ids = [];
    const deletePromises = snapshot.docs.map(async (doc) => {
      ids.push(doc.id);
      await deleteTextResumeFiles(doc.data());
      await doc.ref.delete();
    });
    await Promise.all(deletePromises);
    res.json({ message: `${ids.length} résumé(s) supprimé(s)`, ids });
  } catch (error) {
    res.status(500).json({ error: 'Erreur lors de la suppression', details: error.message });
  }
};

const deleteTextResumesByFilter = async (req, res) => {
  try {
    let query = db.collection('textes_resumes');
    const filters = ['category', 'mois', 'annee'];
    filters.forEach(f => { if (req.query[f]) query = query.where(f, '==', req.query[f]); });
    const snapshot = await query.get();
    const ids = [];
    const deletePromises = snapshot.docs.map(async (doc) => {
      ids.push(doc.id);
      await deleteTextResumeFiles(doc.data());
      await doc.ref.delete();
    });
    await Promise.all(deletePromises);
    res.json({ message: `${ids.length} résumé(s) supprimé(s)`, ids });
  } catch (error) {
    res.status(500).json({ error: 'Erreur lors de la suppression', details: error.message });
  }
};

module.exports = {
  createTextResume,
  getAllTextResumes,
  getTextResumeById,
  updateTextResume,
  deleteTextResume,
  deleteAllTextResumes,
  deleteTextResumesByFilter,
};
