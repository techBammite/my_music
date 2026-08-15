const Busboy = require('busboy');
const fs = require('fs');
const path = require('path');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const uploadDir = path.join(__dirname, '..', '..', '..', 'uploads');

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

function handleUpload(req, res) {
  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ success: false, error: 'Méthode non autorisée' }));
    return;
  }

  let busboy;
  try {
    busboy = Busboy({ headers: req.headers });
  } catch (error) {
    res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ success: false, error: 'Entêtes multipart invalides' }));
    return;
  }

  let fileSaved = false;
  let filename = '';
  let writeError = null;
  let uploadPromise = Promise.resolve();

  busboy.on('file', (name, file, info) => {
    const { filename: originalName, mimeType } = info;
    const allowedTypes = [
      'image/jpeg', 'image/png', 'image/webp', 'image/jpg', 
      'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 
      'audio/ogg', 'audio/mp4', 'video/mp4'
    ];

    if (!allowedTypes.includes(mimeType)) {
      file.resume();
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: 'Type de fichier non autorisé' }));
      return;
    }

    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    filename = uniqueSuffix + path.extname(originalName);

    const bucketName = process.env.AWS_S3_BUCKET;

    if (bucketName) {
      // Stream vers S3
      const chunks = [];
      file.on('data', (chunk) => chunks.push(chunk));
      
      uploadPromise = new Promise((resolve) => {
        file.on('end', async () => {
          try {
            const buffer = Buffer.concat(chunks);
            const s3Client = new S3Client({ region: process.env.AWS_REGION || 'eu-west-3' });
            await s3Client.send(new PutObjectCommand({
              Bucket: bucketName,
              Key: `uploads/${filename}`,
              Body: buffer,
              ContentType: mimeType
            }));
            fileSaved = true;
            resolve();
          } catch (err) {
            writeError = err;
            resolve();
          }
        });
      });
    } else {
      // Stockage local
      const saveTo = path.join(uploadDir, filename);
      const fstream = fs.createWriteStream(saveTo);
      file.pipe(fstream);

      fstream.on('error', (err) => {
        writeError = err;
      });

      fileSaved = true;
    }
  });

  busboy.on('error', (err) => {
    res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ success: false, error: err.message }));
  });

  busboy.on('finish', async () => {
    await uploadPromise;

    if (res.writableEnded) return;

    if (writeError) {
      res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: 'Erreur lors de la sauvegarde du fichier : ' + writeError.message }));
      return;
    }

    if (fileSaved) {
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        success: true,
        fileName: filename,
        path: `/uploads/${filename}`,
        url: `/uploads/${filename}`
      }));
    } else {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: 'Aucun fichier reçu' }));
    }
  });

  req.pipe(busboy);
}

module.exports = {
  handleUpload
};
