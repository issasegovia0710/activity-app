import axios from 'axios';
import { Platform } from 'react-native';
import storage from './storage';

const API_URL_WEB = 'https://activity-api-git-main-issasegovia0710s-projects.vercel.app/api';

// Para iPhone cambia esto por la IP de tu computadora.
const API_URL_MOVIL = 'https://activity-api-git-main-issasegovia0710s-projects.vercel.app/api';

const API_BASE_URL = Platform.OS === 'web' ? API_URL_WEB : API_URL_MOVIL;

console.log('==============================');
console.log('API CONFIG');
console.log('Platform.OS:', Platform.OS);
console.log('API_BASE_URL:', API_BASE_URL);
console.log('==============================');

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
});

api.interceptors.request.use(
  async (config) => {
    const token = await storage.getItem('token');

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    const fullUrl = `${config.baseURL || API_BASE_URL}${config.url || ''}`;

    console.log('REQUEST API');
    console.log('Método:', String(config.method || 'GET').toUpperCase());
    console.log('URL:', fullUrl);
    console.log('Token:', token ? 'Sí hay token' : 'No hay token');
    console.log('Data:', config.data || null);

    return config;
  },
  (error) => {
    console.log('ERROR ANTES DE ENVIAR REQUEST:', error);
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response) => {
    console.log('RESPUESTA API');
    console.log('Status:', response.status);
    console.log('URL:', response.config?.url);
    console.log('Data:', response.data);

    return response;
  },
  (error) => {
    console.log('ERROR API');
    console.log('Mensaje:', error.message);
    console.log('URL:', error.config?.baseURL + error.config?.url);
    console.log('Status:', error.response?.status);
    console.log('Data:', error.response?.data);

    return Promise.reject(error);
  }
);

export default api;