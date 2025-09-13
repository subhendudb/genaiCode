import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { Button, Input } from '../UI';
import useApi from '../../hooks/useApi';
import { format } from 'date-fns';

const FormContainer = styled.div`
  background: ${({ theme }) => theme.cardBackground};
  padding: 20px;
  border-radius: 12px;
  box-shadow: ${({ theme }) => theme.shadow};
  margin-bottom: 20px;
`;

const TransactionForm = ({ accounts, onTransactionCreated }) => {
  const [formData, setFormData] = useState({
    account_id: '',
    contra_account_id: '',
    transaction_date: format(new Date(), 'yyyy-MM-dd'),
    amount: '0.00',
    description: '',
    reference_number: '',
  });
  const { post } = useApi();

  useEffect(() => {
    if (accounts.length > 1) {
      setFormData(prev => ({
        ...prev,
        account_id: accounts[0]?.id || '',
        contra_account_id: accounts[1]?.id || '',
      }));
    }
  }, [accounts]);

  const handleChange = e => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async e => {
    e.preventDefault();
    if (formData.account_id === formData.contra_account_id) {
      alert('Account and Contra Account must be different');
      return;
    }
    try {
      const response = await post('/api/transactions', formData);
      onTransactionCreated(response.data.transaction);
      setFormData(prev => ({
        ...prev,
        amount: '0.00',
        description: '',
        reference_number: '',
      }));
    } catch (error) {
      console.error('Error creating transaction:', error);
    }
  };

  return (
    <FormContainer>
      <h3>Record New Transaction</h3>
      <form onSubmit={handleSubmit}>
        <div>
          <label>From Account:</label>
          <select
            name='account_id'
            value={formData.account_id}
            onChange={handleChange}
            required
          >
            {accounts.map(account => (
              <option key={account.id} value={account.id}>
                {account.name} ({account.type})
              </option>
            ))}
          </select>
        </div>
        <div>
          <label>To Account:</label>
          <select
            name='contra_account_id'
            value={formData.contra_account_id}
            onChange={handleChange}
            required
          >
            {accounts.map(account => (
              <option key={account.id} value={account.id}>
                {account.name} ({account.type})
              </option>
            ))}
          </select>
        </div>
        <Input
          type='date'
          name='transaction_date'
          value={formData.transaction_date}
          onChange={handleChange}
          required
        />
        <Input
          type='number'
          name='amount'
          value={formData.amount}
          onChange={handleChange}
          placeholder='Amount'
          step='0.01'
          min='0.01'
          required
        />
        <Input
          name='description'
          value={formData.description}
          onChange={handleChange}
          placeholder='Description'
          maxLength='500'
        />
        <Input
          name='reference_number'
          value={formData.reference_number}
          onChange={handleChange}
          placeholder='Reference Number'
          maxLength='100'
        />
        <Button type='submit'>Record Transaction</Button>
      </form>
    </FormContainer>
  );
};
export default TransactionForm;
