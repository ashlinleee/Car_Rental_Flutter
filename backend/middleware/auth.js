/**
 * auth.js — JWT authentication middleware.
 *
 * Exports:
 *   signToken(userId)  — Creates a signed JWT for the given user ID (valid 30 days).
 *   protect            — Express middleware that validates the Bearer token,
 *                        looks up the user in the database, and attaches the user
 *                        document to req.user for downstream route handlers.
 *                        Responds 401 on missing, invalid, or expired tokens.
 */
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Use a strong secret from environment; the fallback is only for local dev
const JWT_SECRET = process.env.JWT_SECRET || 'car_rental_jwt_secret_change_in_production';
const JWT_EXPIRES_IN = '30d';

/** Signs and returns a JWT containing the user's MongoDB ObjectId. */
function signToken(userId) {
  return jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

/**
 * Express middleware that enforces authentication.
 * Reads the "Authorization: Bearer <token>" header, verifies the JWT,
 * fetches the corresponding user, and attaches it to req.user.
 */
async function protect(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
  }
  const token = auth.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({ success: false, message: 'User no longer exists.' });
    }
    req.user = user;
    next();
  } catch {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
}

module.exports = { signToken, protect };
