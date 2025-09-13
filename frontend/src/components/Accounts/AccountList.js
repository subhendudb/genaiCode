import React from 'react';
import styled from 'styled-components';
import AccountCard from './AccountCard';
import { Card } from '../UI';

const ListContainer = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 30px;
`;

const SummaryCard = styled(Card)`
  grid-column: 1 / -1;
  display: flex;
  justify-content: space-between;
  padding: 20px;
  background-color: ${({ theme }) => theme.primary}10;
  border-left: 4px solid ${({ theme }) => theme.primary};
`;

const AccountList = ({ accounts }) => {
  // Calculate summary statistics
  const totalAccounts = accounts.length;
  const totalBalance = accounts.reduce((sum, account) => {
    const balance = parseFloat(account.current_balance);
    return sum + (isNaN(balance) ? 0 : balance);
  }, 0);

  // Format currency
  const formattedBalance = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(totalBalance);

  return (
    <>
      <SummaryCard>
        <div>
          <h3>Total Accounts</h3>
          <p>{totalAccounts}</p>
        </div>
        <div>
          <h3>Total Balance</h3>
          <p>{formattedBalance}</p>
        </div>
      </SummaryCard>
      <ListContainer>
        {accounts.length === 0 ? (
          <Card>No accounts found.</Card>
        ) : (
          accounts.map(account => (
            <AccountCard key={account.id} account={account} />
          ))
        )}
      </ListContainer>
    </>
  );
};
export default AccountList;
