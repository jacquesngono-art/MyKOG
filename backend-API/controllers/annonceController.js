const { db } = require('../config/firebase');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

const createAnnonce = async (req, res) => {
  try {
    const { nom, description } = req.body;

    // Vérifier que les champs sont remplis
    if (!nom || !nom.trim()) {
      return res.status(400).json({ error: 'Le nom de l\'annonce est requis' });
    }
    if (!description || !description.trim()) {
      return res.status(400).json({ error: 'La description est requise' });
    }
    if (nom.length > 200) {
      return res.status(400).json({ error: 'Le nom ne peut pas dépasser 200 caractères' });
    }
    if (description.length > 5000) {
      return res.status(400).json({ error: 'La description ne peut pas dépasser 5000 caractères' });
    }

    // Créer l'objet annonce
    const annonceData = {
      nom: nom,
      description: description,
      dateCreation: new Date()
    };

    // Sauvegarder dans Firestore
    const docRef = await db.collection('annonces').add(annonceData);

    // Envoyer une notification push à tous les utilisateurs
    try {
      await sendNotificationToAllUsers({
        title: '📢 Nouvelle annonce',
        body: nom,
        data: {
          id: docRef.id,
          type: 'annonce',
          annonceId: docRef.id,
        },
        type: 'annonce',
      });
    } catch (notifError) {
      console.error('Erreur envoi notification annonce:', notifError);
      // Ne pas bloquer la réponse si la notification échoue
    }

    res.status(201).json({
      id: docRef.id,
      message: 'Annonce créée avec succès',
      data: annonceData
    });

  } catch (error) {
    console.error('Erreur lors de la création:', error);
    res.status(500).json({
      error: 'Erreur lors de la création de l\'annonce',
      details: error.message
    });
  }
};

const getAllAnnonces = async (req, res) => {
  try {
    const annoncesSnapshot = await db.collection('annonces').get();
    const annonces = [];

    annoncesSnapshot.forEach(doc => {
      annonces.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.json(annonces);
  } catch (error) {
    console.error('Erreur lors de la récupération:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des annonces'
    });
  }
};

const deleteAllAnnonces = async (req, res) => {
  try {
    const snapshot = await db.collection('annonces').get();
    const batchSize = snapshot.size;
    if (batchSize === 0) {
      return res.json({ message: 'Aucune annonce à supprimer', deleted: 0 });
    }
    const deletePromises = snapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    res.json({ message: `${batchSize} annonce(s) supprimée(s)`, deleted: batchSize });
  } catch (error) {
    console.error('Erreur suppression toutes les annonces:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression des annonces' });
  }
};

const deleteAnnonce = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('annonces').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Annonce non trouvée' });
    }
    await doc.ref.delete();
    res.json({ id, message: 'Annonce supprimée avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'annonce' });
  }
};

module.exports = {
  createAnnonce,
  getAllAnnonces,
  deleteAnnonce,
  deleteAllAnnonces
};