const mysql = require('mysql2/promise');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

let pool = null;

async function getDbCredentials() {
  if (process.env.DB_SECRET_ARN) {
    try {
      const client = new SecretsManagerClient({ region: process.env.AWS_REGION || 'eu-west-3' });
      const response = await client.send(new GetSecretValueCommand({ SecretId: process.env.DB_SECRET_ARN }));
      if (response.SecretString) {
        const creds = JSON.parse(response.SecretString);
        return {
          host: creds.host || process.env.DB_HOST || 'localhost',
          port: Number(creds.port || process.env.DB_PORT || 3306),
          user: creds.username || creds.user || process.env.DB_USER || 'root',
          password: creds.password || process.env.DB_PASSWORD || '',
          database: creds.dbname || creds.database || process.env.DB_NAME || 'my_music'
        };
      }
    } catch (err) {
      console.warn('Fallback aux variables d\'environnement locales pour la BDD:', err.message);
    }
  }

  return {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'my_music'
  };
}

async function connectToDatabase() {
  if (pool) {
    return pool;
  }

  const creds = await getDbCredentials();

  const config = {
    host: creds.host,
    port: creds.port,
    user: creds.user,
    password: creds.password,
    database: creds.database,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    maxAllowedPacket: 1024 * 1024 * 64,
    connectTimeout: 60000,
    enableKeepAlive: true
  };

  try {
    pool = mysql.createPool(config);
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();

    console.log(`Connexion à la base de données réussie sur ${config.host}:${config.port}/${config.database}`);
    return pool;
  } catch (error) {
    console.error('Échec de la connexion à la base de données :', error.message);
    throw error;
  }
}

async function closeDatabaseConnection() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

module.exports = {
  connectToDatabase,
  closeDatabaseConnection
};
