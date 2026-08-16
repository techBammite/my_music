const serverless = require('serverless-http');
const app = require('./mail');

module.exports.handler = serverless(app);
