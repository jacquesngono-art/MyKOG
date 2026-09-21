const express = require('express');
const router = express.Router();
const { createAnnonce, getAllAnnonces, deleteAnnonce, deleteAllAnnonces } = require('../controllers/annonceController');

// Route pour créer une annonce
router.post('/', createAnnonce);

// Route pour récupérer toutes les annonces
router.get('/', getAllAnnonces);

// Route pour supprimer une annonce
router.delete('/:id', deleteAnnonce);

// Route pour supprimer toutes les annonces
router.delete('/all', deleteAllAnnonces);

module.exports = router;