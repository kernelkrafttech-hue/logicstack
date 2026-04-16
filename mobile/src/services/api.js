import * as SecureStore from 'expo-secure-store';

const API_URL = 'http://localhost:3000/api'; // Change to your server URL

let authToken = null;

async function loadToken() {
  if (!authToken) {
    authToken = await SecureStore.getItemAsync('auth_token');
  }
  return authToken;
}

async function setToken(token) {
  authToken = token;
  if (token) {
    await SecureStore.setItemAsync('auth_token', token);
  } else {
    await SecureStore.deleteItemAsync('auth_token');
  }
}

async function request(endpoint, options = {}) {
  const token = await loadToken();
  const url = `${API_URL}${endpoint}`;

  const config = {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  };

  if (options.body && typeof options.body === 'object') {
    config.body = JSON.stringify(options.body);
  }

  const response = await fetch(url, config);
  const data = await response.json();

  if (!response.ok) {
    const error = new Error(data.error || 'Request failed');
    error.status = response.status;
    throw error;
  }

  return data;
}

// Auth
export const auth = {
  async login(email, password) {
    const data = await request('/auth/login', {
      method: 'POST',
      body: { email, password },
    });
    await setToken(data.token);
    return data;
  },

  async pinLogin(merchantId, pin) {
    const data = await request('/auth/pin-login', {
      method: 'POST',
      body: { merchantId, pin },
    });
    await setToken(data.token);
    return data;
  },

  async register(merchantName, email, password, name) {
    const data = await request('/auth/register', {
      method: 'POST',
      body: { merchantName, email, password, name },
    });
    await setToken(data.token);
    return data;
  },

  async getMe() {
    return request('/auth/me');
  },

  async logout() {
    await setToken(null);
  },

  // Staff management
  async listUsers() {
    return request('/auth/users');
  },

  async createUser(userData) {
    return request('/auth/users', { method: 'POST', body: userData });
  },

  async updateUser(id, userData) {
    return request(`/auth/users/${id}`, { method: 'PUT', body: userData });
  },

  async deleteUser(id) {
    return request(`/auth/users/${id}`, { method: 'DELETE' });
  },
};

// Orders
export const orders = {
  async list(params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/orders${query ? `?${query}` : ''}`);
  },

  async get(id) {
    return request(`/orders/${id}`);
  },

  async create(orderData) {
    return request('/orders', { method: 'POST', body: orderData });
  },

  async updateStatus(id, status, reviewNotes) {
    return request(`/orders/${id}/status`, {
      method: 'PUT',
      body: { status, reviewNotes },
    });
  },

  async delete(id) {
    return request(`/orders/${id}`, { method: 'DELETE' });
  },

  async print(id, printerId) {
    return request(`/orders/${id}/print`, {
      method: 'POST',
      body: { printerId },
    });
  },

  async getStats(date) {
    const query = date ? `?date=${date}` : '';
    return request(`/orders/stats${query}`);
  },
};

// Menu
export const menu = {
  async listCategories() {
    return request('/menu/categories');
  },

  async createCategory(data) {
    return request('/menu/categories', { method: 'POST', body: data });
  },

  async updateCategory(id, data) {
    return request(`/menu/categories/${id}`, { method: 'PUT', body: data });
  },

  async deleteCategory(id) {
    return request(`/menu/categories/${id}`, { method: 'DELETE' });
  },

  async listItems(categoryId) {
    const query = categoryId ? `?categoryId=${categoryId}` : '';
    return request(`/menu/items${query}`);
  },

  async createItem(data) {
    return request('/menu/items', { method: 'POST', body: data });
  },

  async updateItem(id, data) {
    return request(`/menu/items/${id}`, { method: 'PUT', body: data });
  },

  async deleteItem(id) {
    return request(`/menu/items/${id}`, { method: 'DELETE' });
  },
};

// Printers
export const printers = {
  async list() {
    return request('/printers');
  },

  async create(data) {
    return request('/printers', { method: 'POST', body: data });
  },

  async update(id, data) {
    return request(`/printers/${id}`, { method: 'PUT', body: data });
  },

  async delete(id) {
    return request(`/printers/${id}`, { method: 'DELETE' });
  },

  async test(id) {
    return request(`/printers/${id}/test`, { method: 'POST' });
  },
};

// Billing
export const billing = {
  async getStatus() {
    return request('/billing/status');
  },

  async createCheckout(successUrl, cancelUrl) {
    return request('/billing/create-checkout', {
      method: 'POST',
      body: { successUrl, cancelUrl },
    });
  },
};

export default { auth, orders, menu, printers, billing };
