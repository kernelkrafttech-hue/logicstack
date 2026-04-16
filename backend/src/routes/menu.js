const express = require('express');
const router = express.Router();
const { MenuItem, MenuCategory } = require('../models/MenuItem');
const { authenticate, requireAdmin, checkSubscription } = require('../middleware/auth');

router.use(authenticate, checkSubscription);

// ---- Categories ----

// GET /api/menu/categories
router.get('/categories', (req, res) => {
  try {
    const categories = MenuCategory.listByMerchant(req.user.merchant_id);
    res.json(categories);
  } catch (err) {
    console.error('List categories error:', err);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// POST /api/menu/categories (admin)
router.post('/categories', requireAdmin, (req, res) => {
  try {
    const { name, sortOrder } = req.body;
    if (!name) return res.status(400).json({ error: 'Name is required' });

    const category = MenuCategory.create({
      merchantId: req.user.merchant_id,
      name,
      sortOrder,
    });
    res.status(201).json(category);
  } catch (err) {
    console.error('Create category error:', err);
    res.status(500).json({ error: 'Failed to create category' });
  }
});

// PUT /api/menu/categories/:id (admin)
router.put('/categories/:id', requireAdmin, (req, res) => {
  try {
    const cat = MenuCategory.findById(req.params.id);
    if (!cat || cat.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Category not found' });
    }
    const updated = MenuCategory.update(req.params.id, req.body);
    res.json(updated);
  } catch (err) {
    console.error('Update category error:', err);
    res.status(500).json({ error: 'Failed to update category' });
  }
});

// DELETE /api/menu/categories/:id (admin)
router.delete('/categories/:id', requireAdmin, (req, res) => {
  try {
    const cat = MenuCategory.findById(req.params.id);
    if (!cat || cat.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Category not found' });
    }
    MenuCategory.delete(req.params.id);
    res.json({ message: 'Category deleted' });
  } catch (err) {
    console.error('Delete category error:', err);
    res.status(500).json({ error: 'Failed to delete category' });
  }
});

// ---- Items ----

// GET /api/menu/items
router.get('/items', (req, res) => {
  try {
    const { categoryId } = req.query;
    let items;
    if (categoryId) {
      items = MenuItem.listByCategory(req.user.merchant_id, categoryId);
    } else {
      items = MenuItem.listByMerchant(req.user.merchant_id);
    }
    res.json(items);
  } catch (err) {
    console.error('List items error:', err);
    res.status(500).json({ error: 'Failed to fetch menu items' });
  }
});

// POST /api/menu/items (admin)
router.post('/items', requireAdmin, (req, res) => {
  try {
    const { name, description, price, categoryId, cloverItemId } = req.body;
    if (!name || price === undefined) {
      return res.status(400).json({ error: 'Name and price are required' });
    }

    const item = MenuItem.create({
      merchantId: req.user.merchant_id,
      categoryId,
      name,
      description,
      price,
      cloverItemId,
    });
    res.status(201).json(item);
  } catch (err) {
    console.error('Create item error:', err);
    res.status(500).json({ error: 'Failed to create menu item' });
  }
});

// PUT /api/menu/items/:id (admin)
router.put('/items/:id', requireAdmin, (req, res) => {
  try {
    const item = MenuItem.findById(req.params.id);
    if (!item || item.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Item not found' });
    }
    const updated = MenuItem.update(req.params.id, req.body);
    res.json(updated);
  } catch (err) {
    console.error('Update item error:', err);
    res.status(500).json({ error: 'Failed to update menu item' });
  }
});

// DELETE /api/menu/items/:id (admin)
router.delete('/items/:id', requireAdmin, (req, res) => {
  try {
    const item = MenuItem.findById(req.params.id);
    if (!item || item.merchant_id !== req.user.merchant_id) {
      return res.status(404).json({ error: 'Item not found' });
    }
    MenuItem.delete(req.params.id);
    res.json({ message: 'Item deleted' });
  } catch (err) {
    console.error('Delete item error:', err);
    res.status(500).json({ error: 'Failed to delete menu item' });
  }
});

module.exports = router;
