const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const os = require('os');
const {
  createTextResume,
  getAllTextResumes,
  getTextResumeById,
  updateTextResume,
  deleteTextResume,
  deleteAllTextResumes,
  deleteTextResumesByFilter,
} = require('../controllers/textResumeController');

// Configuration Multer pour l'upload de fichiers
const uploadDir = path.join(os.tmpdir(), 'mykog-textresumes');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = file.fieldname === 'pdf' ? '.pdf' : '.jpg';
    cb(null, `${file.fieldname}_${uniqueSuffix}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB max pour les PDFs
  },
  fileFilter: (req, file, cb) => {
    // Accepter les PDFs et les images
    if (file.fieldname === 'pdf' && file.mimetype === 'application/pdf') {
      cb(null, true);
    } else if (file.fieldname === 'image' && file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non supporté'), false);
    }
  },
});

// Routes
router.post(
  '/',
  upload.fields([
    { name: 'pdf', maxCount: 1 },
    { name: 'image', maxCount: 1 },
  ]),
  createTextResume
);

router.get('/', getAllTextResumes);
router.get('/:id', getTextResumeById);

router.put(
  '/:id',
  upload.fields([
    { name: 'pdf', maxCount: 1 },
    { name: 'image', maxCount: 1 },
  ]),
  updateTextResume
);

router.delete('/batch', deleteTextResumesByFilter);
router.delete('/all', deleteAllTextResumes);
router.delete('/:id', deleteTextResume);

module.exports = router;

