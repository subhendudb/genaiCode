import React, { useState } from 'react';
import styled from 'styled-components';
import { Button, Input } from '../UI';
import useApi from '../../hooks/useApi';

const FormContainer = styled.div`
  background: ${({ theme }) => theme.cardBackground};
  padding: 20px;
  border-radius: 12px;
  box-shadow: ${({ theme }) => theme.shadow};
  margin-bottom: 20px;
`;

const AccountForm = ({ onAccountCreated }) => {
  const [formData, setFormData] = useState({
    name: '',
    type: 'ASSET',
    description: '',
    opening_balance: '0.00',
  });
  const { post } = useApi();
  const handleChange = e => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };
  const handleSubmit = async e => {
    e.preventDefault();
    try {
      const response = await post('/api/accounts', formData);
      onAccountCreated(response.data);
      setFormData({
        name: '',
        type: 'ASSET',
        description: '',
        opening_balance: '0.00',
      });
    } catch (error) {
      console.error('Error creating account:', error);
    }
  };
  return (
    <FormContainer>
      <h3>Create New Account</h3>
      <form onSubmit={handleSubmit}>
        <Input
          name='name'
          value={formData.name}
          onChange={handleChange}
          placeholder='Account Name'
          required
        />
        <select
          name='type'
          value={formData.type}
          onChange={handleChange}
          required
        >
          <option value='ASSET'>Asset</option>
          <option value='LIABILITY'>Liability</option>
          <option value='INCOME'>Income</option>
          <option value='EXPENSE'>Expense</option>
        </select>
        <Input
          name='description'
          value={formData.description}
          onChange={handleChange}
          placeholder='Description'
        />
        <Input
          type='number'
          name='opening_balance'
          value={formData.opening_balance}
          onChange={handleChange}
          placeholder='Opening Balance'
          step='0.01'
          min='0'
          required
        />
        <Button type='submit'>Create Account</Button>
      </form>
    </FormContainer>
  );
};
export default AccountForm;
