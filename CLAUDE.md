# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NELO is an "Everything App" for proximity services in Africa, starting with a pilot in Tiassale, Côte d'Ivoire (~100,000 inhabitants). The project follows a **Monolith-First strategy** designed for progressive extraction to microservices.

**Current Status:** Documentation and planning phase (no production code yet)

## Architecture Strategy

### Monolith-First Phases
- **Phase 1 (MVP):** Single FastAPI monolith with modular architecture (1-5 devs, 1 DB, Docker Compose)
- **Phase 2:** Progressive extraction (5-15 devs, 2-3 DBs, RabbitMQ)
- **Phase 3:** Full microservices (15+ devs, N DBs, Kubernetes)

### Critical Architecture Rules (Phase 1)
1. **Module Isolation:** Each module (auth, users, orders, deliveries, payments, notifications) is autonomous
2. **No SQL JOINs between schemas** - compose data in Python service layer
3. **No FK constraints between schemas** - reference by UUID only
4. **Communication via interfaces** - use abstract contracts, not direct imports
5. **Store snapshots, not live references** - e.g., `delivery_address_snapshot JSONB`
6. **Internal EventBus** for async module communication

## Tech Stack

| Component | Technology |
|-----------|------------|
| Backend | FastAPI + SQLAlchemy 2.0 + Alembic |
| Database | PostgreSQL 15+ with PostGIS |
| Cache | Redis |
| Mobile Apps (3) | Flutter (Dart) - Clean Architecture + BLoC |
| Web Admin | Nuxt 4 + Vue 3 + Pinia + Tailwind |

## Project Structure

```
nelo/
├── databases/
│   ├── monolith/schema.sql      # Phase 1 complete schema
│   ├── microservices/           # Phase 2/3 schemas per service
│   └── shared/                  # Extensions, seeds, migrations
├── docs/
│   ├── 01_CAHIER_DES_CHARGES.md # Complete specifications
│   ├── 02_ARCHITECTURE.md       # Monolith-First strategy (READ THIS)
│   ├── 03_PLAN_MVP_PHASE1.md    # MVP timeline overview
│   └── plans/                   # Implementation plans by component
└── services/                    # (to be created)
    └── nelo-api/                # FastAPI monolith
```

### Planned Backend Structure
```
services/nelo-api/app/
├── modules/           # Isolated business modules
│   ├── auth/         # Authentication (OTP, JWT, sessions)
│   ├── users/        # Profiles, addresses, favorites
│   ├── orders/       # Order lifecycle, cart, ratings
│   ├── deliveries/   # Drivers, tracking, zones, matching
│   ├── payments/     # Wallet, transactions, providers
│   └── notifications/ # Push, SMS, templates
├── core/             # Shared infrastructure (config, db, security)
└── shared/
    ├── interfaces/   # Contracts between modules
    └── events/       # Internal event bus
```

## Database Schemas

PostgreSQL with logical schema separation (same DB, separate schemas):
- `auth` - users, sessions, otp_codes, kyc_documents, audit_logs
- `users` - profiles, addresses, favorites, referrals
- `orders` - orders, order_items, order_ratings
- `deliveries` - deliveries, drivers, vehicles, zones, geo_index
- `payments` - wallets, transactions, payment_methods
- `notifications` - notifications, templates, subscriptions

## Build and Run Commands

### Backend (when implemented)
```bash
# Development
docker compose -f docker-compose.dev.yml up

# Run tests
pytest
pytest --cov=app --cov-report=html
pytest tests/test_auth.py -v  # Single module

# Database migrations
alembic upgrade head
alembic revision --autogenerate -m "description"
```

### Mobile Apps (Flutter)
```bash
# Development
flutter pub get
flutter run

# Tests
flutter test
```

### Web Admin (Nuxt 4)
```bash
# Development
npm install
npm run dev

# Build
npm run build
```

## API Conventions

- Versioned endpoints: `/api/v1/`
- Auto-generated OpenAPI docs at `/docs`
- Authentication: OTP-based (phone numbers) + JWT tokens
- PIN protection for sensitive operations (wallet transactions)

## Key Implementation Patterns

### Module Communication Example
```python
# Use interfaces, not direct imports
class OrderService:
    def __init__(self, user_service: UserInterface):  # Interface injection
        self.user_service = user_service

    async def create_order(self, request):
        # Call through interface, never direct SQL join
        user = await self.user_service.get_user_by_id(request.user_id)
```

### Event Publishing
```python
await EventBus.publish(Event(
    name="order.created",
    data={"order_id": str(order.id), "user_id": str(order.user_id)}
))
```

## Development Guidelines

### Schema-First Development
**IMPORTANT:** Before implementing any form or screen that collects/displays user data:
1. **Always read `databases/monolith/schema.sql`** to understand the exact fields required
2. Match form fields to database columns (required vs optional, types, constraints)
3. Key tables to check:
   - `auth.users` - authentication fields (phone, email, role, kyc_level)
   - `users.profiles` - user info (first_name, last_name, referral_code, referred_by_id)
   - `orders.*` - order-related entities
   - `payments.wallets` - wallet/payment fields

## Context-Specific Considerations

- **African Market:** Consider offline capabilities, diverse payment methods (Mobile Money via Wave, cash on delivery)
- **Pilot City:** Initial deployment targets 5-10 restaurants, 10-20 delivery drivers
- **Language:** Documentation is in French, code in English
