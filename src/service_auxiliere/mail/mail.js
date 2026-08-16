const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const nodemailer = require('nodemailer');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 4001;

// CORS open headers for public access
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'mail', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'mail', message: 'Microservice Mail Lambda fonctionnel !' });
});

app.post('/send', async (req, res) => {
  try {
    const { to, subject, text, html } = req.body;

    if (!to || !subject || (!text && !html)) {
      return res.status(400).json({ error: 'Paramètres invalides. "to", "subject" et ("text" ou "html") sont requis.' });
    }

    const smtpPort = Number(process.env.SMTP_PORT || 465);
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.hostinger.com',
      port: smtpPort,
      secure: smtpPort === 465,
      auth: {
        user: process.env.SMTP_USERNAME || 'my_musique@bammite.com',
        pass: process.env.SMTP_PASSWORD || 'Aws_cour.isi.2026'
      }
    });

    const fromName = process.env.SMTP_FROM_NAME || 'My musique';
    const fromEmail = process.env.SMTP_FROM_EMAIL || 'my_musique@bammite.com';

    const info = await transporter.sendMail({
      from: `"${fromName}" <${fromEmail}>`,
      to,
      subject,
      text,
      html
    });

    res.status(200).json({ success: true, message: 'Email envoyé avec succès', messageId: info.messageId });
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email:', error);
    res.status(500).json({ error: 'Échec d’envoi de l’email', details: error.message });
  }
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Microservice mail démarré sur le port ${PORT}`);
  });
}

module.exports = app;
