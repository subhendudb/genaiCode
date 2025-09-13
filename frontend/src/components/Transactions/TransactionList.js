import React, { useState } from 'react';
import styled from 'styled-components';
import TransactionCard from './TransactionCard';
import { Card } from '../UI';

const ListContainer = styled.div`
  margin-top: 30px;
`;

const FiltersContainer = styled(Card)`
  padding: 15px;
  margin-bottom: 20px;
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
`;

const FilterGroup = styled.div`
  display: flex;
  flex-direction: column;
  min-width: 200px;
`;

const FilterLabel = styled.label`
  font-size: 0.8rem;
  margin-bottom: 5px;
  color: ${({ theme }) => theme.textSecondary};
`;

const FilterSelect = styled.select`
  padding: 8px;
  border-radius: 6px;
  border: 1px solid ${({ theme }) => theme.border};
  background-color: ${({ theme }) => theme.cardBackground};
  color: ${({ theme }) => theme.text};
`;

const TransactionList = ({ transactions, accounts }) => {
  const [filters, setFilters] = useState({
    account: '',
    type: '',
    dateRange: '30days',
  });

  // Helper to get date threshold
  const getDateThreshold = range => {
    switch (range) {
      case '7days':
        return new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      case '30days':
        return new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      case '90days':
        return new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
      default:
        return null;
    }
  };

  const filteredTransactions = transactions.filter(transaction => {
    // Account filter
    if (
      filters.account &&
      String(transaction.accountId) !== String(filters.account)
    )
      return false;
    // Type filter
    if (filters.type && transaction.type !== filters.type) return false;
    // Date range filter
    if (filters.dateRange !== 'all') {
      const threshold = getDateThreshold(filters.dateRange);
      if (threshold && new Date(transaction.date) < threshold) return false;
    }
    return true;
  });

  return (
    <ListContainer>
      <FiltersContainer>
        <FilterGroup>
          <FilterLabel>Account</FilterLabel>
          <FilterSelect
            value={filters.account}
            onChange={e => setFilters({ ...filters, account: e.target.value })}
          >
            <option value=''>All Accounts</option>
            {accounts &&
              accounts.map(account => (
                <option key={account.id} value={account.id}>
                  {account.name}
                </option>
              ))}
          </FilterSelect>
        </FilterGroup>
        <FilterGroup>
          <FilterLabel>Transaction Type</FilterLabel>
          <FilterSelect
            value={filters.type}
            onChange={e => setFilters({ ...filters, type: e.target.value })}
          >
            <option value=''>All Types</option>
            <option value='income'>Income</option>
            <option value='expense'>Expense</option>
            <option value='transfer'>Transfer</option>
          </FilterSelect>
        </FilterGroup>
        <FilterGroup>
          <FilterLabel>Date Range</FilterLabel>
          <FilterSelect
            value={filters.dateRange}
            onChange={e =>
              setFilters({ ...filters, dateRange: e.target.value })
            }
          >
            <option value='7days'>Last 7 Days</option>
            <option value='30days'>Last 30 Days</option>
            <option value='90days'>Last 90 Days</option>
            <option value='all'>All Time</option>
          </FilterSelect>
        </FilterGroup>
      </FiltersContainer>
      {filteredTransactions.length === 0 ? (
        <Card>
          <p>No transactions found</p>
        </Card>
      ) : (
        filteredTransactions.map(transaction => (
          <TransactionCard key={transaction.id} transaction={transaction} />
        ))
      )}
    </ListContainer>
  );
};
export default TransactionList;
