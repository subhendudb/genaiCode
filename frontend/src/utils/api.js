import axios from 'axios';
const api = axios.create({
  baseURL:
    typeof process !== 'undefined' && process.env.REACT_APP_API_URL
      ? process.env.REACT_APP_API_URL
      : '/',
  headers: {
    'Content-Type': 'application/json',
  },
});
// Request interceptor
api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);
// Response interceptor
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location = '/login';
    }
    return Promise.reject(error);
  }
);
export default api;
