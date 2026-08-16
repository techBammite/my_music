require('dotenv').config();
const http = require('http');
const fs = require('fs');
const path = require('path');
const { connectToDatabase } = require('./src/index');

const { ensureDatabaseSchema } = require('./src/backend/routes/checkdb');
const { getAllMusiques, createMusique } = require('./src/backend/routes/musiques');
const { getProfile, deleteMusique } = require('./src/backend/routes/profile');
const { trackDownload } = require('./src/backend/routes/downloads');
const { toggleLike } = require('./src/backend/routes/likes');
const { handleUpload } = require('./src/backend/routes/upload');
const { register, verifyOtp, login } = require('./src/backend/routes/auth');

const hostname = process.env.HOST || '0.0.0.0';
const port = process.env.PORT || 80;
const frontendDir = path.join(__dirname, 'src', 'frontend');
const MAX_JSON_BODY_SIZE = 1024 * 1024 * 100;

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.ogg': 'audio/ogg',
  '.m4a': 'audio/mp4'
};

function sendFile(req, res, filePath, statusCode = 200) {
  const extension = path.extname(filePath).toLowerCase();
  const contentType = mimeTypes[extension] || 'application/octet-stream';

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      send404(res);
      return;
    }

    const range = req.headers.range;
    if (range && (contentType.startsWith('audio/') || contentType.startsWith('video/'))) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : stats.size - 1;

      if (start >= stats.size || end >= stats.size) {
        res.writeHead(416, { 'Content-Range': `bytes */${stats.size}` });
        return res.end();
      }

      const chunksize = end - start + 1;
      const file = fs.createReadStream(filePath, { start, end });
      res.writeHead(206, {
        'Content-Range': `bytes ${start}-${end}/${stats.size}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': chunksize,
        'Content-Type': contentType
      });
      file.pipe(res);
      return;
    }

    res.writeHead(statusCode, {
      'Content-Type': contentType,
      'Content-Length': stats.size
    });
    fs.createReadStream(filePath).pipe(res);
  });
}

function send404(res) {
  res.writeHead(404, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ success: false, error: 'Ressource non trouvée' }));
}

function parseJsonBody(req, callback) {
  let body = '';
  let bodySize = 0;

  req.on('data', (chunk) => {
    bodySize += chunk.length;
    if (bodySize > MAX_JSON_BODY_SIZE) {
      req.destroy();
      return;
    }
    body += chunk.toString();
  });

  req.on('end', () => {
    if (!body) {
      req.body = {};
      return callback(null, {});
    }
    try {
      const parsed = JSON.parse(body);
      req.body = parsed;
      callback(null, parsed);
    } catch (error) {
      callback(error, null);
    }
  });

  req.on('error', (err) => callback(err, null));
}

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Health check endpoint
  if (req.method === 'GET' && (pathname === '/healthz' || pathname === '/health')) {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
    return;
  }

  // Verification du schema de base de donnees
  if (req.method === 'GET' && pathname === '/api/checkdb') {
    ensureDatabaseSchema()
      .then((result) => {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify(result));
      })
      .catch((error) => {
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: error.message }));
      });
    return;
  }

  // Enregistrement, validation OTP & Connexion
  if (req.method === 'POST' && pathname === '/api/auth/register') {
    parseJsonBody(req, (err, body) => {
      if (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        return;
      }
      register(req, res, body);
    });
    return;
  }

  if (req.method === 'POST' && pathname === '/api/auth/verify-otp') {
    parseJsonBody(req, (err, body) => {
      if (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        return;
      }
      verifyOtp(req, res, body);
    });
    return;
  }

  if (req.method === 'POST' && pathname === '/api/auth/login') {
    parseJsonBody(req, (err, body) => {
      if (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        return;
      }
      login(req, res, body);
    });
    return;
  }

  // Upload de fichier
  if (req.method === 'POST' && pathname === '/api/upload') {
    handleUpload(req, res);
    return;
  }

  // Musiques
  if (req.method === 'GET' && pathname === '/api/musiques') {
    getAllMusiques(req, res);
    return;
  }

  if (req.method === 'POST' && pathname === '/api/musiques') {
    parseJsonBody(req, (err, body) => {
      if (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        return;
      }
      createMusique(req, res, body);
    });
    return;
  }

  // Likes
  if (req.method === 'POST' && pathname === '/api/likes') {
    parseJsonBody(req, (err, body) => {
      if (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        return;
      }
      toggleLike(req, res, body);
    });
    return;
  }

  // Telechargements
  if (req.method === 'POST' && pathname === '/api/downloads') {
    parseJsonBody(req, (err, body) => {
      if (err) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'JSON invalide' }));
        return;
      }
      trackDownload(req, res, body);
    });
    return;
  }

  // Profil Utilisateur
  if (req.method === 'GET' && pathname.startsWith('/api/profile/')) {
    const userId = pathname.split('/')[3];
    getProfile(req, res, userId);
    return;
  }

  if (req.method === 'DELETE' && pathname.startsWith('/api/profile/')) {
    const musiqueId = pathname.split('/')[3];
    deleteMusique(req, res, musiqueId);
    return;
  }

  // Fichiers Média Uploads
  if (req.method === 'GET' && pathname.startsWith('/uploads/')) {
    const uploadFilePath = path.join(__dirname, pathname);
    fs.stat(uploadFilePath, (err, stats) => {
      if (!err && stats.isFile()) {
        sendFile(req, res, uploadFilePath);
      } else {
        send404(res);
      }
    });
    return;
  }

  // Service des fichiers statiques du Frontend
  let filePath = path.join(frontendDir, pathname === '/' ? 'index.html' : pathname);

  if (filePath.startsWith(frontendDir) && fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    sendFile(req, res, filePath);
    return;
  }

  send404(res);
});

connectToDatabase()
  .then(async () => {
    try {
      await ensureDatabaseSchema();
      console.log('Base de données RDS initialisée et schéma vérifié avec succès.');
    } catch (schemaErr) {
      console.warn('Erreur lors de l’initialisation du schéma de BDD :', schemaErr.message);
    }
  })
  .catch((error) => {
    console.error('Le serveur continue malgré l’échec de connexion à la base de données.', error.message);
  });

server.listen(port, hostname, () => {
  console.log(`Serveur MyMusic lancé sur http://${hostname}:${port}`);
});
