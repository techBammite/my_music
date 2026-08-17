const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const mysql = require('mysql2/promise');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const app = express();
const PORT = process.env.PORT || 4002;
const uploadDir = process.env.UPLOAD_DIR || (process.env.AWS_LAMBDA_FUNCTION_NAME ? '/tmp' : path.join(__dirname, 'uploads'));
const baseUrl = process.env.BASE_URL || `http://127.0.0.1:${PORT}`;

app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ extended: true, limit: '100mb' }));

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');

  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }
  next();
});

if (!fs.existsSync(uploadDir)) {
  try { fs.mkdirSync(uploadDir, { recursive: true }); } catch (e) {}
}

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 100 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/ogg', 'audio/mp4', 'video/mp4'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé'));
    }
  }
});

async function getDbConnection() {
  if (!process.env.DB_HOST) return null;
  return mysql.createConnection({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'mymusic_admin',
    password: process.env.DB_PASSWORD || 'MyMusicPassword2026!',
    database: process.env.DB_NAME || 'my_music',
    connectTimeout: 5000
  });
}

app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'upload', lambda: !!process.env.AWS_LAMBDA_FUNCTION_NAME });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'upload' });
});

// Endpoint principal d'upload avec insertion BDD directe facultative
app.post(['/upload', '/api/upload'], upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'Aucun fichier reçu' });
    }

    const ext = path.extname(req.file.originalname) || (req.file.mimetype.startsWith('image/') ? '.jpg' : '.mp3');
    const uniqueFileName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
    let filePublicUrl = '';

    // Si S3 est configure, uploader directement sur S3
    if (process.env.MEDIA_S3_BUCKET) {
      const s3 = new S3Client({ region: process.env.AWS_REGION || 'eu-west-3' });
      await s3.send(new PutObjectCommand({
        Bucket: process.env.MEDIA_S3_BUCKET,
        Key: `uploads/${uniqueFileName}`,
        Body: req.file.buffer,
        ContentType: req.file.mimetype
      }));
      filePublicUrl = `https://${process.env.MEDIA_S3_BUCKET}.s3.${process.env.AWS_REGION || 'eu-west-3'}.amazonaws.com/uploads/${uniqueFileName}`;
    } else {
      // Sinon sauver localement
      const filePath = path.join(uploadDir, uniqueFileName);
      fs.writeFileSync(filePath, req.file.buffer);
      filePublicUrl = `/uploads/${uniqueFileName}`;
    }

    // Optionnel: Si des parametres musique sont passes (title, artist), enregistrer directement en BDD RDS
    let dbInsertId = null;
    if (req.body && req.body.title && req.body.artist) {
      try {
        const conn = await getDbConnection();
        if (conn) {
          const [result] = await conn.query(
            `INSERT INTO musiques (title, artist, cover_url, audio_url, genre, description, user_id, statut, deleted, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, 'actif', FALSE, NOW(), NOW())`,
            [req.body.title, req.body.artist, req.body.cover || null, filePublicUrl, req.body.genre || null, req.body.description || null, req.body.user_id || null]
          );
          dbInsertId = result.insertId;
          await conn.end();
        }
      } catch (dbErr) {
        console.warn('DB Insert Warning in Upload Service:', dbErr.message);
      }
    }

    res.status(200).json({
      success: true,
      fileName: uniqueFileName,
      path: `/uploads/${uniqueFileName}`,
      url: filePublicUrl,
      dbInsertId: dbInsertId,
      size: req.file.size,
      mimeType: req.file.mimetype
    });

  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.use('/uploads', express.static(uploadDir));

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Microservice upload démarré sur le port ${PORT}`);
  });
}

module.exports = app;
