const { db, admin } = require('../config/firebase');

// Enregistrer un token FCM pour un utilisateur
const registerToken = async (req, res) => {
  try {
    const { userId, fcmToken } = req.body;

    if (!userId || !fcmToken) {
      return res.status(400).json({
        error: 'userId et fcmToken sont requis',
      });
    }

    // Vérifier si l'utilisateur existe, sinon le créer
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      // Créer un utilisateur par défaut si il n'existe pas
      console.log(`📝 Création de l'utilisateur ${userId} pour l'enregistrement du token`);
      await db.collection('users').doc(userId).set({
        id: userId,
        name: userId === 'default-user' ? 'Invité' : 'Utilisateur',
        email: userId === 'default-user' ? 'guest@example.com' : `${userId}@example.com`,
        fcmTokens: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }

    // Enregistrer ou mettre à jour le token
    await db.collection('fcm_tokens').doc(fcmToken).set({
      userId,
      fcmToken,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // Ajouter le token à la liste des tokens de l'utilisateur
    const userData = (await db.collection('users').doc(userId).get()).data();
    const tokens = userData?.fcmTokens || [];
    if (!tokens.includes(fcmToken)) {
      tokens.push(fcmToken);
      await db.collection('users').doc(userId).update({
        fcmTokens: tokens,
        updatedAt: new Date(),
      });
    }

    console.log(`✅ Token FCM enregistré pour l'utilisateur: ${userId}`);
    res.status(200).json({ message: 'Token enregistré avec succès' });
  } catch (error) {
    console.error('Erreur lors de l\'enregistrement du token:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'enregistrement du token',
      details: error.message,
    });
  }
};

// Supprimer un token FCM
const unregisterToken = async (req, res) => {
  try {
    const { userId, fcmToken } = req.body;

    if (!userId || !fcmToken) {
      return res.status(400).json({
        error: 'userId et fcmToken sont requis',
      });
    }

    // Supprimer le token
    await db.collection('fcm_tokens').doc(fcmToken).delete();

    // Retirer le token de la liste de l'utilisateur
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      const tokens = (userData.fcmTokens || []).filter((t) => t !== fcmToken);
      await db.collection('users').doc(userId).update({
        fcmTokens: tokens,
        updatedAt: new Date(),
      });
    }

    res.status(200).json({ message: 'Token supprimé avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression du token:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression du token',
      details: error.message,
    });
  }
};

// Envoyer une notification à tous les utilisateurs
const sendNotificationToAll = async (req, res) => {
  try {
    const { title, body, data, imageUrl } = req.body;

    if (!title || !body) {
      return res.status(400).json({
        error: 'title et body sont requis',
      });
    }

    // Sauvegarder dans Firestore pour les clients desktop/autres
    let notificationDoc;
    try {
      notificationDoc = await db.collection('notifications_outbox').add({
        title,
        body,
        data: data || {},
        imageUrl: imageUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        readBy: [],
      });
      console.log(`📝 Notification sauvegardée dans Firestore: ${notificationDoc.id}`);
    } catch (err) {
      console.warn('⚠️ Impossible de sauvegarder la notification dans Firestore:', err.message);
    }

    // Récupérer tous les tokens FCM
    const tokensSnapshot = await db.collection('fcm_tokens').get();
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().fcmToken);

    if (tokens.length === 0) {
      return res.status(200).json({
        message: 'Aucun token enregistré',
        sent: 0,
        firestoreId: notificationDoc?.id || null,
      });
    }

    // Préparer le message
    const message = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl }),
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'mykog_notifications',
          sound: 'default',
          ...(imageUrl && { imageUrl }),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Envoyer par batch (FCM limite à 500 tokens par batch)
    const batchSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: batch,
          ...message,
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        // Supprimer les tokens invalides
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success && resp.error) {
              const invalidToken = batch[idx];
              // Supprimer le token invalide
              db.collection('fcm_tokens').doc(invalidToken).delete();
            }
          });
        }
      } catch (error) {
        console.error(`Erreur batch ${i / batchSize + 1}:`, error);
        failureCount += batch.length;
      }
    }

    res.status(200).json({
      message: 'Notifications envoyées',
      sent: successCount,
      failed: failureCount,
      total: tokens.length,
      firestoreId: notificationDoc?.id || null,
    });
  } catch (error) {
    console.error('Erreur lors de l\'envoi des notifications:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'envoi des notifications',
      details: error.message,
    });
  }
};

// Envoyer une notification à un utilisateur spécifique
const sendNotificationToUser = async (req, res) => {
  try {
    const { userId, title, body, data, imageUrl } = req.body;

    if (!userId || !title || !body) {
      return res.status(400).json({
        error: 'userId, title et body sont requis',
      });
    }

    // Récupérer les tokens de l'utilisateur
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const tokens = userDoc.data().fcmTokens || [];
    if (tokens.length === 0) {
      return res.status(200).json({
        message: 'Aucun token enregistré pour cet utilisateur',
        sent: 0,
      });
    }

    // Préparer le message
    const message = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl }),
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'mykog_notifications',
          sound: 'default',
          ...(imageUrl && { imageUrl }),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Envoyer à tous les tokens de l'utilisateur
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      ...message,
    });

    res.status(200).json({
      message: 'Notification envoyée',
      sent: response.successCount,
      failed: response.failureCount,
    });
  } catch (error) {
    console.error('Erreur lors de l\'envoi de la notification:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'envoi de la notification',
      details: error.message,
    });
  }
};

// Envoyer une notification à un topic
const sendNotificationToTopic = async (req, res) => {
  try {
    const { topic, title, body, data, imageUrl } = req.body;

    if (!topic || !title || !body) {
      return res.status(400).json({
        error: 'topic, title et body sont requis',
      });
    }

    const message = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl }),
      },
      data: data || {},
      topic,
      android: {
        priority: 'high',
        notification: {
          channelId: 'mykog_notifications',
          sound: 'default',
          ...(imageUrl && { imageUrl }),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);

    res.status(200).json({
      message: 'Notification envoyée au topic',
      messageId: response,
    });
  } catch (error) {
    console.error('Erreur lors de l\'envoi au topic:', error);
    res.status(500).json({
      error: 'Erreur lors de l\'envoi au topic',
      details: error.message,
    });
  }
};

module.exports = {
  registerToken,
  unregisterToken,
  sendNotificationToAll,
  sendNotificationToUser,
  sendNotificationToTopic,
};

