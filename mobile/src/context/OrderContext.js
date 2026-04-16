import React, { createContext, useContext, useReducer } from 'react';

const OrderContext = createContext(null);

const initialState = {
  items: [],
  customerName: '',
  orderType: 'dine_in',
  tableNumber: '',
  notes: '',
};

function cartReducer(state, action) {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existing = state.items.findIndex(
        (i) => i.menu_item_id === action.payload.menu_item_id && i.notes === (action.payload.notes || '')
      );
      if (existing >= 0) {
        const items = [...state.items];
        items[existing] = { ...items[existing], quantity: items[existing].quantity + 1 };
        return { ...state, items };
      }
      return { ...state, items: [...state.items, { ...action.payload, quantity: 1 }] };
    }

    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter((_, i) => i !== action.payload) };

    case 'UPDATE_QUANTITY': {
      const items = [...state.items];
      if (action.payload.quantity <= 0) {
        items.splice(action.payload.index, 1);
      } else {
        items[action.payload.index] = { ...items[action.payload.index], quantity: action.payload.quantity };
      }
      return { ...state, items };
    }

    case 'SET_ITEM_NOTES': {
      const items = [...state.items];
      items[action.payload.index] = { ...items[action.payload.index], notes: action.payload.notes };
      return { ...state, items };
    }

    case 'SET_ORDER_INFO':
      return { ...state, ...action.payload };

    case 'CLEAR_CART':
      return { ...initialState };

    default:
      return state;
  }
}

export function OrderProvider({ children }) {
  const [cart, dispatch] = useReducer(cartReducer, initialState);

  function addItem(menuItem) {
    dispatch({
      type: 'ADD_ITEM',
      payload: {
        menu_item_id: menuItem.id,
        name: menuItem.name,
        price: menuItem.price,
        notes: '',
      },
    });
  }

  function removeItem(index) {
    dispatch({ type: 'REMOVE_ITEM', payload: index });
  }

  function updateQuantity(index, quantity) {
    dispatch({ type: 'UPDATE_QUANTITY', payload: { index, quantity } });
  }

  function setItemNotes(index, notes) {
    dispatch({ type: 'SET_ITEM_NOTES', payload: { index, notes } });
  }

  function setOrderInfo(info) {
    dispatch({ type: 'SET_ORDER_INFO', payload: info });
  }

  function clearCart() {
    dispatch({ type: 'CLEAR_CART' });
  }

  const subtotal = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const tax = Math.round(subtotal * 0.08);
  const total = subtotal + tax;
  const itemCount = cart.items.reduce((sum, item) => sum + item.quantity, 0);

  const value = {
    ...cart,
    subtotal,
    tax,
    total,
    itemCount,
    addItem,
    removeItem,
    updateQuantity,
    setItemNotes,
    setOrderInfo,
    clearCart,
  };

  return <OrderContext.Provider value={value}>{children}</OrderContext.Provider>;
}

export function useOrder() {
  const context = useContext(OrderContext);
  if (!context) {
    throw new Error('useOrder must be used within OrderProvider');
  }
  return context;
}
