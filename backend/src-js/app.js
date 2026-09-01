const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { config } = require('./config/env');
const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');

// Create Express app
const app = express();

// ============================================
// MIDDLEWARE
// ============================================

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable for development
  crossOriginEmbedderPolicy: false,
}));

// CORS configuration - Allow all origins in development
app.use(cors({
  origin: '*', // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  exposedHeaders: ['Content-Type', 'Authorization'],
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// ============================================
// ROUTES
// ============================================

// Health check endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv,
  });
});

// API status endpoint
app.get('/api', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Canvas Editor API v2.0',
    version: '2.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      pages: '/api/pages', // New page-based API
      comments: '/api/pages/:pageId/comments', // Comments & Annotations
      mentions: '/api/users/me/mentions', // User mentions
      canvases: '/api/canvases', // Legacy (deprecated)
      widgets: '/api/canvases/:id/widgets', // Legacy (deprecated)
    },
    note: 'Page-based API is the new standard. Canvas API is deprecated.',
  });
});

// ============================================
// API ROUTES
// ============================================

// Import routes
const authRoutes = require('./routes/auth.routes');
const canvasRoutes = require('./routes/canvas.routes');
const pageRoutes = require('./routes/page.routes');
const commentsRoutes = require('./routes/comments.routes');

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/canvases', canvasRoutes); // Legacy - keep for backward compatibility
app.use('/api/pages', pageRoutes); // New page-based API
app.use('/api', commentsRoutes); // Comments API (supports both /api/pages/:pageId/comments and /api/comments/:id)

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;
