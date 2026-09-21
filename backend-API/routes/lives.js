const express = require('express');
const router = express.Router();
const {
  createLiveStream,
  getAllLiveStreams,
  getLiveStreamById,
  getActiveLive,
  getServerInfo,
  updateLiveStream,
  updateLiveStreamStatus,
  incrementViewerCount,
  decrementViewerCount,
  getViewerCount,
  deleteLiveStream,
  deleteAllLiveStreams,
} = require('../controllers/liveController');

/**
 * @openapi
 * /api/lives:
 *   get:
 *     summary: Récupérer tous les lives
 *     tags: [Lives]
 *     responses:
 *       200:
 *         description: Liste des lives
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LiveStream'
 */
router.get('/', getAllLiveStreams);

/**
 * @openapi
 * /api/lives/active:
 *   get:
 *     summary: Récupérer le live actuellement actif
 *     tags: [Lives]
 *     responses:
 *       200:
 *         description: Live actif
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LiveStream'
 */
router.get('/active', getActiveLive);

/**
 * @openapi
 * /api/lives/server-info:
 *   get:
 *     summary: Obtenir les informations du serveur de streaming
 *     tags: [Lives]
 *     responses:
 *       200:
 *         description: Informations du serveur
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ipAddress:
 *                   type: string
 *                 serverUrl:
 *                   type: string
 */
router.get('/server-info', getServerInfo);

/**
 * @openapi
 * /api/lives/{id}/viewers:
 *   get:
 *     summary: Obtenir le nombre de viewers
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Nombre de viewers
 */
router.get('/:id/viewers', getViewerCount);

/**
 * @openapi
 * /api/lives/{id}:
 *   get:
 *     summary: Récupérer un live par ID
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Live trouvé
 */
router.get('/:id', getLiveStreamById);

/**
 * @openapi
 * /api/lives:
 *   post:
 *     summary: Créer un nouveau live
 *     tags: [Lives]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               streamUrl:
 *                 type: string
 *               thumbnailUrl:
 *                 type: string
 *               scheduledAt:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       201:
 *         description: Live créé
 */
router.post('/', createLiveStream);

/**
 * @openapi
 * /api/lives/{id}:
 *   put:
 *     summary: Mettre à jour un live
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LiveStream'
 *     responses:
 *       200:
 *         description: Live mis à jour
 */
router.put('/:id', updateLiveStream);

/**
 * @openapi
 * /api/lives/{id}/status:
 *   put:
 *     summary: Mettre à jour le statut d'un live
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [scheduled, live, ended]
 *     responses:
 *       200:
 *         description: Statut mis à jour
 */
router.put('/:id/status', updateLiveStreamStatus);

/**
 * @openapi
 * /api/lives/{id}/join:
 *   post:
 *     summary: Rejoindre un live (incrémente le compteur)
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Viewer ajouté
 */
router.post('/:id/join', incrementViewerCount);

/**
 * @openapi
 * /api/lives/{id}/leave:
 *   post:
 *     summary: Quitter un live (décrémente le compteur)
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Viewer retiré
 */
router.post('/:id/leave', decrementViewerCount);

/**
 * @openapi
 * /api/lives/{id}:
 *   delete:
 *     summary: Supprimer un live
 *     tags: [Lives]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Live supprimé
 */
router.delete('/:id', deleteLiveStream);

/**
 * @openapi
 * /api/lives:
 *   delete:
 *     summary: Supprimer tous les lives
 *     tags: [Lives]
 *     responses:
 *       200:
 *         description: Tous les lives supprimés
 */
router.delete('/', deleteAllLiveStreams);

module.exports = router;
