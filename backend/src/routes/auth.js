const express = require('express');
const router = express.Router();
const db = require('../config/database');
const User = require('../models/User');
const { generateToken, authenticate, requireAdmin } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');

// POST /api/auth/register - Register new merchant + admin account
router.post('/register', (req, res) => {
  try {
    const { merchantName, email, password, name } = req.body;

    if (!merchantName || !email || !password || !name) {
      return res.status(400).json({ error: 'All fields are required: merchantName, email, password, name' });
    }

    // Check if email already exists
    const existing = User.findByEmailGlobal(email);
    if (existing) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Create merchant
    const merchantId = uuidv4();
    db.prepare(`
      INSERT INTO merchants (id, name, subscription_status, trial_ends_at)
      VALUES (?, ?, 'trial', datetime('now', '+30 days'))
    `).run(merchantId, merchantName);

    // Initialize order sequence
    db.prepare('INSERT INTO order_sequence (merchant_id, current_number) VALUES (?, 0)').run(merchantId);

    // Create admin user
    const user = User.create({
      merchantId,
      email,
      password,
      name,
      role: 'admin',
    });

    const token = generateToken(user);

    res.status(201).json({
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
      merchant: { id: merchantId, name: merchantName },
      token,
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login - Login with email/password
router.post('/login', (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = User.findByEmailGlobal(email);
    if (!user || !user.is_active) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    if (!User.verifyPassword(user, password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const merchant = db.prepare('SELECT id, name, subscription_status, trial_ends_at FROM merchants WHERE id = ?').get(user.merchant_id);
    const token = generateToken(user);

    res.json({
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
      merchant,
      token,
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// POST /api/auth/pin-login - Quick login with PIN (for POS register)
router.post('/pin-login', (req, res) => {
  try {
    const { merchantId, pin } = req.body;

    if (!merchantId || !pin) {
      return res.status(400).json({ error: 'Merchant ID and PIN are required' });
    }

    const user = User.findByPin(merchantId, pin);
    if (!user) {
      return res.status(401).json({ error: 'Invalid PIN' });
    }

    const token = generateToken(user);

    res.json({
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
      token,
    });
  } catch (err) {
    console.error('PIN login error:', err);
    res.status(500).json({ error: 'PIN login failed' });
  }
});

// GET /api/auth/me - Get current user
router.get('/me', authenticate, (req, res) => {
  const merchant = db.prepare('SELECT id, name, subscription_status, trial_ends_at FROM merchants WHERE id = ?').get(req.user.merchant_id);
  res.json({ user: req.user, merchant });
});

// Staff management (admin only)

// POST /api/auth/users - Create staff user
router.post('/users', authenticate, requireAdmin, (req, res) => {
  try {
    const { email, password, name, role, pin } = req.body;

    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' });
    }

    const validRoles = ['staff', 'admin'];
    const userRole = validRoles.includes(role) ? role : 'staff';

    const existing = User.findByEmail(req.user.merchant_id, email);
    if (existing) {
      return res.status(409).json({ error: 'Email already exists for this merchant' });
    }

    const user = User.create({
      merchantId: req.user.merchant_id,
      email,
      password,
      name,
      role: userRole,
      pin,
    });

    res.status(201).json(user);
  } catch (err) {
    console.error('Create user error:', err);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// GET /api/auth/users - List all users for merchant
router.get('/users', authenticate, requireAdmin, (req, res) => {
  const users = User.listByMerchant(req.user.merchant_id);
  res.json(users);
});

// PUT /api/auth/users/:id - Update user
router.put('/users/:id', authenticate, requireAdmin, (req, res) => {
  try {
    const user = User.findById(req.params.id);
    if (!user || user.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'User not found' });
    }

    const updated = User.update(req.params.id, req.body);
    res.json(updated);
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// DELETE /api/auth/users/:id - Delete user
router.delete('/users/:id', authenticate, requireAdmin, (req, res) => {
  try {
    if (req.params.id === req.user.id) {
      return res.status(400).json({ error: 'Cannot delete yourself' });
    }

    const user = User.findById(req.params.id);
    if (!user || user.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'User not found' });
    }

    User.delete(req.params.id);
    res.json({ message: 'User deleted' });
  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

module.exports = router;
