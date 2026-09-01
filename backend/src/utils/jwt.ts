import jwt from 'jsonwebtoken';
import { config } from '../config/env';

interface JWTPayload {
  userId: string;
  email: string;
}

// Generate JWT token
export const generateToken = (payload: JWTPayload): string => {
  return jwt.sign(payload, config.jwt.secret as any, {
    expiresIn: config.jwt.expiresIn,
  } as any);
};

// Verify JWT token
export const verifyToken = (token: string): JWTPayload => {
  try {
    const decoded = jwt.verify(token, config.jwt.secret as any) as JWTPayload;
    return decoded;
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

// Decode token without verification (for inspection)
export const decodeToken = (token: string): JWTPayload | null => {
  try {
    return jwt.decode(token) as JWTPayload;
  } catch (error) {
    return null;
  }
};
