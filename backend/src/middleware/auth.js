const jwt = require('jsonwebtoken');
const db = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

function generateToken(user) {
  return jwt.sign(
    {
      id: user.id,
      merchant_id: user.merchant_id,
      role: user.role,
    },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

function authenticate(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const token = header.slice(7);
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.prepare('SELECT id, merchant_id, email, name, role FROM users WHERE id = ? AND is_active = 1').get(decoded.id);
    if (!user) {
      return res.status(401).json({ error: 'User not found or inactive' });
    }
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

function checkSubscription(req, res, next) {
  const merchant = db.prepare('SELECT subscription_status, trial_ends_at FROM merchants WHERE id = ?').get(req.user.merchant_id);
  if (!merchant) {
    return res.status(403).json({ error: 'Merchant not found' });
  }

  if (merchant.subscription_status === 'active') {
    return next();
  }

  if (merchant.subscription_status === 'trial') {
    const trialEnd = new Date(merchant.trial_ends_at);
    if (trialEnd > new Date()) {
      return next();
    }
    return res.status(403).json({ error: 'Trial expired. Please subscribe to continue.' });
  }

  return res.status(403).json({ error: 'Subscription required. Please subscribe to continue.' });
}

module.exports = { generateToken, authenticate, requireAdmin, checkSubscription };
