import React, { useEffect, useState } from 'react';
import AccountForm from './AccountForm';
import AccountList from './AccountList';
import useApi from '../../hooks/useApi';
import { Card } from '../UI';

const Accounts = () => {
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const { get } = useApi();

  useEffect(() => {
    const fetchAccounts = async () => {
      try {
        const response = await get('/api/accounts');
        // console.log(response.data);
        // Defensive: fallback to empty array if response is malformed
        setAccounts(response?.data || []);
      } catch (error) {
        // console.error('Error fetching accounts:', error);
        setAccounts([]); // Ensure accounts is always an array
      } finally {
        setLoading(false);
      }
    };
    fetchAccounts();
  }, [get]);

  const handleAccountCreated = newAccount => {
    setAccounts(prev => [...prev, newAccount]);
  };

  if (loading) return <Card>Loading accounts...</Card>;

  return (
    <div>
      <AccountForm onAccountCreated={handleAccountCreated} />
      <AccountList accounts={accounts} />
    </div>
  );
};
export default Accounts;
