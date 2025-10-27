# Vinylhound Infrastructure

Deployment and orchestration layer for the Vinylhound music discovery platform.

## Overview

The Infrastructure component provides:
- **API Gateway**: Reverse proxy and request routing for all backend services
- **Docker Orchestration**: Docker Compose configuration for local development
- **Shared Libraries**: Reusable Go packages for authentication, middleware, and models
- **Database Schema**: PostgreSQL schema with seed data

## Quick Start

### Prerequisites

- [Docker](https://www.docker.com/get-started) and Docker Compose
- [Go 1.23+](https://golang.org/dl/) (for local development)
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Vinylhound-Infrastructure
   ```

2. **Create environment configuration**
   ```bash
   cp .env.example .env
   ```

3. **Configure environment variables**

   Edit `.env` and update these **REQUIRED** values:
   ```bash
   # Generate a secure password
   POSTGRES_PASSWORD=your-secure-database-password
   DB_PASSWORD=your-secure-database-password

   # Generate a JWT secret with: openssl rand -base64 32
   JWT_SECRET=your-generated-jwt-secret-key
   ```

4. **Start all services**
   ```bash
   docker-compose up --build
   ```

5. **Verify services are running**
   ```bash
   # Check API Gateway health
   curl http://localhost:8080/health

   # Check individual services
   curl http://localhost:8001/health  # User Service
   curl http://localhost:8002/health  # Catalog Service
   curl http://localhost:8003/health  # Rating Service
   curl http://localhost:8004/health  # Playlist Service
   ```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Port 3000)                         │
│                   (vinylhound-frontend)                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP/REST
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              API GATEWAY (Port 8080)                            │
│  - Authentication validation                                    │
│  - CORS handling                                                │
│  - Request routing                                              │
│  - Error handling                                               │
└──────┬──────────────┬──────────────────┬──────────────────────┬─┘
       │              │                  │                      │
       ▼              ▼                  ▼                      ▼
  User Service   Catalog Service    Rating Service       Playlist Service
  (Port 8001)    (Port 8002)        (Port 8003)          (Port 8004)
       │              │                  │                      │
       └──────────────┴──────────────────┴──────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │  PostgreSQL Database        │
        │  (Port 54320)               │
        └─────────────────────────────┘
```

### Components

#### 1. API Gateway (`cmd/gateway`)

**Responsibilities:**
- Routes requests to appropriate backend services
- Validates authentication tokens (Bearer format)
- Applies CORS headers for frontend communication
- Handles upstream service failures gracefully

**Public Endpoints** (no authentication):
- `/health` - Health check
- `/api/v1/auth/signup` - User registration
- `/api/v1/auth/login` - User login
- `/api/v1/albums` (GET) - Browse album catalog
- `/api/v1/artists` (GET) - Browse artists
- `/api/v1/songs` (GET) - Browse songs

**Protected Endpoints** (authentication required):
- `/api/v1/users` - User management
- `/api/v1/me` - Current user profile
- `/api/v1/albums` (POST/PUT/DELETE) - Album management
- `/api/v1/ratings` - Rating management
- `/api/v1/reviews` - Review management
- `/api/v1/preferences` - User preferences
- `/api/v1/playlists` - Playlist management

#### 2. Backend Services

| Service | Port | Purpose | Database |
|---------|------|---------|----------|
| User Service | 8001 | Authentication, user management | PostgreSQL |
| Catalog Service | 8002 | Album, artist, song catalog | PostgreSQL |
| Rating Service | 8003 | Ratings, reviews, preferences | PostgreSQL |
| Playlist Service | 8004 | Playlist management | In-memory |

#### 3. Shared Libraries (`shared/go`)

**Packages:**
- `auth/` - Password hashing, token generation
- `middleware/` - CORS, authentication middleware
- `models/` - Shared data structures
- `database/` - Database connection utilities

## Configuration

### Environment Variables

All configuration is managed through environment variables. See [.env.example](.env.example) for the complete list.

**Required Variables:**
```bash
POSTGRES_PASSWORD   # Database password (MUST be changed in production)
DB_PASSWORD         # Same as POSTGRES_PASSWORD
JWT_SECRET          # Secret key for JWT signing (MUST be changed in production)
```

**Optional Variables:**
```bash
# Ports
GATEWAY_PORT=8080
USER_SERVICE_PORT=8001
CATALOG_SERVICE_PORT=8002
RATING_SERVICE_PORT=8003
PLAYLIST_SERVICE_PORT=8004
FRONTEND_PORT=3000
POSTGRES_EXTERNAL_PORT=54320

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173,http://localhost:8080

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Environment
ENV=development
```

### Production Configuration

Before deploying to production:

1. **Generate secure credentials:**
   ```bash
   # Generate strong password
   openssl rand -base64 32

   # Generate JWT secret
   openssl rand -base64 32
   ```

2. **Update environment variables:**
   ```bash
   POSTGRES_PASSWORD=<generated-password>
   DB_PASSWORD=<generated-password>
   JWT_SECRET=<generated-secret>
   DB_SSLMODE=require
   ENV=production
   LOG_LEVEL=warn
   ```

3. **Update CORS origins:**
   ```bash
   CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
   ```

4. **Use secrets management:**
   - For Kubernetes: Use K8s Secrets
   - For Docker Swarm: Use Docker Secrets
   - For cloud: Use AWS Secrets Manager, GCP Secret Manager, etc.

## Database

### Schema

The database schema is automatically initialized on first startup from [db/schema.sql](db/schema.sql).

**Tables:**
- `users` - User accounts
- `sessions` - Authentication sessions
- `user_content` - User content preferences
- `albums` - Album catalog
- `artists` - Artist information
- `songs` - Song catalog
- `user_album_preferences` - User ratings and favorites
- `ratings` - Album ratings
- `reviews` - Album reviews
- `playlists` - User playlists
- `playlist_items` - Playlist contents

### Seed Data

Sample data includes albums from:
- The Beatles
- Pink Floyd
- Miles Davis
- Nirvana
- Daft Punk

### Migrations

Currently using a single initialization script. For production, consider:
- [Flyway](https://flywaydb.org/)
- [golang-migrate](https://github.com/golang-migrate/migrate)
- [goose](https://github.com/pressly/goose)

## Development

### Running Services Locally (without Docker)

1. **Start PostgreSQL:**
   ```bash
   docker-compose up postgres
   ```

2. **Run services individually:**
   ```bash
   # Terminal 1: User Service
   cd ../Vinylhound-Backend
   DB_HOST=localhost DB_PORT=54320 DB_USER=vinylhound \
   DB_PASSWORD=localpassword DB_NAME=vinylhound \
   JWT_SECRET=dev-secret PORT=8001 \
   go run services/user-service/main.go

   # Terminal 2: Catalog Service
   PORT=8002 go run services/catalog-service/main.go

   # Terminal 3: API Gateway
   cd Vinylhound-Infrastructure
   USER_SERVICE_URL=http://localhost:8001 \
   CATALOG_SERVICE_URL=http://localhost:8002 \
   JWT_SECRET=dev-secret PORT=8080 \
   go run cmd/gateway/main.go
   ```

### Building the API Gateway

```bash
# Development build
go build -o gateway cmd/gateway/main.go

# Production build (optimized)
CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o gateway cmd/gateway/main.go
```

### Testing

```bash
# Test user registration
curl -X POST http://localhost:8080/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'

# Test login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'

# Test protected endpoint
TOKEN="<your-token-from-login>"
curl http://localhost:8080/api/v1/me/profile \
  -H "Authorization: Bearer $TOKEN"
```

## Docker Commands

```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Stop all services
docker-compose down

# Stop and remove volumes (DELETES DATA)
docker-compose down -v

# View logs
docker-compose logs

# View logs for specific service
docker-compose logs api-gateway
docker-compose logs user-service

# Follow logs in real-time
docker-compose logs -f

# Rebuild specific service
docker-compose up --build api-gateway

# Scale a service (if supported)
docker-compose up --scale user-service=3
```

## Troubleshooting

### Services won't start

**Error:** `JWT_SECRET environment variable is required`

**Solution:** Create a `.env` file from `.env.example` and set all required variables.

---

**Error:** `Database connection refused`

**Solution:** Ensure PostgreSQL is healthy:
```bash
docker-compose ps
docker-compose logs postgres
```

---

**Error:** `Port already in use`

**Solution:** Change ports in `.env`:
```bash
GATEWAY_PORT=8081
POSTGRES_EXTERNAL_PORT=54321
```

### Gateway returns 502 Bad Gateway

**Cause:** Backend service is not responding.

**Solution:**
1. Check service health:
   ```bash
   curl http://localhost:8001/health
   curl http://localhost:8002/health
   ```

2. View service logs:
   ```bash
   docker-compose logs user-service
   docker-compose logs catalog-service
   ```

3. Restart services:
   ```bash
   docker-compose restart user-service
   ```

### CORS errors in browser

**Cause:** Frontend origin not allowed.

**Solution:** Add your frontend URL to `CORS_ALLOWED_ORIGINS`:
```bash
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173,https://yourdomain.com
```

### Authentication always returns 401

**Cause:** Token format incorrect or missing.

**Solution:** Ensure Authorization header format:
```bash
Authorization: Bearer <your-token-here>
```

## Monitoring & Observability

### Current State

- Basic stdout logging
- Health check endpoints
- Docker health checks

### Planned Improvements

- Structured logging with zerolog
- Prometheus metrics
- Request tracing with correlation IDs
- Distributed tracing with Jaeger
- Centralized logging with ELK stack

## Security

### Current Measures

✅ Password hashing with bcrypt
✅ Session-based authentication
✅ CORS configuration
✅ Environment-driven secrets
✅ SQL parameterization (prevents injection)
✅ Bearer token validation at gateway

### Planned Improvements

- Rate limiting on auth endpoints
- Request throttling
- Password strength requirements
- Session expiry enforcement
- mTLS between services
- Security headers (CSP, HSTS, X-Frame-Options)
- Regular security audits
- Dependency vulnerability scanning

## Performance

### Current Optimizations

- Connection pooling for database
- Reverse proxy caching headers
- Graceful shutdown for zero-downtime deploys

### Planned Optimizations

- Redis caching layer
- CDN for static assets
- Database query optimization
- Horizontal scaling with load balancer
- Service mesh (Istio/Linkerd)

## Deployment

### Docker Compose (Development)

```bash
docker-compose up --build
```

### Docker Swarm (Production)

```bash
docker stack deploy -c docker-compose.yml vinylhound
```

### Kubernetes

See [docs/kubernetes.md](docs/kubernetes.md) (coming soon)

### Cloud Platforms

- **AWS**: ECS/EKS deployment guide (coming soon)
- **GCP**: GKE deployment guide (coming soon)
- **Azure**: AKS deployment guide (coming soon)

## Contributing

1. Follow the existing code style
2. Add tests for new features
3. Update documentation
4. Submit a pull request

## License

[Add license information]

## Support

- Issues: [GitHub Issues](https://github.com/yourusername/vinylhound/issues)
- Documentation: [docs/](docs/)
- Email: support@yourdomain.com

---

**Last Updated:** 2025-10-24
**Maintained By:** Development Team
