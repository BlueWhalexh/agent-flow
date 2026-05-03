import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Form, Input, message } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import http from '@/utils/http';
import './style.scss';

const LoginPage = () => {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const onFinish = async (values: { username: string; password: string }) => {
    setLoading(true);
    try {
      const response = await http.post('/api/login', {
        username: values.username,
        password: values.password,
      });

      if (response.accessToken) {
        localStorage.setItem('accessToken', response.accessToken);
        if (response.refreshToken) {
          localStorage.setItem('refreshToken', response.refreshToken);
        } else {
          localStorage.removeItem('refreshToken');
        }
        message.success('Login successful');
        navigate('/home');
      } else {
        message.error('Login failed, please try again');
      }
    } catch (error: any) {
      message.error(error?.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-header">
          <h1>PaiFlow</h1>
          <p>Local account sign in</p>
        </div>
        <Form
          name="login"
          className="login-form"
          onFinish={onFinish}
          autoComplete="off"
        >
          <Form.Item
            name="username"
            rules={[{ required: true, message: 'Please enter username' }]}
          >
            <Input
              prefix={<UserOutlined />}
              placeholder="Username"
              size="large"
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[{ required: true, message: 'Please enter password' }]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder="Password"
              size="large"
            />
          </Form.Item>

          <Form.Item>
            <Button
              type="primary"
              htmlType="submit"
              className="login-button"
              size="large"
              loading={loading}
              block
            >
              Sign in
            </Button>
          </Form.Item>
        </Form>
      </div>
    </div>
  );
};

export default LoginPage;
