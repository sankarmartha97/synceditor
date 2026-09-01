const Redis = require('ioredis');
const dotenv = require('dotenv');

dotenv.config();

// Redis configuration
const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  },
  maxRetriesPerRequest: 3,
};

// Create Redis client
const redis = new Redis(redisConfig);

// Redis event handlers
redis.on('connect', () => {
  console.log('✅ Redis connected successfully');
});

redis.on('error', (err) => {
  console.error('❌ Redis connection error:', err);
});

redis.on('ready', () => {
  console.log('📦 Redis is ready to accept commands');
});

redis.on('close', () => {
  console.log('📦 Redis connection closed');
});

// Test Redis connection
const testRedisConnection = async () => {
  try {
    await redis.ping();
    console.log('✅ Redis ping successful');
    return true;
  } catch (error) {
    console.error('❌ Redis ping failed:', error);
    return false;
  }
};

// Graceful shutdown
const closeRedis = async () => {
  try {
    await redis.quit();
    console.log('📦 Redis connection closed gracefully');
  } catch (error) {
    console.error('Error closing Redis connection:', error);
  }
};

module.exports = { redis, testRedisConnection, closeRedis };
