const { Router } = require('express');
const rateLimit = require('express-rate-limit');
const {
  register,
  login,
  getCurrentUser,
  logout,
} = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth.middleware');
const {
  validateRequest,
  registerSchema,
  loginSchema,
} = require('../middleware/validation.middleware');

const router = Router();

// Brute-force protection: 10 attempts per 15 minutes per IP
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many attempts, please try again later.',
  },
});

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', authLimiter, validateRequest(registerSchema), register);

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', authLimiter, validateRequest(loginSchema), login);

/**
 * @route   GET /api/auth/me
 * @desc    Get current user
 * @access  Private
 */
router.get('/me', authMiddleware, getCurrentUser);

/**
 * @route   POST /api/auth/logout
 * @desc    Logout user
 * @access  Private
 */
router.post('/logout', authMiddleware, logout);

module.exports = router;
