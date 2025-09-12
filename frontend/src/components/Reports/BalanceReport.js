import React, { useEffect, useState } from 'react';
import styled from 'styled-components';
import { Card } from '../UI';
import useApi from '../../hooks/useApi';
import { format } from 'date-fns';

const ReportContainer = styled.div`
  margin-top: 20px;
`;

const ReportHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
`;

const ReportTitle = styled.h2`
  color: ${({ theme }) => theme.primary};
`;

const ReportDate = styled.span`
  color: ${({ theme }) => theme.textSecondary};
  font-size: 0.9rem;
`;

const AccountTypeSection = styled.div`
  margin-bottom: 30px;
`;

const AccountTypeTitle = styled.h3`
  border-bottom: 1px solid ${({ theme }) => theme.border};
  padding-bottom: 8px;
  margin-bottom: 15px;
`;

const AccountRow = styled.div`
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px dashed ${({ theme }) => theme.border};
  &:last-child {
    border-bottom: none;
  }
`;

const AccountName = styled.span`
  flex: 2;
`;

const AccountBalance = styled.span`
  flex: 1;
  text-align: right;
  font-weight: ${({ bold }) => bold ? 'bold' : 'normal'};
  color: ${({ positive, theme }) => positive ? theme.primary : '#e74c3c'};
`;

const TotalRow = styled.div`
  display: flex;
  justify-content: space-between;
  padding: 15px 0;
  margin-top: 10px;
  border-top: 2px solid ${({ theme }) => theme.primary};
  font-weight: bold;
  font-size: 1.1rem;
`;

const BalanceReport = () => {
  const [reportData, setReportData] = useState(null);
  const [loading, setLoading] = useState(true);
  const { get } = useApi();

  useEffect(() => {
    const fetchBalanceReport = async () => {
      try {
        const response = await get('/api/reports/balance');
        setReportData(response.data);
      } catch (error) {
        console.error('Error fetching balance report:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchBalanceReport();
  }, [get]);

  if (loading) return <Card>Loading balance report...</Card>;
  if (!reportData) return <Card>Error loading balance report</Card>;

  const accountTypes = ['ASSET', 'LIABILITY', 'INCOME', 'EXPENSE'];

  return (
    <ReportContainer>
      <Card>
        <ReportHeader>
          <ReportTitle>Balance Sheet Report</ReportTitle>
          <ReportDate>
            As of {format(new Date(reportData.report_date), 'MMMM d, yyyy')}
          </ReportDate>
        </ReportHeader>
        {accountTypes.map(type => (
          <AccountTypeSection key={type}>
            <AccountTypeTitle>
              {type.charAt(0) + type.slice(1).toLowerCase()} Accounts
            </AccountTypeTitle>
            {reportData.accounts
              .filter(account => account.type === type)
              .map(account => (
                <AccountRow key={account.id}>
                  <AccountName>{account.name}</AccountName>
                  <AccountBalance
                    positive={account.current_balance >= 0}
                  >
                    {account.current_balance >= 0 ? '' : '('}
                    ${Math.abs(account.current_balance).toFixed(2)}
                    {account.current_balance >= 0 ? '' : ')'}
                  </AccountBalance>
                </AccountRow>
              ))}
            <TotalRow>
              <span>Total {type.charAt(0) + type.slice(1).toLowerCase()}</span>
              <AccountBalance
                bold
                positive={reportData.totals[type] >= 0}
              >
                ${Math.abs(reportData.totals[type]).toFixed(2)}
              </AccountBalance>
            </TotalRow>
          </AccountTypeSection>
        ))}
        <TotalRow>
          <span>Net Worth</span>
          <AccountBalance bold positive={reportData.net_worth >= 0}>
            ${Math.abs(reportData.net_worth).toFixed(2)}
          </AccountBalance>
        </TotalRow>
      </Card>
    </ReportContainer>
  );
};
export default BalanceReport; 