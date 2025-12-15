# NELO

**Everything App pour les Services de Proximite en Afrique**

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/01_CAHIER_DES_CHARGES.md](docs/01_CAHIER_DES_CHARGES.md) | Specifications completes |
| [docs/02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md) | Strategie Monolith-First |
| [docs/03_PLAN_MVP_PHASE1.md](docs/03_PLAN_MVP_PHASE1.md) | Vue d'ensemble MVP |

### Plans par Application (Developpement Parallele)

| Plan | Description |
|------|-------------|
| [docs/plans/01_BACKEND.md](docs/plans/01_BACKEND.md) | Backend FastAPI (M1-M5) |
| [docs/plans/02_APP_CLIENT.md](docs/plans/02_APP_CLIENT.md) | App Flutter Client |
| [docs/plans/03_APP_PROVIDER.md](docs/plans/03_APP_PROVIDER.md) | App Flutter Provider |
| [docs/plans/04_APP_DRIVER.md](docs/plans/04_APP_DRIVER.md) | App Flutter Driver |
| [docs/plans/05_WEB_ADMIN.md](docs/plans/05_WEB_ADMIN.md) | Dashboard Nuxt 4 |
| [docs/plans/06_LANCEMENT.md](docs/plans/06_LANCEMENT.md) | Deploiement (M7) |

**Commencer ici** : [docs/README.md](docs/README.md)

---

## Stack Technologique (Phase 1 - MVP)

| Composant | Technologie |
|-----------|-------------|
| App Client | Flutter (Dart) |
| App Prestataire | Flutter (Dart) |
| App Livreur | Flutter (Dart) |
| Dashboard Admin | Nuxt 4 (Vue 3) |
| Backend | FastAPI (Python) |
| Base de donnees | PostgreSQL + PostGIS |
| Cache | Redis |

---

## Strategie : Monolith-First

> **Approche progressive** : On commence par un monolithe modulaire bien structure, puis on extrait les services quand le besoin se fait sentir.

| Phase | Description | Equipe | Infrastructure |
|-------|-------------|--------|----------------|
| **Phase 1** | Monolithe modulaire (MVP) | 1-5 devs | 1 DB, Docker Compose |
| Phase 2 | Extraction progressive | 5-15 devs | 2-3 DBs, RabbitMQ |
| Phase 3 | Microservices complets | 15+ devs | N DBs, Kubernetes |

**Documentation complete** : [docs/02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md)

---

## Applications

| Composant | Technologie | Description |
|-----------|-------------|-------------|
| mobile-client | Flutter | Application consommateurs B2C |
| mobile-provider | Flutter | Application prestataires B2B |
| mobile-driver | Flutter | Application livreurs B2B |
| web-admin | Nuxt 4 | Dashboard administration |

---

## Quick Start

1. Lire [docs/README.md](docs/README.md)
2. Suivre [docs/plans/01_BACKEND.md](docs/plans/01_BACKEND.md) pour M1
3. Executer `databases/monolith/schema.sql`

---

## Ville Pilote

**Tiassale, Cote d'Ivoire** - Population ~100,000 habitants
# nelo
