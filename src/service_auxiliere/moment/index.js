const serverless = require('serverless-http');
const app = require('./moment');

module.exports.handler = serverless(app);
