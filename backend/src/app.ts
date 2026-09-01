import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config/env';
import { errorHandler, notFoundHandler } from './middleware/error.middleware';

// Create Express app
const app: Application = express();

// ============================================
// MIDDLEWARE
// ============================================

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable for development
  crossOriginEmbedderPolicy: false,
}));

// CORS configuration
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    if (config.cors.allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
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
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv,
  });
});

// API status endpoint
app.get('/api', (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Canvas Editor API v2.0',
    version: '2.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      pages: '/api/pages', // New page-based API
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
import authRoutes from './routes/auth.routes';
import canvasRoutes from './routes/canvas.routes';
import pageRoutes from './routes/page.routes';

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/canvases', canvasRoutes); // Legacy - keep for backward compatibility
app.use('/api/pages', pageRoutes); // New page-based API

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

export default app;
