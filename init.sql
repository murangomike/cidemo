-- Initialize the database schema for the CRUD application
-- This file will be automatically executed when the PostgreSQL container starts

-- Create the users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some sample data for testing
INSERT INTO users (name) VALUES 
    ('John Doe'),
    ('Jane Smith'),
    ('Bob Johnson')
ON CONFLICT DO NOTHING;

-- Create an index on the name column for better performance
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
