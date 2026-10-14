const express = require('express');
const router = express.Router();
const { ListObjectsV2Command } = require('@aws-sdk/client-s3');
const s3 = require('../services/s3Service');
const storage = require('../services/storageService');

const BUCKET = process.env.AWS_BUCKET_NAME;
const REGION = process.env.AWS_REGION || 'eu-north-1';
// Quota de référence (AWS Free Tier = 5 GB). Modifiable via STORAGE_QUOTA_GB.
const QUOTA_GB = parseFloat(process.env.STORAGE_QUOTA_GB || '5');

/**
 * @openapi
 * /api/storage/stats:
 *   get:
 *     summary: Statistiques d'utilisation du stockage cloud (S3)
 *     tags: [Storage]
 */
router.get('/stats', async (req, res) => {
  try {
    if (storage.provider !== 's3' || !BUCKET) {
      return res.json({
        provider: storage.provider,
        configured: false,
        message: 'Stockage S3 non configuré (provider actif: ' + storage.provider + ')',
      });
    }

    const client = s3.getClient();
    let totalBytes = 0;
    let objectCount = 0;
    const breakdown = {};
    let token;

    do {
      const out = await client.send(new ListObjectsV2Command({
        Bucket: BUCKET,
        ContinuationToken: token,
        MaxKeys: 1000,
      }));
      for (const obj of out.Contents || []) {
        totalBytes += obj.Size || 0;
        objectCount++;
        const prefix = (obj.Key || '').split('/')[0] || 'racine';
        if (!breakdown[prefix]) breakdown[prefix] = { bytes: 0, count: 0 };
        breakdown[prefix].bytes += obj.Size || 0;
        breakdown[prefix].count++;
      }
      token = out.IsTruncated ? out.NextContinuationToken : undefined;
    } while (token);

    const quotaBytes = QUOTA_GB * 1024 * 1024 * 1024;
    res.json({
      provider: 's3',
      configured: true,
      bucket: BUCKET,
      region: REGION,
      objectCount,
      totalBytes,
      totalMB: +(totalBytes / 1048576).toFixed(2),
      totalGB: +(totalBytes / 1073741824).toFixed(4),
      quotaGB: QUOTA_GB,
      quotaBytes,
      remainingBytes: Math.max(0, quotaBytes - totalBytes),
      remainingGB: +(Math.max(0, quotaBytes - totalBytes) / 1073741824).toFixed(4),
      usagePercent: +((totalBytes / quotaBytes) * 100).toFixed(2),
      breakdown,
      note: 'S3 n\'a pas de limite fixe — le quota affiché est une référence (Free Tier). La facturation dépend de l\'usage réel.',
    });
  } catch (err) {
    console.error('Erreur storage stats:', err.message);
    res.status(500).json({ error: 'Erreur lors du calcul du stockage', details: err.message });
  }
});

module.exports = router;
