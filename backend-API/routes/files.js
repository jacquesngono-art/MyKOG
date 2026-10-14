const express = require('express');
const router = express.Router();
const storage = require('../services/storageService');

/**
 * @openapi
 * /api/files/{key}:
 *   get:
 *     summary: Servir un fichier du stockage (S3/B2) via redirection signée
 *     description: URL stable — le backend génère une URL pré-signée fraîche à chaque appel
 *     tags: [Files]
 */
router.get('/*splat', async (req, res) => {
  try {
    const splat = req.params.splat;
    const key = decodeURIComponent(
      Array.isArray(splat) ? splat.join('/') : (splat || '')
    );
    if (!key || key.includes('..')) {
      return res.status(400).json({ error: 'Clé de fichier invalide' });
    }
    const url = await storage.getDownloadUrl(key);
    if (!url) {
      return res.status(404).json({ error: 'Fichier introuvable' });
    }
    // Redirection vers l'URL pré-signée S3 (expire 1h, régénérée à chaque appel)
    res.redirect(302, url);
  } catch (err) {
    console.error('Erreur fichier:', err.message);
    res.status(500).json({ error: 'Erreur lors de la récupération du fichier' });
  }
});

module.exports = router;
