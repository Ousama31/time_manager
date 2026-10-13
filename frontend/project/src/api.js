// src/api.js
import axios from 'axios';

export const DEFAULT_MOBILE_HOST = 'http://172.20.10.2:4000/api';
export const DEFAULT_WEB_HOST = 'http://localhost:4000/api';

function isNativePlatform() {
  return typeof window !== 'undefined' && Boolean(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
}

export function getApiBaseUrl() {
  const custom = (typeof sessionStorage !== 'undefined' && sessionStorage.getItem('apiBaseUrl')) ||
                 (typeof localStorage !== 'undefined' && localStorage.getItem('apiBaseUrl'));
  if (custom && custom.trim()) {
    return custom.trim().replace(/\/+$/, '');
  }
  if (isNativePlatform()) {
    return DEFAULT_MOBILE_HOST;
  }
  if (typeof window !== 'undefined' && window.location && window.location.hostname && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    return `http://${window.location.hostname}:4000/api`;
  }
  return DEFAULT_WEB_HOST;
}

export function setApiBaseUrl(url) {
  if (url && url.trim()) {
    if (typeof sessionStorage !== 'undefined') sessionStorage.setItem('apiBaseUrl', url.trim());
    if (typeof localStorage !== 'undefined') localStorage.setItem('apiBaseUrl', url.trim());
  } else {
    if (typeof sessionStorage !== 'undefined') sessionStorage.removeItem('apiBaseUrl');
    if (typeof localStorage !== 'undefined') localStorage.removeItem('apiBaseUrl');
  }
}

const api = axios.create({
  baseURL: getApiBaseUrl(),
  headers: {
    'Content-Type': 'application/json'
  },
  timeout: 10000
});

api.interceptors.request.use((config) => {
  config.baseURL = getApiBaseUrl();

  // Skip attaching token for unauthenticated auth routes
  const publicEndpoints = ['/users/sign_in', '/users/sign_up'];
  const isPublicRoute = publicEndpoints.some(path => (config.url || '').endsWith(path));

  const token = (typeof sessionStorage !== 'undefined' && sessionStorage.getItem('xsrfToken')) ||
                (typeof localStorage !== 'undefined' && localStorage.getItem('xsrfToken'));

  if (!isPublicRoute && token && token !== 'undefined' && token !== 'null') {
    config.headers['x-xsrf-token'] = token;
  } else {
    delete config.headers['x-xsrf-token'];
  }

  return config;
}, (error) => {
  return Promise.reject(error);
});

export default api;
