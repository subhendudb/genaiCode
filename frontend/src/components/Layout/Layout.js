import React from 'react';
import styled from 'styled-components';
import Sidebar from './Sidebar';
import MainContent from './MainContent';
import RightPanel from './RightPanel';
import { Button } from '../UI';
import { Outlet } from 'react-router-dom';
const LayoutContainer = styled.div`
  display: grid;
  grid-template-columns: 200px 1fr 300px;
  min-height: 100vh;
  background-color: ${({ theme }) => theme.background};
  @media (max-width: 1024px) {
    grid-template-columns: 80px 1fr;
    grid-template-rows: auto 1fr;
  }
  @media (max-width: 768px) {
    grid-template-columns: 1fr;
    grid-template-rows: auto 1fr auto;
  }
`;
const ThemeToggle = styled(Button)`
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 1000;
`;
function Layout({ theme, toggleTheme }) {
  return (
    <LayoutContainer>
      <Sidebar />
      <MainContent><Outlet /></MainContent>
      <RightPanel />
      <ThemeToggle onClick={toggleTheme}>
        {theme === 'light' ? '🌙' : '☀'}
      </ThemeToggle>
    </LayoutContainer>
  );
}
export default Layout; 