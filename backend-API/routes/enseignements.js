const express = require('express');
const router = express.Router();
const { upload } = require('../middleware/upload');
const { createEnseignement, getAllEnseignements, updateEnseignement, deleteEnseignement, deleteAllEnseignements, deleteEnseignementsByFilter } = require('../controllers/enseignementController');

// Route pour créer un enseignement
router.post('/',
  upload.fields([{ name: 'image', maxCount: 1 }, { name: 'audio', maxCount: 1 }]),
  createEnseignement
);

// Route pour récupérer tous les enseignements
router.get('/', getAllEnseignements);

// Route pour mettre à jour un enseignement (avec support pour upload d'image optionnel)
router.put('/:id', 
  upload.fields([{ name: 'image', maxCount: 1 }]),
  updateEnseignement
);

// Route pour supprimer les enseignements par filtre (category, mois, annee, typeCulte)
router.delete('/batch', deleteEnseignementsByFilter);

// Route pour supprimer tous les enseignements
router.delete('/all', deleteAllEnseignements);

// Route pour supprimer un enseignement
router.delete('/:id', deleteEnseignement);

module.exports = router;