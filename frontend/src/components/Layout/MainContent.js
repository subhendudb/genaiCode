import React from 'react';
import styled from 'styled-components';
const MainContentContainer = styled.main`
  padding: 20px;
  overflow-y: auto;
  max-height: 100vh;
  @media (max-width: 768px) {
    max-height: none;
    padding: 15px;
  }
`;
const MainContent = ({ children }) => {
  return <MainContentContainer>{children}</MainContentContainer>;
};
export default MainContent;
