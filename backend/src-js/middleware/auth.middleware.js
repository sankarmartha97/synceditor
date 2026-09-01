const { verifyToken } = require('../utils/jwt');
const { AppError } = require('./error.middleware');

// Authentication middleware
const authMiddleware = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No token provided', 401);
    }
    
    const token = authHeader.split(' ')[1];
    
    if (!token) {
      throw new AppError('Invalid token format', 401);
    }
    
    // Verify token
    const decoded = verifyToken(token);
    
    // Attach user to request
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
    };
    
    next();
  } catch (error) {
    if (error instanceof AppError) {
      next(error);
    } else {
      next(new AppError('Authentication failed', 401));
    }
  }
};

// Optional authentication middleware (doesn't fail if no token)
const optionalAuthMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = verifyToken(token);
      
      req.user = {
        userId: decoded.userId,
        email: decoded.email,
      };
    }
    
    next();
  } catch (error) {
    // Continue without user
    next();
  }
};

module.exports = { authMiddleware, optionalAuthMiddleware };
