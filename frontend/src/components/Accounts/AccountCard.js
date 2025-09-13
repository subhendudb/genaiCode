import React from 'react';
import styled from 'styled-components';
import { useNavigate } from 'react-router-dom';
import { Card } from '../UI';
import Button from '../UI/Button';

const AccountCardContainer = styled(Card)`
  padding: 20px;
  transition: transform 0.2s;
  cursor: pointer;
  border-left: 4px solid
    ${({ theme, accountType }) =>
      accountType === 'ASSET'
        ? '#2ecc71'
        : accountType === 'LIABILITY'
        ? '#e74c3c'
        : accountType === 'INCOME'
        ? '#3498db'
        : '#f39c12'};
  &:hover {
    transform: translateY(-5px);
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }
`;

const AccountHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
`;

const AccountName = styled.h3`
  margin: 0;
  font-size: 1.1rem;
`;

const AccountType = styled.span`
  font-size: 0.8rem;
  padding: 3px 8px;
  border-radius: 4px;
  background-color: ${({ theme }) => theme.primary}20;
  color: ${({ theme }) => theme.primary};
`;

const AccountBalance = styled.p`
  font-size: 1.5rem;
  font-weight: bold;
  margin: 10px 0;
  color: ${({ positive, theme }) => (positive ? theme.primary : '#e74c3c')};
`;

const AccountMeta = styled.div`
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
  color: ${({ theme }) => theme.textSecondary};
`;

const AccountCard = ({ account }) => {
  const navigate = useNavigate();
  const handleClick = () => {
    navigate(`/accounts/${account.id}`);
  };
  const isPositive = parseFloat(account.current_balance) >= 0;
  return (
    <AccountCardContainer
      className='account-card'
      onClick={handleClick}
      accountType={account.type}
    >
      <AccountHeader>
        <AccountName>{account.name}</AccountName>
        <AccountType>{account.type}</AccountType>
      </AccountHeader>
      <AccountBalance positive={isPositive}>
        ${Math.abs(parseFloat(account.current_balance)).toFixed(2)}
        {!isPositive && ' (DR)'}
      </AccountBalance>
      {account.description && <p>{account.description}</p>}
      <AccountMeta>
        <span>
          Created: {new Date(account.created_at).toLocaleDateString()}
        </span>
        <span>
          Last updated: {new Date(account.updated_at).toLocaleDateString()}
        </span>
      </AccountMeta>
      <Button onClick={() => navigate(`/accounts/${account.id}`)}>
        View / Edit
      </Button>
    </AccountCardContainer>
  );
};
export default AccountCard;
