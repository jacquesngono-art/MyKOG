const express = require('express');
const router = express.Router();
const {
  createCalendarEvent,
  getAllCalendarEvents,
  getEventsByYear,
  getCalendarEventById,
  updateCalendarEvent,
  deleteCalendarEvent,
  deleteAllCalendarEvents,
} = require('../controllers/calendarController');

// Route pour créer un événement (admin uniquement - à vérifier côté middleware)
router.post('/', createCalendarEvent);

// Route pour récupérer tous les événements
router.get('/', getAllCalendarEvents);

// Route pour récupérer les événements d'une année spécifique
router.get('/year/:year', getEventsByYear);

// Route pour récupérer un événement par son ID
router.get('/:id', getCalendarEventById);

// Route pour mettre à jour un événement (admin uniquement)
router.put('/:id', updateCalendarEvent);

// Route pour supprimer tous les événements
router.delete('/all', deleteAllCalendarEvents);

// Route pour supprimer un événement (admin uniquement)
router.delete('/:id', deleteCalendarEvent);

module.exports = router;

