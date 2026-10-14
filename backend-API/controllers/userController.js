const { db } = require('../config/firebase');

// Connexion d'un utilisateur existant par nom + numéro de téléphone
// (le téléphone est stocké dans le champ email)
const loginUser = async (req, res) => {
  try {
    const { phone, name } = req.body;
    if (!phone || !phone.trim()) {
      return res.status(400).json({ error: 'Numéro de téléphone requis' });
    }
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Nom requis' });
    }
    const snap = await db.collection('users')
      .where('email', '==', phone.trim())
      .limit(1)
      .get();
    if (snap.empty) {
      return res.status(404).json({ error: 'Aucun compte associé à ce numéro' });
    }
    const doc = snap.docs[0];
    const data = doc.data();

    // Vérifier que le nom correspond (insensible à la casse / espaces)
    const norm = (s) => (s || '').trim().toLowerCase().replace(/\s+/g, ' ');
    if (norm(data.name) !== norm(name)) {
      return res.status(401).json({ error: 'Nom ou numéro incorrect' });
    }

    res.json({
      id: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
      updatedAt: data.updatedAt?.toDate?.()?.toISOString() || data.updatedAt,
    });
  } catch (error) {
    console.error('Erreur login utilisateur:', error);
    res.status(500).json({ error: 'Erreur lors de la connexion', details: error.message });
  }
};

// Créer ou mettre à jour un utilisateur
const createOrUpdateUser = async (req, res) => {
  try {
    const {
      id,
      name,
      email,
      profileImageUrl,
      favoriteTeachingIds,
      downloadedTeachingIds,
      recentlyPlayedIds,
      notificationsEnabled,
    } = req.body;

    // Vérifier les champs requis
    if (!id || !name || !email) {
      return res.status(400).json({
        error: 'id, name et email sont requis',
      });
    }

    const now = new Date();

    // Vérifier si l'utilisateur existe déjà
    const userDoc = await db.collection('users').doc(id).get();
    
    let userData;
    if (userDoc.exists) {
      // Mettre à jour l'utilisateur existant
      userData = {
        name,
        email,
        profileImageUrl: profileImageUrl || userDoc.data().profileImageUrl || null,
        favoriteTeachingIds: favoriteTeachingIds || userDoc.data().favoriteTeachingIds || [],
        downloadedTeachingIds: downloadedTeachingIds || userDoc.data().downloadedTeachingIds || [],
        recentlyPlayedIds: recentlyPlayedIds || userDoc.data().recentlyPlayedIds || [],
        notificationsEnabled: notificationsEnabled !== undefined 
          ? notificationsEnabled 
          : (userDoc.data().notificationsEnabled !== undefined 
              ? userDoc.data().notificationsEnabled 
              : true),
        updatedAt: now,
        // Conserver la date de création originale
        createdAt: userDoc.data().createdAt || now,
      };
      
      await db.collection('users').doc(id).update(userData);
    } else {
      // Créer un nouvel utilisateur
      userData = {
        id,
        name,
        email,
        profileImageUrl: profileImageUrl || null,
        favoriteTeachingIds: favoriteTeachingIds || [],
        downloadedTeachingIds: downloadedTeachingIds || [],
        recentlyPlayedIds: recentlyPlayedIds || [],
        notificationsEnabled: notificationsEnabled !== undefined ? notificationsEnabled : true,
        createdAt: now,
        updatedAt: now,
      };
      
      await db.collection('users').doc(id).set(userData);
    }

    // Retourner les données avec les dates formatées
    const responseData = {
      ...userData,
      createdAt: userData.createdAt?.toDate?.()?.toISOString() || userData.createdAt,
      updatedAt: userData.updatedAt?.toDate?.()?.toISOString() || userData.updatedAt,
    };

    res.status(userDoc.exists ? 200 : 201).json(responseData);
  } catch (error) {
    console.error('Erreur lors de la création/mise à jour de l\'utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la création/mise à jour de l\'utilisateur',
      details: error.message,
    });
  }
};

// Récupérer tous les utilisateurs
const getAllUsers = async (req, res) => {
  try {
    const snapshot = await db.collection('users').orderBy('createdAt', 'desc').get();
    const users = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
        updatedAt: data.updatedAt?.toDate?.()?.toISOString() || data.updatedAt,
      };
    });

    res.status(200).json(users);
  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des utilisateurs',
      details: error.message,
    });
  }
};

// Récupérer un utilisateur par son ID
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('users').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const userData = {
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt,
    };

    res.status(200).json(userData);
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération de l\'utilisateur',
      details: error.message,
    });
  }
};

// Mettre à jour un utilisateur
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      email,
      profileImageUrl,
      favoriteTeachingIds,
      downloadedTeachingIds,
      recentlyPlayedIds,
      notificationsEnabled,
    } = req.body;

    // Vérifier que l'utilisateur existe
    const doc = await db.collection('users').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Préparer les données de mise à jour
    const updateData = {
      updatedAt: new Date(),
    };

    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (profileImageUrl !== undefined) updateData.profileImageUrl = profileImageUrl;
    if (favoriteTeachingIds !== undefined) updateData.favoriteTeachingIds = favoriteTeachingIds;
    if (downloadedTeachingIds !== undefined) updateData.downloadedTeachingIds = downloadedTeachingIds;
    if (recentlyPlayedIds !== undefined) updateData.recentlyPlayedIds = recentlyPlayedIds;
    if (notificationsEnabled !== undefined) updateData.notificationsEnabled = notificationsEnabled;

    // Mettre à jour dans Firestore
    await db.collection('users').doc(id).update(updateData);

    // Récupérer l'utilisateur mis à jour
    const updatedDoc = await db.collection('users').doc(id).get();
    const userData = {
      id: updatedDoc.id,
      ...updatedDoc.data(),
      createdAt: updatedDoc.data().createdAt?.toDate?.()?.toISOString() || updatedDoc.data().createdAt,
      updatedAt: updatedDoc.data().updatedAt?.toDate?.()?.toISOString() || updatedDoc.data().updatedAt,
    };

    res.status(200).json(userData);
  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour de l\'utilisateur',
      details: error.message,
    });
  }
};

// Supprimer un utilisateur
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier que l'utilisateur existe
    const doc = await db.collection('users').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Supprimer de Firestore
    await db.collection('users').doc(id).delete();

    res.status(200).json({ message: 'Utilisateur supprimé avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'utilisateur:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression de l\'utilisateur',
      details: error.message,
    });
  }
};

// Obtenir les statistiques des utilisateurs
const getUserStats = async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map((doc) => doc.data());

    const stats = {
      totalUsers: users.length,
      usersWithFavorites: users.filter((u) => u.favoriteTeachingIds?.length > 0).length,
      usersWithDownloads: users.filter((u) => u.downloadedTeachingIds?.length > 0).length,
      totalFavorites: users.reduce((sum, u) => sum + (u.favoriteTeachingIds?.length || 0), 0),
      totalDownloads: users.reduce((sum, u) => sum + (u.downloadedTeachingIds?.length || 0), 0),
      notificationsEnabled: users.filter((u) => u.notificationsEnabled === true).length,
      notificationsDisabled: users.filter((u) => u.notificationsEnabled === false).length,
    };

    res.status(200).json(stats);
  } catch (error) {
    console.error('Erreur lors de la récupération des statistiques:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des statistiques',
      details: error.message,
    });
  }
};

module.exports = {
  createOrUpdateUser,
  loginUser,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  getUserStats,
};
