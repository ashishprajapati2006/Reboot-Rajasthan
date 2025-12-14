const redis = require('redis');
const logger = require('../utils/logger');

// Create Redis client
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
  },
  password: process.env.REDIS_PASSWORD || undefined,
});

// Connect to Redis
redisClient.connect().catch((err) => {
  logger.error(`Redis connection error: ${err.message}`);
  process.exit(-1);
});

// Event listeners
redisClient.on('connect', () => {
  logger.info('Redis connected successfully');
});

redisClient.on('error', (err) => {
  logger.error(`Redis error: ${err.message}`);
});

redisClient.on('ready', () => {
  logger.info('Redis is ready to accept commands');
});

module.exports = redisClient;
