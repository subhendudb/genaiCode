import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from 'styled-components';
import { GlobalStyles } from './styles/GlobalStyles';
import { lightTheme, darkTheme } from './theme';
import Layout from './components/Layout/Layout';
import Accounts from './components/Accounts/Accounts';
import Transactions from './components/Transactions/Transactions';
import Reports from './components/Reports/Reports';
import Login from './components/Auth/Login';
import { AuthProvider } from './context/AuthContext';
import AccountDetail from './components/Accounts/AccountDetail';

function App() {
  const [theme, setTheme] = useState('light');
  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };
  return (
    <ThemeProvider theme={theme === 'light' ? lightTheme : darkTheme}>
      <GlobalStyles />

      <Router>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/" element={
              <Layout theme={theme} toggleTheme={toggleTheme} />
            }>
              <Route path="accounts" element={<Accounts />} />
              <Route path="accounts/:id" element={<AccountDetail />} />
              <Route path="transactions" element={<Transactions />} />
              <Route path="reports" element={<Reports />} />
            </Route>
          </Routes>
        </AuthProvider>
      </Router>
    </ThemeProvider>
  );
}
export default App; 