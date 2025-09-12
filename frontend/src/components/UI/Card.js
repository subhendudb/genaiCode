import styled from 'styled-components';
const Card = styled.div`
  background-color: ${({ theme }) => theme.cardBackground};
  border-radius: 12px;
  box-shadow: ${({ theme }) => theme.shadow};
  padding: ${({ padding }) => padding || '20px'};
  transition: all 0.3s ease;
  border: 1px solid ${({ theme }) => theme.border};
  margin-bottom: ${({ marginBottom }) => marginBottom || '0'};
  width: ${({ width }) => width || 'auto'};
  ${({ hoverEffect }) => hoverEffect && `
    &:hover {
      box-shadow: 0 4px 8px rgba(0,0,0,0.1);
      transform: translateY(-2px);
    }
  `}
`;
export default Card; 