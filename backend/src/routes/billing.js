const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticate, requireAdmin } = require('../middleware/auth');

// Initialize Stripe only if key is configured
let stripe = null;
if (process.env.STRIPE_SECRET_KEY && process.env.STRIPE_SECRET_KEY !== 'sk_test_your-stripe-secret-key') {
  stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
}

// GET /api/billing/status - Get subscription status
router.get('/status', authenticate, (req, res) => {
  const merchant = db.prepare(`
    SELECT id, name, subscription_status, trial_ends_at, stripe_customer_id, stripe_subscription_id
    FROM merchants WHERE id = ?
  `).get(req.user.merchant_id);

  if (!merchant) {
    return res.status(404).json({ error: 'Merchant not found' });
  }

  const daysLeft = merchant.trial_ends_at
    ? Math.max(0, Math.ceil((new Date(merchant.trial_ends_at) - new Date()) / (1000 * 60 * 60 * 24)))
    : 0;

  res.json({
    status: merchant.subscription_status,
    trialEndsAt: merchant.trial_ends_at,
    trialDaysLeft: daysLeft,
    hasPaymentMethod: !!merchant.stripe_customer_id,
  });
});

// POST /api/billing/create-checkout - Create Stripe checkout session for $10/month
router.post('/create-checkout', authenticate, requireAdmin, async (req, res) => {
  if (!stripe) {
    return res.status(503).json({ error: 'Billing is not configured. Set STRIPE_SECRET_KEY in environment.' });
  }

  try {
    const merchant = db.prepare('SELECT * FROM merchants WHERE id = ?').get(req.user.merchant_id);

    // Create or get Stripe customer
    let customerId = merchant.stripe_customer_id;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: req.user.email,
        name: merchant.name,
        metadata: { merchant_id: merchant.id },
      });
      customerId = customer.id;
      db.prepare('UPDATE merchants SET stripe_customer_id = ? WHERE id = ?').run(customerId, merchant.id);
    }

    const priceId = process.env.STRIPE_PRICE_ID;
    if (!priceId || priceId === 'price_your-stripe-price-id') {
      return res.status(503).json({ error: 'Stripe price ID not configured. Create a $10/month price in Stripe Dashboard.' });
    }

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      mode: 'subscription',
      success_url: `${req.body.successUrl || 'https://your-app.com/billing/success'}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: req.body.cancelUrl || 'https://your-app.com/billing/cancel',
      metadata: { merchant_id: merchant.id },
    });

    res.json({ checkoutUrl: session.url, sessionId: session.id });
  } catch (err) {
    console.error('Create checkout error:', err);
    res.status(500).json({ error: 'Failed to create checkout session' });
  }
});

// POST /api/billing/webhook - Stripe webhook handler
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  if (!stripe) {
    return res.status(503).json({ error: 'Billing not configured' });
  }

  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!webhookSecret || webhookSecret === 'whsec_your-webhook-secret') {
    return res.status(503).json({ error: 'Webhook secret not configured' });
  }

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).json({ error: 'Invalid signature' });
  }

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object;
      const merchantId = session.metadata.merchant_id;
      if (merchantId) {
        db.prepare(`
          UPDATE merchants SET subscription_status = 'active', stripe_subscription_id = ?, updated_at = datetime('now')
          WHERE id = ?
        `).run(session.subscription, merchantId);
      }
      break;
    }

    case 'customer.subscription.deleted': {
      const subscription = event.data.object;
      db.prepare(`
        UPDATE merchants SET subscription_status = 'cancelled', updated_at = datetime('now')
        WHERE stripe_subscription_id = ?
      `).run(subscription.id);
      break;
    }

    case 'invoice.payment_failed': {
      const invoice = event.data.object;
      db.prepare(`
        UPDATE merchants SET subscription_status = 'past_due', updated_at = datetime('now')
        WHERE stripe_customer_id = ?
      `).run(invoice.customer);
      break;
    }
  }

  res.json({ received: true });
});

module.exports = router;
