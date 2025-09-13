import React, { useState } from 'react';
import styled from 'styled-components';
import { useAuth } from '../../context/AuthContext';
import { Button, Input } from '../UI';
import useApi from '../../hooks/useApi';

const LoginContainer = styled.div`
  max-width: 400px;
  margin: 100px auto;
  padding: 20px;
  background: ${({ theme }) => theme.cardBackground};
  border-radius: 12px;
  box-shadow: ${({ theme }) => theme.shadow};
`;

const Login = () => {
  const [credentials, setCredentials] = useState({
    username: '',
    password: '',
  });
  const [error, setError] = useState(null); // <-- Add error state
  const { login } = useAuth();
  const { post } = useApi();
  const handleChange = e => {
    const { name, value } = e.target;
    setCredentials(prev => ({ ...prev, [name]: value }));
  };
  const handleSubmit = async e => {
    e.preventDefault();
    try {
      await post('/api/login', credentials);
      setError(null); // Clear error on success
      login(credentials);
    } catch (error) {
      setError('Login failed: Invalid username or password'); // Set error message
    }
  };
  return (
    <LoginContainer>
      <h2>Enter Credentials</h2>
      {error && (
        <div
          style={{
            background: '#ffe0e0',
            color: '#b00020',
            padding: '10px',
            borderRadius: '6px',
            marginBottom: '16px',
            position: 'relative',
          }}
          data-testid='login-error'
        >
          {error}
          <button
            onClick={() => setError(null)}
            style={{
              position: 'absolute',
              right: 8,
              top: 8,
              background: 'transparent',
              border: 'none',
              fontWeight: 'bold',
              fontSize: '16px',
              cursor: 'pointer',
              color: '#b00020',
            }}
            aria-label='Close'
          >
            ×
          </button>
        </div>
      )}
      <form onSubmit={handleSubmit}>
        <Input
          name='username'
          value={credentials.username}
          onChange={handleChange}
          placeholder='Username'
          required
        />
        <Input
          type='password'
          name='password'
          value={credentials.password}
          onChange={handleChange}
          placeholder='Password'
          required
        />
        <Button data-testid='login-submit' type='submit'>
          Login
        </Button>
      </form>
    </LoginContainer>
  );
};
export default Login;
