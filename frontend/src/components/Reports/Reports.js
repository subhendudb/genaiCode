import React, { useState } from 'react';
import styled from 'styled-components';
import BalanceReport from './BalanceReport';
import ProfitLossReport from './ProfitLossReport';
import { Button } from '../UI';

const ReportsContainer = styled.div`
  max-width: 1200px;
  margin: 0 auto;
`;

const ReportSelector = styled.div`
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
`;

const Reports = () => {
  const [activeReport, setActiveReport] = useState('balance');
  return (
    <ReportsContainer>
      <h1>Financial Reports</h1>
      <ReportSelector>
        <Button
          onClick={() => setActiveReport('balance')}
          active={activeReport === 'balance'}
        >
          Balance Report
        </Button>
        <Button
          onClick={() => setActiveReport('profit-loss')}
          active={activeReport === 'profit-loss'}
        >
          Profit & Loss
        </Button>
      </ReportSelector>
      {activeReport === 'balance' && <BalanceReport />}
      {activeReport === 'profit-loss' && <ProfitLossReport />}
    </ReportsContainer>
  );
};
export default Reports;
