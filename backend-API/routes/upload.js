const express = require('express');
const { PutObjectCommand } = require('@aws-sdk/client-s3');
const storage = require('../services/storageService');
const { upload } = require('../middleware/upload');

const router = express.Router();
const BUCKET = process.env.AWS_BUCKET_NAME || process.env.B2_BUCKET || 'kog-blackblaze';

function generateTimestampId() {
  return `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
}

router.post('/', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni (champ "file")' });
    }

    const ext = req.file.originalname.split('.').pop() || 'bin';
    const mimetype = req.file.mimetype || '';
    const prefix = mimetype.startsWith('image/')
      ? 'images'
      : mimetype.startsWith('audio/')
        ? 'audios'
        : mimetype.startsWith('video/')
          ? 'videos'
          : 'files';
    const key = `${prefix}/${generateTimestampId()}.${ext}`;

    const command = new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
    });

    await storage.getClient().send(command);

    res.status(201).json({
      key,
      bucket: BUCKET,
      provider: storage.provider,
      size: req.file.size,
      contentType: req.file.mimetype,
    });
  } catch (err) {
    console.error('❌ Erreur upload:', err.message);
    res.status(500).json({ error: 'Erreur upload', details: err.message });
  }
});

module.exports = router;