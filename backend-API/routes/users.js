const express = require('express');
const router = express.Router();
const {
  createOrUpdateUser,
  loginUser,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
  deleteAllUsers,
  getUserStats,
} = require('../controllers/userController');

// Connexion par numéro de téléphone
router.post('/login', loginUser);

// Route pour créer ou mettre à jour un utilisateur
router.post('/', createOrUpdateUser);

// Route pour récupérer tous les utilisateurs (admin uniquement)
router.get('/', getAllUsers);

// Route pour récupérer les statistiques des utilisateurs
router.get('/stats', getUserStats);

// Route pour récupérer un utilisateur par son ID
router.get('/:id', getUserById);

// Route pour mettre à jour un utilisateur
router.put('/:id', updateUser);

// Route pour supprimer tous les utilisateurs (admin uniquement)
router.delete('/all', deleteAllUsers);

// Route pour supprimer un utilisateur (admin uniquement)
router.delete('/:id', deleteUser);

module.exports = router;
