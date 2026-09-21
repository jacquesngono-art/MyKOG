const { admin, db } = require('../config/firebase');

/**
 * Envoyer une notification push à tous les utilisateurs
 * @param {Object} options - Options de la notification
 * @param {string} options.title - Titre de la notification
 * @param {string} options.body - Corps de la notification
 * @param {Object} options.data - Données supplémentaires
 * @param {string} options.imageUrl - URL de l'image (optionnel)
 * @param {string} options.type - Type de contenu (calendar, teaching, live, annonce)
 */
async function sendNotificationToAllUsers({
  title,
  body,
  data = {},
  imageUrl = null,
  type = 'general',
}) {
  try {
    // Écrire dans notifications_outbox pour le client desktop (Electron)
    try {
      await db.collection('notifications_outbox').add({
        title,
        body,
        data: data || {},
        imageUrl: imageUrl || null,
        type: type || 'general',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        readBy: [],
      });
    } catch (err) {
      console.warn('⚠️ Impossible d\'écrire dans notifications_outbox:', err.message);
    }

    // Vérifier la connectivité réseau avant d'essayer d'envoyer
    // Si pas de connexion, on retourne silencieusement sans bloquer
    if (!admin.messaging) {
      console.log('⚠️ Firebase Messaging non initialisé');
      return { sent: 0, failed: 0, total: 0, error: 'Firebase not initialized' };
    }

    // Récupérer tous les tokens FCM
    const tokensSnapshot = await db.collection('fcm_tokens').get();
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().fcmToken);

    if (tokens.length === 0) {
      console.log('⚠️ Aucun token FCM enregistré');
      return { sent: 0, failed: 0, total: 0 };
    }

    // Préparer le message
    const message = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl }),
      },
      data: {
        ...data,
        type,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'mykog_notifications',
          sound: 'default',
          icon: 'kog_launch', // Logo KOG de l'application
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
      let retries = 3; // Nombre de tentatives
      let lastError = null;
      
      while (retries > 0) {
        try {
          // Ajouter un timeout pour éviter que les erreurs réseau bloquent trop longtemps
          const sendPromise = admin.messaging().sendEachForMulticast({
            tokens: batch,
            ...message,
          });

          // Timeout de 30 secondes par batch (augmenté pour les connexions lentes)
          const timeoutPromise = new Promise((_, reject) => {
            setTimeout(() => reject(new Error('Timeout: connexion réseau trop lente')), 30000);
          });

          const response = await Promise.race([sendPromise, timeoutPromise]);
          
          // Succès, sortir de la boucle de retry
          lastError = null;
          retries = 0;

          successCount += response.successCount;
          failureCount += response.failureCount;

          // Supprimer les tokens invalides
          if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
              if (!resp.success && resp.error) {
                const invalidToken = batch[idx];
                // Supprimer le token invalide (de manière asynchrone pour ne pas bloquer)
                db.collection('fcm_tokens').doc(invalidToken).delete().catch(() => {});
                console.log(`🗑️ Token invalide supprimé: ${invalidToken}`);
              }
            });
          }
          break; // Sortir de la boucle de retry en cas de succès
        } catch (error) {
          lastError = error;
          retries--;
          
          // Gérer spécifiquement les erreurs réseau
          if (error.code === 'messaging/app/network-error' || 
              error.message?.includes('EAI_AGAIN') ||
              error.message?.includes('getaddrinfo') ||
              error.message?.includes('Timeout')) {
            if (retries > 0) {
              console.warn(`⚠️ Erreur réseau batch ${i / batchSize + 1}, nouvelle tentative dans 2s... (${retries} tentatives restantes)`);
              // Attendre 2 secondes avant de réessayer
              await new Promise(resolve => setTimeout(resolve, 2000));
            } else {
              console.warn(`⚠️ Erreur réseau batch ${i / batchSize + 1} après 3 tentatives: ${error.message}`);
              console.warn('💡 Vérifiez votre connexion internet et que fcm.googleapis.com est accessible');
              failureCount += batch.length;
            }
          } else {
            // Erreur non-réseau, ne pas réessayer
            console.error(`❌ Erreur batch ${i / batchSize + 1}:`, error);
            failureCount += batch.length;
            break;
          }
        }
      }
      
      // Si toutes les tentatives ont échoué avec une erreur réseau
      if (lastError && (lastError.code === 'messaging/app/network-error' || 
          lastError.message?.includes('EAI_AGAIN') ||
          lastError.message?.includes('getaddrinfo'))) {
        console.warn(`⚠️ Impossible d'envoyer le batch ${i / batchSize + 1} après 3 tentatives`);
      }
    }

    if (successCount > 0) {
      console.log(
        `✅ Notifications envoyées: ${successCount} réussies, ${failureCount} échouées sur ${tokens.length}`
      );
    } else if (failureCount > 0) {
      console.warn(
        `⚠️ Aucune notification envoyée: ${failureCount} échouées sur ${tokens.length}`
      );
      console.warn('💡 Vérifiez votre connexion internet et la configuration Firebase');
    }
    
    return { sent: successCount, failed: failureCount, total: tokens.length };
  } catch (error) {
    // Ne pas bloquer l'application en cas d'erreur réseau
    if (error.code === 'messaging/app/network-error' || 
        error.message?.includes('EAI_AGAIN') ||
        error.message?.includes('getaddrinfo')) {
      console.warn('⚠️ Erreur réseau lors de l\'envoi de notifications:', error.message);
      console.warn('💡 Les notifications ne seront pas envoyées, mais l\'opération principale continue');
      return { sent: 0, failed: 0, total: 0, error: 'Network error', warning: true };
    }
    console.error('❌ Erreur envoi notifications:', error);
    return { sent: 0, failed: 0, total: 0, error: error.message };
  }
}

/**
 * Envoyer une notification via topic
 * @param {string} topic - Topic FCM
 * @param {Object} options - Options de la notification
 */
async function sendNotificationToTopic(topic, { title, body, data = {}, imageUrl = null, type = 'general' }) {
  try {
    const message = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl }),
      },
      data: {
        ...data,
        type,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      topic,
      android: {
        priority: 'high',
        notification: {
          channelId: 'mykog_notifications',
          sound: 'default',
          icon: 'kog_launch', // Logo KOG de l'application
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

    // Ajouter un timeout avec retries
    let retries = 3;
    let lastError = null;
    
    while (retries > 0) {
      try {
        const sendPromise = admin.messaging().send(message);
        const timeoutPromise = new Promise((_, reject) => {
          setTimeout(() => reject(new Error('Timeout: connexion réseau trop lente')), 30000);
        });

        const response = await Promise.race([sendPromise, timeoutPromise]);
        console.log(`✅ Notification envoyée au topic ${topic}: ${response}`);
        return { success: true, messageId: response };
      } catch (error) {
        lastError = error;
        retries--;
        
        if ((error.code === 'messaging/app/network-error' || 
            error.message?.includes('EAI_AGAIN') ||
            error.message?.includes('getaddrinfo') ||
            error.message?.includes('Timeout')) && retries > 0) {
          console.warn(`⚠️ Erreur réseau topic ${topic}, nouvelle tentative dans 2s... (${retries} tentatives restantes)`);
          await new Promise(resolve => setTimeout(resolve, 2000));
        } else {
          break;
        }
      }
    }
    
    // Si toutes les tentatives ont échoué
    if (lastError) {
      if (lastError.code === 'messaging/app/network-error' || 
          lastError.message?.includes('EAI_AGAIN') ||
          lastError.message?.includes('getaddrinfo') ||
          lastError.message?.includes('Timeout')) {
        console.warn(`⚠️ Erreur réseau envoi au topic ${topic} après 3 tentatives: ${lastError.message}`);
        console.warn('💡 Vérifiez votre connexion internet');
        return { success: false, error: lastError.message, warning: true };
      }
      console.error(`❌ Erreur envoi au topic ${topic}:`, lastError);
      return { success: false, error: lastError.message };
    }
    
    return { success: false, error: 'Unknown error' };
  } catch (error) {
    // Gestion d'erreur globale (ne devrait pas arriver avec les retries)
    console.error(`❌ Erreur inattendue envoi au topic ${topic}:`, error);
    return { success: false, error: error.message };
  }
}

module.exports = {
  sendNotificationToAllUsers,
  sendNotificationToTopic,
};

