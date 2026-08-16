const http = require('http');

const hostname = process.env.HOST || '0.0.0.0';
const port = process.env.PORT || 80;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <title>MyMusic - Status</title>
      <style>
        body {
          font-family: system-ui, -apple-system, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
          background: #0f172a;
          color: #f8fafc;
        }
        .card {
          background: #1e293b;
          padding: 3rem;
          border-radius: 1rem;
          box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
          text-align: center;
        }
        h1 {
          color: #22c55e;
          font-size: 2.5rem;
          margin-bottom: 1rem;
        }
        p {
          color: #94a3b8;
          font-size: 1.2rem;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>✅ Application fonctionnelle</h1>
        <p>Le serveur MyMusic Node.js est en ligne et répond parfaitement !</p>
      </div>
    </body>
    </html>
  `);
});

server.listen(port, hostname, () => {
  console.log(`Serveur de test lancé sur http://${hostname}:${port}`);
});
