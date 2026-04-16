const net = require('net');
const db = require('../config/database');
const CloverService = require('./clover');

const PrinterService = {
  /**
   * Format order for receipt printing using ESC/POS commands
   */
  formatReceipt(order) {
    const ESC = '\x1B';
    const GS = '\x1D';
    const lines = [];

    // Initialize printer
    lines.push(`${ESC}@`);

    // Center align + bold for header
    lines.push(`${ESC}a\x01`); // center
    lines.push(`${ESC}E\x01`); // bold on
    lines.push(`${GS}!\x11`); // double size
    lines.push(`ORDER #${order.order_number}`);
    lines.push(`${GS}!\x00`); // normal size
    lines.push('');

    // Order type & table
    const typeLabels = {
      dine_in: 'DINE IN',
      takeout: 'TAKEOUT',
      delivery: 'DELIVERY',
    };
    lines.push(typeLabels[order.order_type] || order.order_type.toUpperCase());
    if (order.table_number) {
      lines.push(`Table: ${order.table_number}`);
    }
    if (order.customer_name) {
      lines.push(`Customer: ${order.customer_name}`);
    }
    lines.push(`${ESC}E\x00`); // bold off
    lines.push('');

    // Left align for items
    lines.push(`${ESC}a\x00`); // left
    lines.push('--------------------------------');
    lines.push('');

    // Items
    for (const item of order.items) {
      const price = (item.price * item.quantity / 100).toFixed(2);
      const qty = item.quantity > 1 ? `${item.quantity}x ` : '';
      const nameStr = `${qty}${item.name}`;
      const padding = Math.max(1, 32 - nameStr.length - price.length);
      lines.push(`${nameStr}${' '.repeat(padding)}$${price}`);

      if (item.modifiers) {
        try {
          const mods = typeof item.modifiers === 'string' ? JSON.parse(item.modifiers) : item.modifiers;
          if (Array.isArray(mods)) {
            for (const mod of mods) {
              lines.push(`  + ${mod}`);
            }
          }
        } catch (e) {
          // ignore modifier parse errors
        }
      }

      if (item.notes) {
        lines.push(`  * ${item.notes}`);
      }
    }

    lines.push('');
    lines.push('--------------------------------');

    // Totals
    const subtotal = (order.subtotal / 100).toFixed(2);
    const tax = (order.tax / 100).toFixed(2);
    const total = (order.total / 100).toFixed(2);

    lines.push(`${'Subtotal:'.padEnd(24)}$${subtotal}`);
    lines.push(`${'Tax:'.padEnd(24)}$${tax}`);
    lines.push(`${ESC}E\x01`); // bold
    lines.push(`${'TOTAL:'.padEnd(24)}$${total}`);
    lines.push(`${ESC}E\x00`); // bold off

    // Notes
    if (order.notes) {
      lines.push('');
      lines.push('--------------------------------');
      lines.push(`Notes: ${order.notes}`);
    }

    // Footer
    lines.push('');
    lines.push(`${ESC}a\x01`); // center
    const date = new Date(order.created_at).toLocaleString();
    lines.push(date);
    lines.push(`Server: ${order.created_by_name || 'Unknown'}`);
    lines.push('');
    lines.push('Thank you!');
    lines.push('');

    // Cut paper
    lines.push(`${GS}V\x00`);

    return lines.join('\n');
  },

  /**
   * Send data to a network printer
   */
  sendToNetworkPrinter(address, port, data) {
    return new Promise((resolve, reject) => {
      const client = new net.Socket();
      const timeout = setTimeout(() => {
        client.destroy();
        reject(new Error('Printer connection timed out'));
      }, 10000);

      client.connect(port, address, () => {
        client.write(data, () => {
          clearTimeout(timeout);
          client.end();
          resolve();
        });
      });

      client.on('error', (err) => {
        clearTimeout(timeout);
        reject(new Error(`Printer error: ${err.message}`));
      });
    });
  },

  /**
   * Print an order
   */
  async printOrder(merchantId, order, printerId) {
    let printer;

    if (printerId) {
      printer = db.prepare('SELECT * FROM printers WHERE id = ? AND merchant_id = ? AND is_active = 1').get(printerId, merchantId);
    } else {
      printer = db.prepare('SELECT * FROM printers WHERE merchant_id = ? AND is_default = 1 AND is_active = 1').get(merchantId);
    }

    if (!printer) {
      printer = db.prepare('SELECT * FROM printers WHERE merchant_id = ? AND is_active = 1 LIMIT 1').get(merchantId);
    }

    if (!printer) {
      throw new Error('No printer configured. Add a printer in Settings.');
    }

    if (printer.type === 'clover') {
      // Use Clover's built-in print API
      if (order.clover_order_id) {
        return CloverService.printOrder(merchantId, order.clover_order_id);
      }
      throw new Error('Order not synced to Clover. Cannot use Clover printer.');
    }

    // Format and send to network/USB printer
    const receiptData = PrinterService.formatReceipt(order);

    if (printer.type === 'network') {
      if (!printer.address) {
        throw new Error('Printer network address not configured');
      }
      return PrinterService.sendToNetworkPrinter(printer.address, printer.port || 9100, receiptData);
    }

    // For USB/Bluetooth, return formatted data (handled by mobile app)
    return { type: printer.type, data: receiptData };
  },

  /**
   * Send a test print
   */
  async testPrint(printer) {
    const ESC = '\x1B';
    const GS = '\x1D';
    const testData = [
      `${ESC}@`,
      `${ESC}a\x01`,
      `${ESC}E\x01`,
      'PRINTER TEST',
      `${ESC}E\x00`,
      '',
      `Printer: ${printer.name}`,
      `Type: ${printer.type}`,
      `Time: ${new Date().toLocaleString()}`,
      '',
      'If you see this, your',
      'printer is working!',
      '',
      `${GS}V\x00`,
    ].join('\n');

    if (printer.type === 'network') {
      return PrinterService.sendToNetworkPrinter(printer.address, printer.port || 9100, testData);
    }

    return { type: printer.type, data: testData };
  },
};

module.exports = PrinterService;
