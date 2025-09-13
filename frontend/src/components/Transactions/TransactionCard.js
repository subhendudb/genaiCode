import React from 'react';
import styled from 'styled-components';
import { useNavigate } from 'react-router-dom';
import { Card } from '../UI';
import { format } from 'date-fns';

const TransactionCardContainer = styled(Card)`
  padding: 15px;
  margin-bottom: 15px;
  border-left: 4px solid
    ${({ theme, isVoid }) => (isVoid ? theme.textSecondary : theme.primary)};
  opacity: ${({ isVoid }) => (isVoid ? 0.7 : 1)};
  transition: all 0.2s;
  cursor: pointer;
  &:hover {
    transform: translateX(5px);
  }
`;

const TransactionHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
`;

const TransactionAmount = styled.div`
  font-size: 1.2rem;
  font-weight: bold;
  color: ${({ theme, isNegative }) => (isNegative ? '#e74c3c' : theme.primary)};
`;

const TransactionDate = styled.span`
  font-size: 0.8rem;
  color: ${({ theme }) => theme.textSecondary};
`;

const TransactionDescription = styled.p`
  margin: 5px 0;
  font-weight: 500;
`;

const TransactionAccounts = styled.div`
  display: flex;
  justify-content: space-between;
  font-size: 0.9rem;
  margin-top: 10px;
`;

const AccountInfo = styled.div`
  flex: 1;
  padding: 5px;
  border-radius: 4px;
  background-color: ${({ theme, isFrom }) =>
    isFrom ? theme.primary + '10' : theme.secondary + '10'};
`;

const AccountLabel = styled.span`
  font-size: 0.7rem;
  display: block;
  color: ${({ theme }) => theme.textSecondary};
`;

const VoidBadge = styled.span`
  font-size: 0.7rem;
  padding: 2px 5px;
  background-color: ${({ theme }) => theme.textSecondary};
  color: white;
  border-radius: 4px;
  margin-left: 10px;
`;

const TransactionCard = ({ transaction }) => {
  const navigate = useNavigate();
  const handleClick = () => {
    navigate(`/transactions/${transaction.id}`);
  };
  const isNegative = parseFloat(transaction.amount) < 0;
  const formattedDate = format(
    new Date(transaction.transaction_date),
    'MMM dd, yyyy',
  );
  const formattedAmount = Math.abs(parseFloat(transaction.amount)).toFixed(2);
  return (
    <TransactionCardContainer
      onClick={handleClick}
      isVoid={transaction.is_void}
    >
      <TransactionHeader>
        <div>
          <TransactionDate>{formattedDate}</TransactionDate>
          <TransactionDescription>
            {transaction.description}
            {transaction.is_void && <VoidBadge>VOIDED</VoidBadge>}
          </TransactionDescription>
        </div>
        <TransactionAmount isNegative={isNegative}>
          {isNegative ? '-' : ''}${formattedAmount}
        </TransactionAmount>
      </TransactionHeader>
      <TransactionAccounts>
        <AccountInfo isFrom={true}>
          <AccountLabel>From</AccountLabel>
          {transaction.contra_account_name || 'Unknown Account'}
        </AccountInfo>
        <AccountInfo isFrom={false}>
          <AccountLabel>To</AccountLabel>
          {transaction.account_name || 'Unknown Account'}
        </AccountInfo>
      </TransactionAccounts>
      {transaction.reference_number && (
        <div style={{ fontSize: '0.8rem', marginTop: '10px' }}>
          Reference: {transaction.reference_number}
        </div>
      )}
    </TransactionCardContainer>
  );
};
export default TransactionCard;
