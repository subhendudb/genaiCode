import React, { useEffect, useState, useContext } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import useApi from '../../hooks/useApi';
import Input from '../UI/Input';
import Button from '../UI/Button';

const AccountDetail = () => {
  const { id } = useParams(); // expects route like /accounts/:id
  const navigate = useNavigate();
  const { get, put } = useApi();

  const [account, setAccount] = useState(null);
  const [form, setForm] = useState({ name: '', description: '' });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Fetch account details
  useEffect(() => {
    const fetchAccount = async () => {
      setLoading(true);
      try {
        const res = await get(`/api/accounts/${id}`);
        // Axios response: data is in res.data
        setAccount(res.data);
        setForm({
          name: res.data.name,
          description: res.data.description || '',
        });
      } catch (err) {
        setError(err.response?.data?.error || err.message);
      }
      setLoading(false);
    };
    fetchAccount();
  }, [id, get]);

  // Handle form changes
  const handleChange = e => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  // Handle update
  const handleUpdate = async e => {
    e.preventDefault();
    setError('');
    try {
      const res = await put(`/api/accounts/${id}`, form);
      setAccount(res.data);
      alert('Account updated!');
    } catch (err) {
      setError(err.response?.data?.error || err.message);
    }
  };

  if (loading) return <div>Loading...</div>;
  if (error) return <div style={{ color: 'red' }}>{error}</div>;
  if (!account) return <div>Account not found.</div>;

  return (
    <div>
      <h2>Account Details</h2>
      <form onSubmit={handleUpdate}>
        <Input
          label='Name'
          name='name'
          value={form.name}
          onChange={handleChange}
          required
        />
        <Input
          label='Description'
          name='description'
          value={form.description}
          onChange={handleChange}
        />
        <div>
          <label>Name:</label> {account.name}
        </div>
        <div>
          <label>Description:</label> {account.description}
        </div>
        <div>
          <strong>Type:</strong> {account.type}
        </div>
        <div>
          <strong>Opening Balance:</strong> {account.opening_balance}
        </div>
        <div>
          <strong>Current Balance:</strong> {account.current_balance}
        </div>
        <Button type='submit'>Update</Button>
        <Button
          type='button'
          onClick={() => navigate(-1)}
          style={{ marginLeft: 8 }}
        >
          Back
        </Button>
      </form>
    </div>
  );
};

export default AccountDetail;
