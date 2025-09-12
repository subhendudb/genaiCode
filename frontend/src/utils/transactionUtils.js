export const filterTransactions = (transactions, filters) => {
  return transactions.filter(transaction => {
    // Filter by account
    if (filters.account &&
      transaction.account_id !== filters.account &&
      transaction.contra_account_id !== filters.account) {
      return false;
    }
    // Filter by type (you would need to determine type based on account types)
    if (filters.type) {
      // Implementation depends on your account structure
    }
    // Filter by date range
    const transactionDate = new Date(transaction.transaction_date);
    const now = new Date();
    if (filters.dateRange === '7days') {
      const sevenDaysAgo = new Date(now.setDate(now.getDate() - 7));
      return transactionDate >= sevenDaysAgo;
    }
    if (filters.dateRange === '30days') {
      const thirtyDaysAgo = new Date(now.setDate(now.getDate() - 30));
      return transactionDate >= thirtyDaysAgo;
    }
    if (filters.dateRange === '90days') {
      const ninetyDaysAgo = new Date(now.setDate(now.getDate() - 90));
      return transactionDate >= ninetyDaysAgo;
    }
    return true;
  });
};

export const sortTransactions = (transactions, sortBy = 'date', ascending = false) => {
  return [...transactions].sort((a, b) => {
    const dateA = new Date(a.transaction_date);
    const dateB = new Date(b.transaction_date);
    if (sortBy === 'date') {
      return ascending ? dateA - dateB : dateB - dateA;
    }
    if (sortBy === 'amount') {
      return ascending ? a.amount - b.amount : b.amount - a.amount;
    }
    return 0;
  });
}; 