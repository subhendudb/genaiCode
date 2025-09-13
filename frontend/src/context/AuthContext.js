import React, { useState, useEffect, createContext } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token') || null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    if (token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      setUser(true); // Just mark as logged in; no user info from backend
    } else {
      setUser(null);
      navigate('/login'); // Redirect to login if no token
    }
    setLoading(false);
  }, [token, navigate]);

  const login = async credentials => {
    // Try to convert credentials to an object if it's a string
    let safeCredentials = credentials;
    if (typeof credentials === 'string') {
      try {
        safeCredentials = JSON.parse(credentials);
      } catch {
        // If parsing fails, set to empty object
        safeCredentials = {};
      }
    }
    //console.log(credentials)
    // Ensure safeCredentials is a valid object with username and password
    if (
      !safeCredentials ||
      typeof safeCredentials !== 'object' ||
      Array.isArray(safeCredentials) ||
      typeof safeCredentials.username !== 'string' ||
      typeof safeCredentials.password !== 'string' // pragma: allowlist secret
    ) {
      // Optionally, you can return a rejected promise with a message
      return Promise.reject(
        new Error(
          'Login requires an object with username and password fields.',
        ),
      );
    }

    const { data } = await api.post('/api/login', safeCredentials);
    localStorage.setItem('token', data.token);
    setToken(data.token);
    setUser(true); // No user info, just mark as logged in
    navigate('/');
    return data;
  };

  const logout = () => {
    localStorage.removeItem('token');
    delete api.defaults.headers.common['Authorization'];
    setToken(null);
    setUser(null);
    navigate('/login');
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = React.useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
