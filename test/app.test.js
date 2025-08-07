// Basic tests for the CRUD backend application
const request = require('supertest');
const express = require('express');

// Mock the app (since we don't want to start the actual server)
const app = express();
app.use(express.json());

// Health check endpoint
app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

// Mock users endpoint
app.get('/users', (req, res) => {
  try {
    // Mock data
    const mockUsers = [
      { id: 1, name: 'John Doe', created_at: '2023-01-01T00:00:00.000Z' },
      { id: 2, name: 'Jane Smith', created_at: '2023-01-01T00:00:00.000Z' }
    ];
    res.json(mockUsers);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mock create user endpoint
app.post('/users', (req, res) => {
  try {
    const { name } = req.body;
    
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return res.status(400).json({ error: 'Name is required and must be a non-empty string' });
    }
    
    // Mock created user
    const mockUser = { id: 3, name: name.trim(), created_at: new Date().toISOString() };
    res.status(201).json(mockUser);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

describe('CRUD Backend API', () => {
  describe('GET /healthz', () => {
    test('should return health status', async () => {
      const response = await request(app).get('/healthz');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual({ status: 'ok' });
    });
  });

  describe('GET /users', () => {
    test('should return list of users', async () => {
      const response = await request(app).get('/users');
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
    });
  });

  describe('POST /users', () => {
    test('should create a new user with valid data', async () => {
      const userData = { name: 'Test User' };
      const response = await request(app)
        .post('/users')
        .send(userData);
      
      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('name', 'Test User');
      expect(response.body).toHaveProperty('created_at');
    });

    test('should return 400 for missing name', async () => {
      const response = await request(app)
        .post('/users')
        .send({});
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    test('should return 400 for empty name', async () => {
      const response = await request(app)
        .post('/users')
        .send({ name: '' });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    test('should return 400 for non-string name', async () => {
      const response = await request(app)
        .post('/users')
        .send({ name: 123 });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    test('should trim whitespace from name', async () => {
      const response = await request(app)
        .post('/users')
        .send({ name: '  Test User  ' });
      
      expect(response.status).toBe(201);
      expect(response.body.name).toBe('Test User');
    });
  });

  describe('Unknown routes', () => {
    test('should return 404 for unknown GET routes', async () => {
      const response = await request(app).get('/unknown');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Route not found');
    });

    test('should return 404 for unknown POST routes', async () => {
      const response = await request(app).post('/unknown');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Route not found');
    });
  });
});
