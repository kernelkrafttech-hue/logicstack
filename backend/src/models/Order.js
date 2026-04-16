const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

const Order = {
  getNextOrderNumber(merchantId) {
    const result = db.prepare(`
      UPDATE order_sequence SET current_number = current_number + 1
      WHERE merchant_id = ?
    `).run(merchantId);

    if (result.changes === 0) {
      db.prepare('INSERT INTO order_sequence (merchant_id, current_number) VALUES (?, 1)').run(merchantId);
      return 1;
    }

    return db.prepare('SELECT current_number FROM order_sequence WHERE merchant_id = ?').get(merchantId).current_number;
  },

  create({ merchantId, createdBy, customerName, orderType, tableNumber, notes, items }) {
    const id = uuidv4();
    const orderNumber = Order.getNextOrderNumber(merchantId);

    let subtotal = 0;
    for (const item of items) {
      subtotal += item.price * item.quantity;
    }
    const tax = Math.round(subtotal * 0.08); // 8% tax
    const total = subtotal + tax;

    const insertOrder = db.prepare(`
      INSERT INTO orders (id, merchant_id, order_number, created_by, customer_name, order_type, table_number, notes, subtotal, tax, total, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `);

    const insertItem = db.prepare(`
      INSERT INTO order_items (id, order_id, menu_item_id, name, quantity, price, modifiers, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const transaction = db.transaction(() => {
      insertOrder.run(id, merchantId, orderNumber, createdBy, customerName || null, orderType || 'dine_in', tableNumber || null, notes || null, subtotal, tax, total);

      for (const item of items) {
        insertItem.run(
          uuidv4(),
          id,
          item.menu_item_id || null,
          item.name,
          item.quantity,
          item.price,
          item.modifiers ? JSON.stringify(item.modifiers) : null,
          item.notes || null
        );
      }
    });

    transaction();
    return Order.findById(id);
  },

  findById(id) {
    const order = db.prepare(`
      SELECT o.*, u.name as created_by_name
      FROM orders o
      LEFT JOIN users u ON o.created_by = u.id
      WHERE o.id = ?
    `).get(id);

    if (!order) return null;

    order.items = db.prepare(`
      SELECT oi.*, mi.description as item_description
      FROM order_items oi
      LEFT JOIN menu_items mi ON oi.menu_item_id = mi.id
      WHERE oi.order_id = ?
    `).all(id);

    return order;
  },

  listByMerchant(merchantId, { status, limit = 50, offset = 0 } = {}) {
    let query = `
      SELECT o.*, u.name as created_by_name
      FROM orders o
      LEFT JOIN users u ON o.created_by = u.id
      WHERE o.merchant_id = ?
    `;
    const params = [merchantId];

    if (status) {
      query += ' AND o.status = ?';
      params.push(status);
    }

    query += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const orders = db.prepare(query).all(...params);

    for (const order of orders) {
      order.items = db.prepare('SELECT * FROM order_items WHERE order_id = ?').all(order.id);
    }

    return orders;
  },

  updateStatus(id, status, reviewedBy, reviewNotes) {
    const updates = ["status = ?", "updated_at = datetime('now')"];
    const values = [status];

    if (reviewedBy) {
      updates.push('reviewed_by = ?');
      values.push(reviewedBy);
    }

    if (reviewNotes) {
      updates.push('review_notes = ?');
      values.push(reviewNotes);
    }

    values.push(id);
    db.prepare(`UPDATE orders SET ${updates.join(', ')} WHERE id = ?`).run(...values);
    return Order.findById(id);
  },

  markPrinted(id) {
    db.prepare("UPDATE orders SET printed = 1, updated_at = datetime('now') WHERE id = ?").run(id);
  },

  delete(id) {
    return db.prepare('DELETE FROM orders WHERE id = ?').run(id);
  },

  getStats(merchantId, date) {
    const dateFilter = date || new Date().toISOString().split('T')[0];

    const stats = db.prepare(`
      SELECT
        COUNT(*) as total_orders,
        COALESCE(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END), 0) as pending,
        COALESCE(SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END), 0) as in_progress,
        COALESCE(SUM(CASE WHEN status = 'ready' THEN 1 ELSE 0 END), 0) as ready,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END), 0) as completed,
        COALESCE(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 0) as cancelled,
        COALESCE(SUM(CASE WHEN status IN ('completed') THEN total ELSE 0 END), 0) as revenue
      FROM orders
      WHERE merchant_id = ? AND date(created_at) = ?
    `).get(merchantId, dateFilter);

    return stats;
  },
};

module.exports = Order;
