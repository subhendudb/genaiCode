import styled from 'styled-components';
const Input = styled.input`
  width: 100%;
  padding: 10px 15px;
  border: 1px solid ${({ theme }) => theme.border};
  border-radius: 6px;
  font-size: 16px;
  transition: all 0.3s;
  background-color: ${({ theme }) =>
    theme.inputBackground || theme.cardBackground};
  color: ${({ theme }) => theme.text};
  margin-bottom: 15px;
  &:focus {
    outline: none;
    border-color: ${({ theme }) => theme.primary};
    box-shadow: 0 0 0 2px ${({ theme }) => theme.primary}20;
  }
  &::placeholder {
    color: ${({ theme }) => theme.textSecondary || '#888'};
    opacity: 0.7;
  }
  ${({ error }) =>
    error &&
    `
    border-color: #e74c3c;
    &:focus {
      box-shadow: 0 0 0 2px rgba(231, 76, 60, 0.2);
    }
  `}
`;
export default Input;
