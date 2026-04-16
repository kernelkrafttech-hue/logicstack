const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

const MenuItem = {
  create({ merchantId, categoryId, name, description, price, cloverItemId }) {
    const id = uuidv4();
    db.prepare(`
      INSERT INTO menu_items (id, merchant_id, category_id, name, description, price, clover_item_id)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(id, merchantId, categoryId || null, name, description || null, price, cloverItemId || null);
    return MenuItem.findById(id);
  },

  findById(id) {
    return db.prepare('SELECT * FROM menu_items WHERE id = ?').get(id);
  },

  listByMerchant(merchantId) {
    return db.prepare(`
      SELECT mi.*, mc.name as category_name
      FROM menu_items mi
      LEFT JOIN menu_categories mc ON mi.category_id = mc.id
      WHERE mi.merchant_id = ? AND mi.is_active = 1
      ORDER BY mc.sort_order, mi.sort_order, mi.name
    `).all(merchantId);
  },

  listByCategory(merchantId, categoryId) {
    return db.prepare(`
      SELECT * FROM menu_items
      WHERE merchant_id = ? AND category_id = ? AND is_active = 1
      ORDER BY sort_order, name
    `).all(merchantId, categoryId);
  },

  update(id, fields) {
    const allowed = ['name', 'description', 'price', 'category_id', 'is_active', 'sort_order', 'clover_item_id'];
    const updates = [];
    const values = [];

    for (const key of allowed) {
      if (fields[key] !== undefined) {
        updates.push(`${key} = ?`);
        values.push(fields[key]);
      }
    }

    if (updates.length === 0) return MenuItem.findById(id);

    updates.push("updated_at = datetime('now')");
    values.push(id);

    db.prepare(`UPDATE menu_items SET ${updates.join(', ')} WHERE id = ?`).run(...values);
    return MenuItem.findById(id);
  },

  delete(id) {
    return db.prepare('UPDATE menu_items SET is_active = 0 WHERE id = ?').run(id);
  },
};

const MenuCategory = {
  create({ merchantId, name, sortOrder }) {
    const id = uuidv4();
    db.prepare('INSERT INTO menu_categories (id, merchant_id, name, sort_order) VALUES (?, ?, ?, ?)').run(id, merchantId, name, sortOrder || 0);
    return MenuCategory.findById(id);
  },

  findById(id) {
    return db.prepare('SELECT * FROM menu_categories WHERE id = ?').get(id);
  },

  listByMerchant(merchantId) {
    return db.prepare('SELECT * FROM menu_categories WHERE merchant_id = ? AND is_active = 1 ORDER BY sort_order, name').all(merchantId);
  },

  update(id, fields) {
    const allowed = ['name', 'sort_order', 'is_active'];
    const updates = [];
    const values = [];

    for (const key of allowed) {
      if (fields[key] !== undefined) {
        updates.push(`${key} = ?`);
        values.push(fields[key]);
      }
    }

    if (updates.length === 0) return MenuCategory.findById(id);
    values.push(id);

    db.prepare(`UPDATE menu_categories SET ${updates.join(', ')} WHERE id = ?`).run(...values);
    return MenuCategory.findById(id);
  },

  delete(id) {
    return db.prepare('UPDATE menu_categories SET is_active = 0 WHERE id = ?').run(id);
  },
};

module.exports = { MenuItem, MenuCategory };
