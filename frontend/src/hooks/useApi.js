import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';

const useApi = () => {
  const { token } = useAuth();
  const [config] = useState({
    baseURL: '/',
    headers: {
      'Content-Type': 'application/json',
      Authorization: token ? `Bearer ${token}` : '',
    },
  });

  const get = useCallback(
    async (url, params) => {
      try {
        const response = await axios.get(url, { ...config, params });
        return response;
      } catch (error) {
        throw error;
      }
    },
    [config]
  );

  const post = useCallback(
    async (url, data) => {
      try {
        const response = await axios.post(url, data, config);
        return response;
      } catch (error) {
        throw error;
      }
    },
    [config]
  );

  const put = useCallback(
    async (url, data) => {
      try {
        const response = await axios.put(url, data, config);
        return response;
      } catch (error) {
        throw error;
      }
    },
    [config]
  );

  return { get, post, put };
};
export default useApi;
