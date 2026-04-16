const db = require('../config/database');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const User = {
  create({ merchantId, email, password, name, role = 'staff', pin }) {
    const id = uuidv4();
    const passwordHash = bcrypt.hashSync(password, 10);
    db.prepare(`
      INSERT INTO users (id, merchant_id, email, password_hash, name, role, pin)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(id, merchantId, email, passwordHash, name, role, pin || null);
    return User.findById(id);
  },

  findById(id) {
    return db.prepare('SELECT id, merchant_id, email, name, role, pin, is_active, created_at FROM users WHERE id = ?').get(id);
  },

  findByEmail(merchantId, email) {
    return db.prepare('SELECT * FROM users WHERE merchant_id = ? AND email = ?').get(merchantId, email);
  },

  findByEmailGlobal(email) {
    return db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  },

  findByPin(merchantId, pin) {
    return db.prepare('SELECT id, merchant_id, email, name, role, is_active FROM users WHERE merchant_id = ? AND pin = ? AND is_active = 1').get(merchantId, pin);
  },

  listByMerchant(merchantId) {
    return db.prepare('SELECT id, merchant_id, email, name, role, is_active, created_at FROM users WHERE merchant_id = ? ORDER BY created_at DESC').all(merchantId);
  },

  update(id, fields) {
    const allowed = ['name', 'email', 'role', 'pin', 'is_active'];
    const updates = [];
    const values = [];

    for (const key of allowed) {
      if (fields[key] !== undefined) {
        updates.push(`${key} = ?`);
        values.push(fields[key]);
      }
    }

    if (fields.password) {
      updates.push('password_hash = ?');
      values.push(bcrypt.hashSync(fields.password, 10));
    }

    updates.push("updated_at = datetime('now')");
    values.push(id);

    db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`).run(...values);
    return User.findById(id);
  },

  delete(id) {
    return db.prepare('DELETE FROM users WHERE id = ?').run(id);
  },

  verifyPassword(user, password) {
    return bcrypt.compareSync(password, user.password_hash);
  },
};

module.exports = User;
