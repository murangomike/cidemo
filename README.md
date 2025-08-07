# CRUD Backend Application

A simple Node.js backend application with PostgreSQL database, containerized with Docker.

## Features

- RESTful API with Express.js
- PostgreSQL database integration
- Docker containerization
- Health check endpoints
- Automatic database initialization with sample data

## API Endpoints

- `GET /healthz` - Health check endpoint
- `GET /users` - Get all users
- `POST /users` - Create a new user (requires JSON body with `name` field)

## Quick Start

### Prerequisites

- Docker and Docker Compose installed

### Running the Application

1. **Start the application:**
   ```bash
   docker-compose up --build -d
   ```

2. **Check container status:**
   ```bash
   docker-compose ps
   ```

3. **Test the API:**
   ```bash
   # Health check
   curl http://localhost:3000/healthz
   
   # Get all users
   curl http://localhost:3000/users
   
   # Create a new user
   curl -X POST http://localhost:3000/users \
     -H "Content-Type: application/json" \
     -d '{"name":"Your Name"}'
   ```

4. **View logs:**
   ```bash
   docker-compose logs backend
   docker-compose logs db
   ```

5. **Stop the application:**
   ```bash
   docker-compose down
   ```

6. **Stop and remove volumes (clean slate):**
   ```bash
   docker-compose down -v
   ```

## Database Access

The PostgreSQL database is accessible on `localhost:5432` with the following credentials:

- **Database:** crudapp
- **Username:** postgres  
- **Password:** password123

You can connect using any PostgreSQL client like pgAdmin, DBeaver, or psql:

```bash
psql -h localhost -p 5432 -U postgres -d crudapp
```

## Project Structure

```
.
├── Dockerfile              # Node.js app container
├── docker-compose.yml      # Multi-container orchestration
├── init.sql                # Database initialization script
├── index.js                # Main application file
├── package.json            # Node.js dependencies
└── .dockerignore           # Docker build context exclusions
```

## Development

For local development without Docker:

1. Set up a local PostgreSQL database
2. Set the `DATABASE_URL` environment variable
3. Run `npm install` to install dependencies
4. Run `npm start` to start the server

## Database Schema

The application uses a simple `users` table:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string (automatically set in Docker)
- `NODE_ENV` - Environment mode (set to "production" in Docker)

## Health Checks

Both containers include health checks:
- **Backend:** HTTP check on `/healthz` endpoint
- **Database:** PostgreSQL readiness check

## Data Persistence

Database data is persisted in a Docker volume named `backend_postgres_data`. This ensures your data survives container restarts.
