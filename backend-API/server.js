require("dotenv").config();
const express = require("express");
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const Veilleur = require("./veilleur");
const { startStreamingServer } = require("./services/streamingService");

const app = express();
const PORT = process.env.PORT || 3000;

// --- MIDDLEWARES ---
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir les fichiers statiques (dashboard admin)
app.use(express.static('public'));

// Servir les fichiers HLS générés par FFmpeg (hls_output/<streamKey>/index.m3u8)
app.use('/hls', express.static(path.join(__dirname, 'hls_output')));

// --- ROUTES ---
app.use("/api/enseignements", require("./routes/enseignements"));
app.use("/api/annonces", require("./routes/annonces"));
app.use("/api/lives", require("./routes/lives"));
app.use("/api/calendar", require("./routes/calendar"));
app.use("/api/users", require("./routes/users"));
app.use("/api/notifications", require("./routes/notifications"));
app.use("/api/text-resumes", require("./routes/textResumes"));
app.use("/api/stream", require("./routes/stream"));

// --- ROUTE DE TEST ---
app.get("/", (req, res) => {
  res.json({ message: "Serveur Enseignement API opérationnel 🚀" });
});

// --- GESTION DES ERREURS (UPLOAD / AUTRE) ---
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ error: "Fichier trop volumineux" });
    }
  }

  res.status(500).json({
    error: "Erreur interne du serveur",
    details: error.message,
  });
});

// --- DEMARRAGE SERVEUR ---
app.listen(PORT, () => {
  console.log(`🚀 Serveur lancé sur le port ${PORT}`);
  console.log("👉 Ouvre ton navigateur et teste /api/enseignements ou /api/lives");

  // Démarrer le serveur de streaming RTMP/HLS (port 1935 / HTTP 8000)
  try {
    startStreamingServer();
  } catch (error) {
    console.error("❌ Erreur démarrage serveur RTMP:", error.message);
  }

  // Démarrer le veilleur uniquement en production
  if (process.env.NODE_ENV === 'production') {
    console.log("🌐 Serveur déployé sur Render");
    const veilleur = new Veilleur(14); // Ping toutes les 14 minutes
    veilleur.start();
  } else {
    console.log("📱 Pour téléphone : utilise l'IP du PC + :3000");
  }
});
