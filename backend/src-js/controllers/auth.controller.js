const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const { pool } = require('../config/database');
const { generateToken } = require('../utils/jwt');
const { AppError, asyncHandler } = require('../middleware/error.middleware');
const { successResponse } = require('../utils/response');

// Register new user
const register = asyncHandler(
  async (req, res, next) => {
    const { email, password, name } = req.body;

    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      throw new AppError('User with this email already exists', 400);
    }

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const userId = uuidv4();
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, name) 
       VALUES ($1, $2, $3, $4) 
       RETURNING id, email, name, created_at`,
      [userId, email, passwordHash, name]
    );

    const user = result.rows[0];

    // Generate token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    successResponse(
      res,
      {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          createdAt: user.created_at,
        },
        token,
      },
      'User registered successfully',
      201
    );
  }
);

// Login user
const login = asyncHandler(
  async (req, res, next) => {
    const { email, password } = req.body;

    // Find user
    const result = await pool.query(
      'SELECT id, email, password_hash, name, avatar_url FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      throw new AppError('Invalid email or password', 401);
    }

    const user = result.rows[0];

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      throw new AppError('Invalid email or password', 401);
    }

    // Generate token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    successResponse(res, {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatar_url,
      },
      token,
    }, 'Login successful');
  }
);

// Get current user
const getCurrentUser = asyncHandler(
  async (req, res, next) => {
    const userId = req.user?.userId;

    if (!userId) {
      throw new AppError('User not authenticated', 401);
    }

    // Get user from database
    const result = await pool.query(
      'SELECT id, email, name, avatar_url, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      throw new AppError('User not found', 404);
    }

    const user = result.rows[0];

    successResponse(res, {
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatar_url,
      createdAt: user.created_at,
    }, 'User retrieved successfully');
  }
);

// Logout user (client-side token removal, but we can add token blacklist here)
const logout = asyncHandler(
  async (req, res, next) => {
    // In a more advanced implementation, you would:
    // 1. Add token to Redis blacklist
    // 2. Set expiry on blacklist entry
    
    successResponse(res, null, 'Logout successful');
  }
);

module.exports = { register, login, getCurrentUser, logout };
