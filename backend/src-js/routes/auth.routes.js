const { Router } = require('express');
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

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', validateRequest(registerSchema), register);

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', validateRequest(loginSchema), login);

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
