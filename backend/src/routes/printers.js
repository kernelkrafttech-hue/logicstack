const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticate, requireAdmin, checkSubscription } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');

router.use(authenticate, checkSubscription);

// GET /api/printers - List printers
router.get('/', (req, res) => {
  const printers = db.prepare('SELECT * FROM printers WHERE merchant_id = ? AND is_active = 1 ORDER BY is_default DESC, name').all(req.user.merchant_id);
  res.json(printers);
});

// POST /api/printers - Add printer (admin)
router.post('/', requireAdmin, (req, res) => {
  try {
    const { name, type, address, port, isDefault } = req.body;

    if (!name || !type) {
      return res.status(400).json({ error: 'Name and type are required' });
    }

    const validTypes = ['network', 'usb', 'bluetooth', 'clover'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({ error: `Invalid type. Must be one of: ${validTypes.join(', ')}` });
    }

    // If setting as default, unset other defaults
    if (isDefault) {
      db.prepare('UPDATE printers SET is_default = 0 WHERE merchant_id = ?').run(req.user.merchant_id);
    }

    const id = uuidv4();
    db.prepare(`
      INSERT INTO printers (id, merchant_id, name, type, address, port, is_default)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(id, req.user.merchant_id, name, type, address || null, port || 9100, isDefault ? 1 : 0);

    const printer = db.prepare('SELECT * FROM printers WHERE id = ?').get(id);
    res.status(201).json(printer);
  } catch (err) {
    console.error('Create printer error:', err);
    res.status(500).json({ error: 'Failed to add printer' });
  }
});

// PUT /api/printers/:id - Update printer (admin)
router.put('/:id', requireAdmin, (req, res) => {
  try {
    const printer = db.prepare('SELECT * FROM printers WHERE id = ? AND merchant_id = ?').get(req.params.id, req.user.merchant_id);
    if (!printer) {
      return res.status(404).json({ error: 'Printer not found' });
    }

    const { name, type, address, port, isDefault } = req.body;

    if (isDefault) {
      db.prepare('UPDATE printers SET is_default = 0 WHERE merchant_id = ?').run(req.user.merchant_id);
    }

    db.prepare(`
      UPDATE printers SET
        name = COALESCE(?, name),
        type = COALESCE(?, type),
        address = COALESCE(?, address),
        port = COALESCE(?, port),
        is_default = COALESCE(?, is_default)
      WHERE id = ?
    `).run(name, type, address, port, isDefault ? 1 : 0, req.params.id);

    const updated = db.prepare('SELECT * FROM printers WHERE id = ?').get(req.params.id);
    res.json(updated);
  } catch (err) {
    console.error('Update printer error:', err);
    res.status(500).json({ error: 'Failed to update printer' });
  }
});

// DELETE /api/printers/:id - Delete printer (admin)
router.delete('/:id', requireAdmin, (req, res) => {
  try {
    const printer = db.prepare('SELECT * FROM printers WHERE id = ? AND merchant_id = ?').get(req.params.id, req.user.merchant_id);
    if (!printer) {
      return res.status(404).json({ error: 'Printer not found' });
    }
    db.prepare('UPDATE printers SET is_active = 0 WHERE id = ?').run(req.params.id);
    res.json({ message: 'Printer removed' });
  } catch (err) {
    console.error('Delete printer error:', err);
    res.status(500).json({ error: 'Failed to delete printer' });
  }
});

// POST /api/printers/:id/test - Test printer
router.post('/:id/test', requireAdmin, async (req, res) => {
  try {
    const PrinterService = require('../services/printer');
    const printer = db.prepare('SELECT * FROM printers WHERE id = ? AND merchant_id = ?').get(req.params.id, req.user.merchant_id);
    if (!printer) {
      return res.status(404).json({ error: 'Printer not found' });
    }

    await PrinterService.testPrint(printer);
    res.json({ message: 'Test print sent successfully' });
  } catch (err) {
    console.error('Test print error:', err);
    res.status(500).json({ error: `Test print failed: ${err.message}` });
  }
});

module.exports = router;
