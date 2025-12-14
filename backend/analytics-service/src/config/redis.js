const redis = require('redis');
const logger = require('../utils/logger');

const client = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
  socket: {
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        logger.error('Redis reconnection failed after 10 attempts');
        return new Error('Redis reconnection limit exceeded');
      }
      return retries * 100;
    }
  }
});

client.on('connect', () => {
  logger.info('Redis connected');
});

client.on('error', (err) => {
  logger.error('Redis error:', err);
});

client.connect().catch(err => {
  logger.error('Failed to connect to Redis:', err);
});

module.exports = client;
