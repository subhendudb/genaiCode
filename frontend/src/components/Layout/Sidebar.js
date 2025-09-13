import React from 'react';
import styled from 'styled-components';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const SidebarContainer = styled.aside`
  background-color: ${({ theme }) => theme.cardBackground};
  padding: 20px;
  border-right: 1px solid ${({ theme }) => theme.border};
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  @media (max-width: 768px) {
    height: auto;
    border-right: none;
    border-bottom: 1px solid ${({ theme }) => theme.border};
  }
`;
const NavList = styled.ul`
  list-style: none;
  padding: 0;
`;
const NavItem = styled.li`
  margin-bottom: 10px;
`;
const StyledNavLink = styled(NavLink)`
  display: block;
  padding: 10px 15px;
  border-radius: 6px;
  color: ${({ theme }) => theme.text};
  text-decoration: none;
  transition: all 0.2s;
  &:hover {
    background-color: ${({ theme }) => theme.primary}20;
  }
  &.active {
    background-color: ${({ theme }) => theme.primary};
    color: white;
  }
`;
const Sidebar = () => {
  const { logout } = useAuth();
  return (
    <SidebarContainer>
      <nav>
        <NavList>
          <NavItem>
            <StyledNavLink to='/accounts'>Accounts</StyledNavLink>
          </NavItem>
          <NavItem>
            <StyledNavLink to='/transactions'>Transactions</StyledNavLink>
          </NavItem>
          <NavItem>
            <StyledNavLink to='/reports'>Reports</StyledNavLink>
          </NavItem>
          <NavItem>
            <StyledNavLink as='button' onClick={logout} data-testid='logout'>
              Logout
            </StyledNavLink>
          </NavItem>
        </NavList>
      </nav>
    </SidebarContainer>
  );
};
export default Sidebar;
