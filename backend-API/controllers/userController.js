const { db } = require('../config/firebase');

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

const deleteAllUsers = async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const batchSize = snapshot.size;
    if (batchSize === 0) {
      return res.json({ message: 'Aucun utilisateur à supprimer', deleted: 0 });
    }
    const deletePromises = snapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    res.json({ message: `${batchSize} utilisateur(s) supprimé(s)`, deleted: batchSize });
  } catch (error) {
    console.error('Erreur suppression tous les utilisateurs:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression des utilisateurs' });
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
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  deleteAllUsers,
  getUserStats,
};
