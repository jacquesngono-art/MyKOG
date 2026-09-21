const { db } = require('../config/firebase');
const { sendNotificationToAllUsers } = require('../utils/notificationHelper');

// Créer un événement calendrier
const createCalendarEvent = async (req, res) => {
  try {
    const {
      title,
      description,
      startDate,
      endDate,
      location,
      category,
      color,
      isAllDay,
      createdBy,
      hasAlarm,
      alarmDaysBefore,
      alarmHoursBefore,
      alarmMinutesBefore,
    } = req.body;

    // Vérifier les champs requis
    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'Le titre est requis' });
    }
    if (!startDate) {
      return res.status(400).json({ error: 'La date de début est requise' });
    }
    if (title.length > 200) {
      return res.status(400).json({ error: 'Le titre ne peut pas dépasser 200 caractères' });
    }
    if (description && description.length > 2000) {
      return res.status(400).json({ error: 'La description ne peut pas dépasser 2000 caractères' });
    }

    // Valider les dates
    const parsedStartDate = new Date(startDate);
    if (isNaN(parsedStartDate.getTime())) {
      return res.status(400).json({ error: 'La date de début est invalide' });
    }

    let parsedEndDate = null;
    if (endDate) {
      parsedEndDate = new Date(endDate);
      if (isNaN(parsedEndDate.getTime())) {
        return res.status(400).json({ error: 'La date de fin est invalide' });
      }
      if (parsedEndDate <= parsedStartDate) {
        return res.status(400).json({ error: 'La date de fin doit être postérieure à la date de début' });
      }
    }

    // Générer un ID unique
    const id = `calendar-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const now = new Date();

    // Créer l'objet événement
    const eventData = {
      id,
      title,
      description: description || null,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      location: location || null,
      category: category || null,
      color: color || null,
      isAllDay: isAllDay || false,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy || null,
      hasAlarm: hasAlarm || false,
      alarmDaysBefore: alarmDaysBefore || null,
      alarmHoursBefore: alarmHoursBefore || null,
      alarmMinutesBefore: alarmMinutesBefore || null,
    };

    // Sauvegarder dans Firestore
    await db.collection('calendar').doc(id).set(eventData);

    // Envoyer une notification push à tous les utilisateurs (non-bloquant)
    sendNotificationToAllUsers({
      title: '📅 Nouvel événement au calendrier',
      body: `${title} - ${startDate ? new Date(startDate).toLocaleDateString('fr-FR') : ''}`,
      data: {
        id,
        type: 'calendar',
        eventId: id,
      },
      type: 'calendar',
    }).catch((notifError) => {
      // Erreur déjà gérée dans notificationHelper, juste logger
      if (!notifError.warning) {
        console.error('Erreur envoi notification calendrier:', notifError);
      }
    });

    res.status(201).json(eventData);
  } catch (error) {
    console.error('Erreur lors de la création de l\'événement:', error);
    res.status(500).json({
      error: 'Erreur lors de la création de l\'événement',
      details: error.message,
    });
  }
};

// Récupérer tous les événements
const getAllCalendarEvents = async (req, res) => {
  try {
    const snapshot = await db.collection('calendar').orderBy('startDate', 'asc').get();
    const events = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      startDate: doc.data().startDate?.toDate?.()?.toISOString() || doc.data().startDate,
      endDate: doc.data().endDate?.toDate?.()?.toISOString() || doc.data().endDate,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt,
    }));

    res.status(200).json(events);
  } catch (error) {
    console.error('Erreur lors de la récupération des événements:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des événements',
      details: error.message,
    });
  }
};

// Récupérer les événements pour une année spécifique
const getEventsByYear = async (req, res) => {
  try {
    const { year } = req.params;
    const yearInt = parseInt(year);

    if (isNaN(yearInt)) {
      return res.status(400).json({ error: 'Année invalide' });
    }

    const startOfYear = new Date(yearInt, 0, 1);
    const endOfYear = new Date(yearInt, 11, 31, 23, 59, 59);

    const snapshot = await db
      .collection('calendar')
      .where('startDate', '>=', startOfYear)
      .where('startDate', '<=', endOfYear)
      .orderBy('startDate', 'asc')
      .get();

    const events = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      startDate: doc.data().startDate?.toDate?.()?.toISOString() || doc.data().startDate,
      endDate: doc.data().endDate?.toDate?.()?.toISOString() || doc.data().endDate,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt,
    }));

    res.status(200).json(events);
  } catch (error) {
    console.error('Erreur lors de la récupération des événements:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des événements',
      details: error.message,
    });
  }
};

// Récupérer un événement par son ID
const getCalendarEventById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('calendar').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Événement non trouvé' });
    }

    const eventData = {
      id: doc.id,
      ...doc.data(),
      startDate: doc.data().startDate?.toDate?.()?.toISOString() || doc.data().startDate,
      endDate: doc.data().endDate?.toDate?.()?.toISOString() || doc.data().endDate,
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || doc.data().createdAt,
      updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt,
    };

    res.status(200).json(eventData);
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'événement:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération de l\'événement',
      details: error.message,
    });
  }
};

// Mettre à jour un événement
const updateCalendarEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      startDate,
      endDate,
      location,
      category,
      color,
      isAllDay,
      hasAlarm,
      alarmDaysBefore,
      alarmHoursBefore,
      alarmMinutesBefore,
    } = req.body;

    // Vérifier que l'événement existe
    const doc = await db.collection('calendar').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Événement non trouvé' });
    }

    // Préparer les données de mise à jour
    const updateData = {
      updatedAt: new Date(),
    };

    if (title !== undefined) {
      if (!title.trim()) return res.status(400).json({ error: 'Le titre ne peut pas être vide' });
      if (title.length > 200) return res.status(400).json({ error: 'Le titre ne peut pas dépasser 200 caractères' });
      updateData.title = title;
    }
    if (description !== undefined) {
      if (description.length > 2000) return res.status(400).json({ error: 'La description ne peut pas dépasser 2000 caractères' });
      updateData.description = description;
    }
    if (startDate !== undefined) {
      const parsedStart = new Date(startDate);
      if (isNaN(parsedStart.getTime())) return res.status(400).json({ error: 'La date de début est invalide' });
      updateData.startDate = parsedStart;
    }
    if (endDate !== undefined) {
      if (endDate) {
        const parsedEnd = new Date(endDate);
        if (isNaN(parsedEnd.getTime())) return res.status(400).json({ error: 'La date de fin est invalide' });
        const start = updateData.startDate || doc.data().startDate;
        if (start && parsedEnd <= new Date(start)) {
          return res.status(400).json({ error: 'La date de fin doit être postérieure à la date de début' });
        }
        updateData.endDate = parsedEnd;
      } else {
        updateData.endDate = null;
      }
    }
    if (location !== undefined) updateData.location = location;
    if (category !== undefined) updateData.category = category;
    if (color !== undefined) updateData.color = color;
    if (isAllDay !== undefined) updateData.isAllDay = isAllDay;
    if (hasAlarm !== undefined) updateData.hasAlarm = hasAlarm;
    if (alarmDaysBefore !== undefined) updateData.alarmDaysBefore = alarmDaysBefore;
    if (alarmHoursBefore !== undefined) updateData.alarmHoursBefore = alarmHoursBefore;
    if (alarmMinutesBefore !== undefined) updateData.alarmMinutesBefore = alarmMinutesBefore;

    // Mettre à jour dans Firestore
    await db.collection('calendar').doc(id).update(updateData);

    // Récupérer l'événement mis à jour
    const updatedDoc = await db.collection('calendar').doc(id).get();
    const eventData = {
      id: updatedDoc.id,
      ...updatedDoc.data(),
      startDate: updatedDoc.data().startDate?.toDate?.()?.toISOString() || updatedDoc.data().startDate,
      endDate: updatedDoc.data().endDate?.toDate?.()?.toISOString() || updatedDoc.data().endDate,
      createdAt: updatedDoc.data().createdAt?.toDate?.()?.toISOString() || updatedDoc.data().createdAt,
      updatedAt: updatedDoc.data().updatedAt?.toDate?.()?.toISOString() || updatedDoc.data().updatedAt,
    };

    // Envoyer une notification push à tous les utilisateurs pour la mise à jour
    try {
      await sendNotificationToAllUsers({
        title: '📅 Événement mis à jour',
        body: `${eventData.title || title} - ${eventData.startDate ? new Date(eventData.startDate).toLocaleDateString('fr-FR') : ''}`,
        data: {
          id,
          type: 'calendar',
          eventId: id,
        },
        type: 'calendar',
      });
    } catch (notifError) {
      console.error('Erreur envoi notification mise à jour calendrier:', notifError);
      // Ne pas bloquer la réponse si la notification échoue
    }

    res.status(200).json(eventData);
  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'événement:', error);
    res.status(500).json({
      error: 'Erreur lors de la mise à jour de l\'événement',
      details: error.message,
    });
  }
};

// Supprimer un événement
const deleteCalendarEvent = async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier que l'événement existe
    const doc = await db.collection('calendar').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Événement non trouvé' });
    }

    // Supprimer de Firestore
    await db.collection('calendar').doc(id).delete();

    res.status(200).json({ message: 'Événement supprimé avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'événement:', error);
    res.status(500).json({
      error: 'Erreur lors de la suppression de l\'événement',
      details: error.message,
    });
  }
};

const deleteAllCalendarEvents = async (req, res) => {
  try {
    const snapshot = await db.collection('calendar').get();
    const batchSize = snapshot.size;
    if (batchSize === 0) {
      return res.json({ message: 'Aucun événement à supprimer', deleted: 0 });
    }
    const deletePromises = snapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);
    res.json({ message: `${batchSize} événement(s) supprimé(s)`, deleted: batchSize });
  } catch (error) {
    console.error('Erreur suppression tous les événements:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression des événements' });
  }
};

module.exports = {
  createCalendarEvent,
  getAllCalendarEvents,
  getEventsByYear,
  getCalendarEventById,
  updateCalendarEvent,
  deleteCalendarEvent,
  deleteAllCalendarEvents,
};

