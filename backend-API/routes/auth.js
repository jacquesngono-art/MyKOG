const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

// Mot de passe par défaut (en dur) — utilisé tant qu'aucun mot de passe
// n'a été enregistré dans Firebase (Firestore > config/admin).
// Il est remplacé définitivement dès le premier changement de mot de passe.
const DEFAULT_ADMIN_PASSWORD = 'mykog-admin-2024';

const adminDoc = () => db.collection('config').doc('admin');

async function getCurrentPassword() {
  try {
    const snap = await adminDoc().get();
    const pwd = snap.exists ? snap.data().password : null;
    if (pwd) return pwd;
  } catch (e) {
    console.error('Auth: lecture Firestore impossible, mot de passe par défaut utilisé:', e.message);
  }
  return DEFAULT_ADMIN_PASSWORD;
}

// POST /api/auth/login — vérifie le mot de passe
router.post('/login', async (req, res) => {
  try {
    const { password } = req.body || {};
    if (!password) {
      return res.status(400).json({ error: 'Mot de passe requis' });
    }
    const current = await getCurrentPassword();
    if (password !== current) {
      return res.status(401).json({ error: 'Mot de passe incorrect' });
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Erreur serveur', details: e.message });
  }
});

// PUT /api/auth/password — change le mot de passe (stocké dans Firebase)
router.put('/password', async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body || {};
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Mot de passe actuel et nouveau mot de passe requis' });
    }
    if (String(newPassword).length < 6) {
      return res.status(400).json({ error: 'Le nouveau mot de passe doit contenir au moins 6 caractères' });
    }
    const current = await getCurrentPassword();
    if (currentPassword !== current) {
      return res.status(401).json({ error: 'Mot de passe actuel incorrect' });
    }
    await adminDoc().set(
      { password: String(newPassword), updatedAt: new Date().toISOString() },
      { merge: true }
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Erreur serveur', details: e.message });
  }
});

module.exports = router;
