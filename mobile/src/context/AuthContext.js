import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { auth } from '../services/api';

const AuthContext = createContext(null);

const initialState = {
  user: null,
  merchant: null,
  isLoading: true,
  isAuthenticated: false,
};

function authReducer(state, action) {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'LOGIN_SUCCESS':
      return {
        ...state,
        user: action.payload.user,
        merchant: action.payload.merchant,
        isAuthenticated: true,
        isLoading: false,
      };
    case 'LOGOUT':
      return { ...initialState, isLoading: false };
    default:
      return state;
  }
}

export function AuthProvider({ children }) {
  const [state, dispatch] = useReducer(authReducer, initialState);

  // Check for existing session on mount
  useEffect(() => {
    checkAuth();
  }, []);

  async function checkAuth() {
    try {
      const data = await auth.getMe();
      dispatch({ type: 'LOGIN_SUCCESS', payload: data });
    } catch {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  }

  async function login(email, password) {
    const data = await auth.login(email, password);
    dispatch({ type: 'LOGIN_SUCCESS', payload: data });
    return data;
  }

  async function pinLogin(merchantId, pin) {
    const data = await auth.pinLogin(merchantId, pin);
    dispatch({ type: 'LOGIN_SUCCESS', payload: { user: data.user, merchant: state.merchant } });
    return data;
  }

  async function register(merchantName, email, password, name) {
    const data = await auth.register(merchantName, email, password, name);
    dispatch({ type: 'LOGIN_SUCCESS', payload: data });
    return data;
  }

  async function logout() {
    await auth.logout();
    dispatch({ type: 'LOGOUT' });
  }

  const value = {
    ...state,
    login,
    pinLogin,
    register,
    logout,
    isAdmin: state.user?.role === 'admin',
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
