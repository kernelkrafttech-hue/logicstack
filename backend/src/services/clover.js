const fetch = require('node-fetch');
const db = require('../config/database');

const CLOVER_API_BASE = process.env.CLOVER_API_BASE || 'https://sandbox.dev.clover.com';

const CloverService = {
  /**
   * Get merchant's Clover credentials
   */
  getMerchantConfig(merchantId) {
    const merchant = db.prepare('SELECT clover_merchant_id, clover_api_token FROM merchants WHERE id = ?').get(merchantId);
    if (!merchant || !merchant.clover_merchant_id || !merchant.clover_api_token) {
      return null;
    }
    return {
      cloverMerchantId: merchant.clover_merchant_id,
      apiToken: merchant.clover_api_token,
    };
  },

  /**
   * Make authenticated request to Clover API
   */
  async request(apiToken, endpoint, options = {}) {
    const url = `${CLOVER_API_BASE}${endpoint}`;
    const response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Clover API error (${response.status}): ${error}`);
    }

    return response.json();
  },

  /**
   * Sync order to Clover POS
   */
  async syncOrder(merchantId, order) {
    const config = CloverService.getMerchantConfig(merchantId);
    if (!config) return null; // Clover not configured, skip silently

    const { cloverMerchantId, apiToken } = config;

    // Create order in Clover
    const cloverOrder = await CloverService.request(
      apiToken,
      `/v3/merchants/${cloverMerchantId}/orders`,
      {
        method: 'POST',
        body: JSON.stringify({
          state: 'open',
          title: `Order #${order.order_number}`,
          note: order.notes || '',
          orderType: { id: order.order_type },
        }),
      }
    );

    // Add line items
    for (const item of order.items) {
      if (item.clover_item_id) {
        await CloverService.request(
          apiToken,
          `/v3/merchants/${cloverMerchantId}/orders/${cloverOrder.id}/line_items`,
          {
            method: 'POST',
            body: JSON.stringify({
              item: { id: item.clover_item_id },
              name: item.name,
              price: item.price,
              quantity: item.quantity,
            }),
          }
        );
      }
    }

    // Store Clover order ID
    db.prepare("UPDATE orders SET clover_order_id = ?, updated_at = datetime('now') WHERE id = ?").run(cloverOrder.id, order.id);

    return cloverOrder;
  },

  /**
   * Sync menu items from Clover inventory
   */
  async syncMenu(merchantId) {
    const config = CloverService.getMerchantConfig(merchantId);
    if (!config) throw new Error('Clover not configured for this merchant');

    const { cloverMerchantId, apiToken } = config;

    // Fetch items from Clover
    const result = await CloverService.request(
      apiToken,
      `/v3/merchants/${cloverMerchantId}/items?expand=categories`
    );

    return result.elements || [];
  },

  /**
   * Print via Clover's print API
   */
  async printOrder(merchantId, orderId) {
    const config = CloverService.getMerchantConfig(merchantId);
    if (!config) throw new Error('Clover not configured for this merchant');

    const { cloverMerchantId, apiToken } = config;

    // Trigger print on Clover device
    return CloverService.request(
      apiToken,
      `/v3/merchants/${cloverMerchantId}/orders/${orderId}/print`,
      { method: 'POST' }
    );
  },
};

module.exports = CloverService;
