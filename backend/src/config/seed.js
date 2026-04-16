require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const db = require('./database');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

console.log('Seeding database...');

const merchantId = uuidv4();
const adminId = uuidv4();
const staffId = uuidv4();

// Create demo merchant
db.prepare(`
  INSERT OR IGNORE INTO merchants (id, name, subscription_status, trial_ends_at)
  VALUES (?, ?, 'trial', datetime('now', '+30 days'))
`).run(merchantId, 'Demo Restaurant');

// Create admin user (password: admin123)
const adminHash = bcrypt.hashSync('admin123', 10);
db.prepare(`
  INSERT OR IGNORE INTO users (id, merchant_id, email, password_hash, name, role, pin)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`).run(adminId, merchantId, 'admin@demo.com', adminHash, 'Admin User', 'admin', '1234');

// Create staff user (password: staff123)
const staffHash = bcrypt.hashSync('staff123', 10);
db.prepare(`
  INSERT OR IGNORE INTO users (id, merchant_id, email, password_hash, name, role, pin)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`).run(staffId, merchantId, 'staff@demo.com', staffHash, 'Staff User', 'staff', '5678');

// Create menu categories
const categories = [
  { name: 'Appetizers', sort: 1 },
  { name: 'Entrees', sort: 2 },
  { name: 'Sides', sort: 3 },
  { name: 'Drinks', sort: 4 },
  { name: 'Desserts', sort: 5 },
];

const categoryIds = {};
for (const cat of categories) {
  const id = uuidv4();
  categoryIds[cat.name] = id;
  db.prepare(`
    INSERT OR IGNORE INTO menu_categories (id, merchant_id, name, sort_order)
    VALUES (?, ?, ?, ?)
  `).run(id, merchantId, cat.name, cat.sort);
}

// Create sample menu items (prices in cents)
const menuItems = [
  { name: 'Buffalo Wings', price: 1299, cat: 'Appetizers', desc: 'Crispy wings with buffalo sauce' },
  { name: 'Mozzarella Sticks', price: 999, cat: 'Appetizers', desc: 'Breaded and fried, served with marinara' },
  { name: 'Caesar Salad', price: 1099, cat: 'Appetizers', desc: 'Romaine, parmesan, croutons' },
  { name: 'Grilled Salmon', price: 2499, cat: 'Entrees', desc: 'Atlantic salmon with lemon butter' },
  { name: 'NY Strip Steak', price: 3299, cat: 'Entrees', desc: '12oz strip with garlic butter' },
  { name: 'Chicken Parmesan', price: 1899, cat: 'Entrees', desc: 'Breaded chicken with marinara and mozzarella' },
  { name: 'Pasta Primavera', price: 1599, cat: 'Entrees', desc: 'Seasonal vegetables in cream sauce' },
  { name: 'Burger & Fries', price: 1699, cat: 'Entrees', desc: 'Half-pound patty with hand-cut fries' },
  { name: 'French Fries', price: 599, cat: 'Sides', desc: 'Hand-cut and crispy' },
  { name: 'Coleslaw', price: 499, cat: 'Sides', desc: 'Creamy homestyle coleslaw' },
  { name: 'House Salad', price: 699, cat: 'Sides', desc: 'Mixed greens with house dressing' },
  { name: 'Coca-Cola', price: 299, cat: 'Drinks', desc: 'Fountain drink' },
  { name: 'Iced Tea', price: 299, cat: 'Drinks', desc: 'Fresh brewed' },
  { name: 'Lemonade', price: 349, cat: 'Drinks', desc: 'House-made lemonade' },
  { name: 'Chocolate Cake', price: 899, cat: 'Desserts', desc: 'Rich chocolate layer cake' },
  { name: 'Cheesecake', price: 999, cat: 'Desserts', desc: 'New York style with berry compote' },
];

for (const item of menuItems) {
  db.prepare(`
    INSERT OR IGNORE INTO menu_items (id, merchant_id, category_id, name, description, price, sort_order)
    VALUES (?, ?, ?, ?, ?, ?, 0)
  `).run(uuidv4(), merchantId, categoryIds[item.cat], item.name, item.desc, item.price);
}

// Initialize order sequence
db.prepare(`
  INSERT OR IGNORE INTO order_sequence (merchant_id, current_number)
  VALUES (?, 0)
`).run(merchantId);

console.log('Database seeded successfully!');
console.log('');
console.log('Demo accounts:');
console.log('  Admin: admin@demo.com / admin123 (PIN: 1234)');
console.log('  Staff: staff@demo.com / staff123 (PIN: 5678)');
