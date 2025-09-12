import React from 'react';
import styled from 'styled-components';
const RightPanelContainer = styled.div`
  background-color: ${({ theme }) => theme.cardBackground};
  padding: 20px;
  border-left: 1px solid ${({ theme }) => theme.border};
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  @media (max-width: 1024px) {
    display: none;
  }
`;
const RightPanel = () => {
  return (
    <RightPanelContainer>
      <h3>Quick Actions</h3>
      <p>Recent transactions and account balances will appear here.</p>
      {/* You can add more quick action components here */}
    </RightPanelContainer>
  );
};
export default RightPanel; 