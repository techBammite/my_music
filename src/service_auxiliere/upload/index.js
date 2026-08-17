const serverless = require('serverless-http');
const app = require('./upload');

module.exports.handler = serverless(app, {
  binary: ['*/*', 'multipart/form-data', 'audio/*', 'image/*']
});
