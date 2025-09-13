import styled from 'styled-components';
const ToggleContainer = styled.label`
  position: relative;
  display: inline-block;
  width: 50px;
  height: 24px;
`;
const ToggleInput = styled.input`
  opacity: 0;
  width: 0;
  height: 0;
  &:checked + span {
    background-color: ${({ theme }) => theme.primary};
  }
  &:checked + span:before {
    transform: translateX(26px);
  }
`;
const ToggleSlider = styled.span`
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: ${({ theme }) => theme.textSecondary};
  transition: 0.4s;
  border-radius: 24px;
  &:before {
    position: absolute;
    content: '';
    height: 16px;
    width: 16px;
    left: 4px;
    bottom: 4px;
    background-color: white;
    transition: 0.4s;
    border-radius: 50%;
  }
`;
const Toggle = ({ checked, onChange }) => {
  return (
    <ToggleContainer>
      <ToggleInput type='checkbox' checked={checked} onChange={onChange} />
      <ToggleSlider />
    </ToggleContainer>
  );
};
export default Toggle;
