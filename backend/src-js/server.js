const { createServer } = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const { config, validateEnv } = require('./config/env');
const { testConnection, closePool } = require('./config/database');
const { testRedisConnection, closeRedis } = require('./config/redis');
const { setupSocketHandlers } = require('./websocket/socket.handler');

// Validate environment variables
validateEnv();

// Create HTTP server
const httpServer = createServer(app);

// Create Socket.io instance
const io = new Server(httpServer, {
  cors: {
    origin: config.cors.allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
});

// Setup Socket.io handlers
setupSocketHandlers(io);

// Start server
const startServer = async () => {
  try {
    // Test database connection
    console.log('📊 Testing database connection...');
    const dbConnected = await testConnection();
    if (!dbConnected) {
      throw new Error('Database connection failed');
    }

    // Test Redis connection
    console.log('📦 Testing Redis connection...');
    const redisConnected = await testRedisConnection();
    if (!redisConnected) {
      console.warn('⚠️  Redis connection failed, continuing without cache');
    }

    // Start HTTP server
    httpServer.listen(config.port, () => {
      console.log('\n' + '='.repeat(50));
      console.log('🚀 Canvas Editor Backend Server');
      console.log('='.repeat(50));
      console.log(`📝 Environment: ${config.nodeEnv}`);
      console.log(`🌐 Server running on: http://localhost:${config.port}`);
      console.log(`📡 WebSocket ready on: ws://localhost:${config.port}`);
      console.log(`🔗 Health check: http://localhost:${config.port}/health`);
      console.log(`📚 API docs: http://localhost:${config.port}/api`);
      console.log('='.repeat(50) + '\n');
    });

  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
const gracefulShutdown = async (signal) => {
  console.log(`\n⚠️  ${signal} received, shutting down gracefully...`);
  
  // Close HTTP server
  httpServer.close(async () => {
    console.log('🛑 HTTP server closed');
    
    // Close Socket.io
    io.close(() => {
      console.log('🔌 Socket.io closed');
    });
    
    // Close database pool
    await closePool();
    
    // Close Redis connection
    await closeRedis();
    
    console.log('✅ Graceful shutdown complete');
    process.exit(0);
  });
  
  // Force close after 10 seconds
  setTimeout(() => {
    console.error('⚠️  Forcing shutdown after timeout');
    process.exit(1);
  }, 10000);
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('UNHANDLED_REJECTION');
});

// Start the server
startServer();
