# NELO API

Backend API for the NELO "Everything App" - proximity services platform for Africa.

## Tech Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL 15+ with PostGIS
- **Cache**: Redis
- **ORM**: SQLAlchemy 2.0
- **Migrations**: Alembic

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development without Docker)

### Development Setup

1. **Start the development environment:**

```bash
# From the project root
docker compose -f docker-compose.dev.yml up --build
```

2. **Access the services:**

- API: http://localhost:8000
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- pgAdmin: http://localhost:5050 (admin@nelo.app / admin)
- RedisInsight: http://localhost:5540

3. **Verify the setup:**

```bash
# Health check
curl http://localhost:8000/health

# Readiness check (DB + Redis)
curl http://localhost:8000/health/ready
```

### Database

The database schema is automatically applied on first startup via `docker-entrypoint-initdb.d`.

**Schemas:**
- `auth` - Authentication, sessions, KYC
- `users` - Profiles, addresses, favorites
- `orders` - Orders, products, providers
- `deliveries` - Drivers, tracking, zones
- `payments` - Wallets, transactions
- `notifications` - Push, SMS, templates

### Running Tests

```bash
# Inside the container
docker compose exec nelo-api pytest

# With coverage
docker compose exec nelo-api pytest --cov=app --cov-report=html

# Specific test file
docker compose exec nelo-api pytest tests/test_health.py -v
```

### Alembic Migrations

```bash
# Stamp baseline (first time only, after DB init)
docker compose exec nelo-api alembic stamp 0001_baseline

# Create a new migration
docker compose exec nelo-api alembic revision --autogenerate -m "description"

# Apply migrations
docker compose exec nelo-api alembic upgrade head
```

## Project Structure

```
services/nelo-api/
├── app/
│   ├── main.py                 # FastAPI entrypoint
│   ├── core/                   # Shared infrastructure
│   │   ├── config.py           # Pydantic settings
│   │   ├── database.py         # SQLAlchemy async engine
│   │   ├── redis.py            # Redis async client
│   │   ├── security.py         # JWT, password hashing
│   │   ├── dependencies.py     # FastAPI dependencies
│   │   └── exceptions.py       # Custom exceptions
│   ├── modules/                # Business modules
│   │   ├── auth/
│   │   ├── users/
│   │   ├── orders/
│   │   ├── deliveries/
│   │   ├── payments/
│   │   └── notifications/
│   └── shared/
│       ├── interfaces/         # Module contracts
│       └── events/             # Internal event bus
├── tests/
├── alembic/
├── pyproject.toml
├── Dockerfile
└── Dockerfile.dev
```

## Environment Variables

See `.env.example` for all available configuration options.

Key variables:
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `SECRET_KEY` - JWT signing key
- `ENVIRONMENT` - development/staging/production
- `DEBUG` - Enable debug mode

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- OpenAPI JSON: http://localhost:8000/api/v1/openapi.json

## Module Implementation Status

| Module | Status | Milestone |
|--------|--------|-----------|
| Auth | Skeleton | M2 |
| Users | Skeleton | M2 |
| Orders | Skeleton | M4 |
| Deliveries | Skeleton | M4 |
| Payments | Skeleton | M5 |
| Notifications | Skeleton | - |
