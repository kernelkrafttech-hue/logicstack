const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const { authenticate, requireAdmin, checkSubscription } = require('../middleware/auth');
const PrinterService = require('../services/printer');
const CloverService = require('../services/clover');

// All order routes require auth + active subscription
router.use(authenticate, checkSubscription);

// GET /api/orders - List orders
router.get('/', (req, res) => {
  try {
    const { status, limit, offset } = req.query;
    const orders = Order.listByMerchant(req.user.merchant_id, {
      status,
      limit: parseInt(limit) || 50,
      offset: parseInt(offset) || 0,
    });
    res.json(orders);
  } catch (err) {
    console.error('List orders error:', err);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// GET /api/orders/stats - Get order stats for today
router.get('/stats', (req, res) => {
  try {
    const { date } = req.query;
    const stats = Order.getStats(req.user.merchant_id, date);
    res.json(stats);
  } catch (err) {
    console.error('Order stats error:', err);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

// GET /api/orders/:id - Get single order
router.get('/:id', (req, res) => {
  try {
    const order = Order.findById(req.params.id);
    if (!order || order.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.json(order);
  } catch (err) {
    console.error('Get order error:', err);
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

// POST /api/orders - Create new order (any authenticated user)
router.post('/', async (req, res) => {
  try {
    const { customerName, orderType, tableNumber, notes, items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Order must have at least one item' });
    }

    for (const item of items) {
      if (!item.name || !item.price || !item.quantity) {
        return res.status(400).json({ error: 'Each item must have name, price, and quantity' });
      }
    }

    const order = Order.create({
      merchantId: req.user.merchant_id,
      createdBy: req.user.id,
      customerName,
      orderType,
      tableNumber,
      notes,
      items,
    });

    // Sync to Clover if configured
    try {
      await CloverService.syncOrder(req.user.merchant_id, order);
    } catch (cloverErr) {
      console.warn('Clover sync failed (non-blocking):', cloverErr.message);
    }

    res.status(201).json(order);
  } catch (err) {
    console.error('Create order error:', err);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// PUT /api/orders/:id/status - Update order status
router.put('/:id/status', (req, res) => {
  try {
    const { status, reviewNotes } = req.body;
    const validStatuses = ['pending', 'in_progress', 'ready', 'completed', 'cancelled', 'in_review'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
    }

    const order = Order.findById(req.params.id);
    if (!order || order.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Staff can only move orders forward, not cancel
    if (req.user.role === 'staff' && status === 'cancelled') {
      return res.status(403).json({ error: 'Only admins can cancel orders' });
    }

    // Staff can put orders in review
    const reviewedBy = status === 'in_review' ? req.user.id : null;

    const updated = Order.updateStatus(req.params.id, status, reviewedBy, reviewNotes);
    res.json(updated);
  } catch (err) {
    console.error('Update order status error:', err);
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

// DELETE /api/orders/:id - Delete order (admin only)
router.delete('/:id', requireAdmin, (req, res) => {
  try {
    const order = Order.findById(req.params.id);
    if (!order || order.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Order not found' });
    }

    Order.delete(req.params.id);
    res.json({ message: 'Order deleted' });
  } catch (err) {
    console.error('Delete order error:', err);
    res.status(500).json({ error: 'Failed to delete order' });
  }
});

// POST /api/orders/:id/print - Print order receipt
router.post('/:id/print', async (req, res) => {
  try {
    const order = Order.findById(req.params.id);
    if (!order || order.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const { printerId } = req.body;
    await PrinterService.printOrder(req.user.merchant_id, order, printerId);
    Order.markPrinted(req.params.id);

    res.json({ message: 'Order sent to printer', order_id: order.id });
  } catch (err) {
    console.error('Print order error:', err);
    res.status(500).json({ error: `Print failed: ${err.message}` });
  }
});

module.exports = router;
