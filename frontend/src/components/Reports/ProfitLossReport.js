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

const DateRange = styled.span`
  color: ${({ theme }) => theme.textSecondary};
  font-size: 0.9rem;
`;

const SummaryCard = styled(Card)`
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  padding: 20px;
  margin-bottom: 30px;
  text-align: center;
  @media (max-width: 768px) {
    grid-template-columns: 1fr;
  }
`;

const SummaryItem = styled.div`
  padding: 15px;
`;

const SummaryLabel = styled.div`
  font-size: 0.9rem;
  color: ${({ theme }) => theme.textSecondary};
  margin-bottom: 5px;
`;

const SummaryValue = styled.div`
  font-size: 1.5rem;
  font-weight: bold;
  color: ${({ positive, theme }) => (positive ? theme.primary : '#e74c3c')};
`;

const Section = styled.div`
  margin-bottom: 30px;
`;

const SectionTitle = styled.h3`
  border-bottom: 1px solid ${({ theme }) => theme.border};
  padding-bottom: 8px;
  margin-bottom: 15px;
`;

const ItemRow = styled.div`
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px dashed ${({ theme }) => theme.border};
`;

const ItemName = styled.span`
  flex: 2;
`;

const ItemAmount = styled.span`
  flex: 1;
  text-align: right;
`;

const ProfitLossReport = () => {
  const [reportData, setReportData] = useState(null);
  const [loading, setLoading] = useState(true);
  const { get } = useApi();

  useEffect(() => {
    const fetchProfitLossReport = async () => {
      try {
        // Default to last 30 days
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(endDate.getDate() - 30);
        const response = await get('/api/reports/profit-loss', {
          start_date: format(startDate, 'yyyy-MM-dd'),
          end_date: format(endDate, 'yyyy-MM-dd'),
        });
        setReportData(response.data);
      } catch (error) {
        // console.error('Error fetching profit/loss report:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchProfitLossReport();
  }, [get]);

  if (loading) return <Card>Loading profit/loss report...</Card>;
  if (!reportData) return <Card>Error loading profit/loss report</Card>;

  return (
    <ReportContainer>
      <Card>
        <ReportHeader>
          <ReportTitle>Profit & Loss Statement</ReportTitle>
          <DateRange>
            {format(new Date(reportData.start_date), 'MMM d, yyyy')} -{' '}
            {format(new Date(reportData.end_date), 'MMM d, yyyy')}
          </DateRange>
        </ReportHeader>
        <SummaryCard>
          <SummaryItem>
            <SummaryLabel>Total Income</SummaryLabel>
            <SummaryValue positive>
              ${reportData.total_income.toFixed(2)}
            </SummaryValue>
          </SummaryItem>
          <SummaryItem>
            <SummaryLabel>Total Expenses</SummaryLabel>
            <SummaryValue positive={false}>
              (${reportData.total_expenses.toFixed(2)})
            </SummaryValue>
          </SummaryItem>
          <SummaryItem>
            <SummaryLabel>Net Profit/Loss</SummaryLabel>
            <SummaryValue positive={reportData.net_profit_loss >= 0}>
              {reportData.net_profit_loss >= 0 ? '$' : '($'}
              {Math.abs(reportData.net_profit_loss).toFixed(2)}
              {reportData.net_profit_loss >= 0 ? '' : ')'}
            </SummaryValue>
          </SummaryItem>
        </SummaryCard>
        <Section>
          <SectionTitle>Income</SectionTitle>
          {/* In a real app, you would group income by category */}
          <ItemRow>
            <ItemName>Total Income</ItemName>
            <ItemAmount>${reportData.total_income.toFixed(2)}</ItemAmount>
          </ItemRow>
        </Section>
        <Section>
          <SectionTitle>Expenses</SectionTitle>
          {/* In a real app, you would list expense categories */}
          <ItemRow>
            <ItemName>Total Expenses</ItemName>
            <ItemAmount>(${reportData.total_expenses.toFixed(2)})</ItemAmount>
          </ItemRow>
        </Section>
        <Section>
          <SectionTitle>Net Profit/Loss</SectionTitle>
          <ItemRow>
            <ItemName>Net Result</ItemName>
            <ItemAmount>
              {reportData.net_profit_loss >= 0 ? '$' : '($'}
              {Math.abs(reportData.net_profit_loss).toFixed(2)}
              {reportData.net_profit_loss >= 0 ? '' : ')'}
            </ItemAmount>
          </ItemRow>
        </Section>
      </Card>
    </ReportContainer>
  );
};
export default ProfitLossReport;
