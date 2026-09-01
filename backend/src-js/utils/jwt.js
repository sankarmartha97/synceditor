const jwt = require('jsonwebtoken');
const { config } = require('../config/env');

// Generate JWT token
const generateToken = (payload) => {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
};

// Verify JWT token
const verifyToken = (token) => {
  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    return decoded;
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

// Decode token without verification (for inspection)
const decodeToken = (token) => {
  try {
    return jwt.decode(token);
  } catch (error) {
    return null;
  }
};

module.exports = { generateToken, verifyToken, decodeToken };
