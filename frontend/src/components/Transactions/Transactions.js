import React, { useEffect, useState } from 'react';
import TransactionForm from './TransactionForm';
import TransactionList from './TransactionList';
import useApi from '../../hooks/useApi';
import { Card } from '../UI';

const Transactions = () => {
  const [transactions, setTransactions] = useState([]);
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const { get } = useApi();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [accountsRes, transactionsRes] = await Promise.all([
          get('/api/accounts'),
          get('/api/transactions')
        ]);
        setAccounts(accountsRes.data);
        setTransactions(transactionsRes.data);
        //console.log(transactionsRes.data)
      } catch (error) {
        console.error('Error fetching transactions or accounts:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [get]);

  const handleTransactionCreated = (newTransaction) => {
    setTransactions(prev => [newTransaction, ...prev]);
  };

  if (loading) return <Card>Loading transactions...</Card>;

  return (
    <div>
      <TransactionForm accounts={accounts} onTransactionCreated={handleTransactionCreated} />
      <TransactionList transactions={transactions} accounts={accounts} />
    </div>
  );
};
export default Transactions;