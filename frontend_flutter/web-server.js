/**
 * Serveur Node.js pour le frontend Flutter Web
 * Sert les fichiers statiques du build Flutter
 */

const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 10000;

// Configuration
const FLUTTER_BUILD_PATH = path.join(__dirname, 'build/web');
const API_BASE_URL = process.env.API_BASE_URL || 'https://mykog-backend-api.onrender.com/api';

// Middleware pour CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Middleware pour injecter la configuration API dans les fichiers HTML
app.use((req, res, next) => {
  if (req.path === '/' || req.path.endsWith('.html')) {
    const filePath = path.join(FLUTTER_BUILD_PATH, req.path === '/' ? 'index.html' : req.path);
    
    if (fs.existsSync(filePath)) {
      let content = fs.readFileSync(filePath, 'utf8');
      
      // Injecter la configuration API dans le HTML
      const apiConfig = `
        <script>
          window.API_BASE_URL = '${API_BASE_URL}';
          window.FLUTTER_WEB_CONFIG = {
            apiUrl: '${API_BASE_URL}',
            environment: 'production',
            platform: 'web'
          };
        </script>
      `;
      
      // Injecter avant la fermeture du head
      content = content.replace('</head>', apiConfig + '</head>');
      
      res.setHeader('Content-Type', 'text/html');
      res.send(content);
      return;
    }
  }
  next();
});

// Servir les fichiers statiques Flutter
app.use(express.static(FLUTTER_BUILD_PATH));

// Gérer le routing Flutter (toutes les routes -> index.html)
app.get('*', (req, res) => {
  const indexPath = path.join(FLUTTER_BUILD_PATH, 'index.html');
  
  if (fs.existsSync(indexPath)) {
    let content = fs.readFileSync(indexPath, 'utf8');
    
    // Injecter la configuration API
    const apiConfig = `
      <script>
        window.API_BASE_URL = '${API_BASE_URL}';
        window.FLUTTER_WEB_CONFIG = {
          apiUrl: '${API_BASE_URL}',
          environment: 'production',
          platform: 'web'
        };
      </script>
    `;
    
    content = content.replace('</head>', apiConfig + '</head>');
    
    res.setHeader('Content-Type', 'text/html');
    res.send(content);
  } else {
    res.status(404).send('Flutter build not found. Please run "flutter build web" first.');
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    flutterBuildPath: FLUTTER_BUILD_PATH,
    buildExists: fs.existsSync(FLUTTER_BUILD_PATH),
    apiUrl: API_BASE_URL
  });
});

// Démarrage du serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Serveur frontend Flutter démarré`);
  console.log(`📡 Port: ${PORT}`);
  console.log(`🌐 URL: http://localhost:${PORT}`);
  console.log(`🔗 API Backend: ${API_BASE_URL}`);
  console.log(`📁 Build path: ${FLUTTER_BUILD_PATH}`);
  console.log(`✅ Build exists: ${fs.existsSync(FLUTTER_BUILD_PATH)}`);
  
  // Vérifier si le build Flutter existe
  if (!fs.existsSync(FLUTTER_BUILD_PATH)) {
    console.warn(`⚠️ Attention: Le build Flutter n'existe pas encore!`);
    console.warn(`📝 Lancez: flutter build web`);
  }
});

// Gestion des erreurs
process.on('uncaughtException', (error) => {
  console.error('💥 Erreur non capturée:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('⚠️ Rejet non géré:', reason);
});

module.exports = app;
