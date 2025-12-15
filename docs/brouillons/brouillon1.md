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

## Stack Technologique

| Composant | Technologie | Justification |
|-----------|-------------|---------------|
| App Client | Flutter (Dart) | Performance native, UX optimisée |
| App Prestataire | Flutter (Dart) | Gestion commandes, temps réel |
| App Livreur | Flutter (Dart) | GPS natif, navigation |
| Dashboard Admin | Nuxt 4 (Vue 3) | SSR, Nitro server, excellent DX |
| Backend Auth/Users/AI | FastAPI (Python) | Écosystème ML, développement rapide |
| Backend Realtime | Fastify (Node.js) | WebSocket, notifications, paiements |
| Backend Core | Actix Web (Rust) | Performance critique, géolocalisation |

---

## Arborescence Complète

```
nelo/
├── apps/                              # Applications frontend
│   │
│   ├── mobile-client/                 # App Flutter Client
│   │   ├── lib/
│   │   │   ├── core/
│   │   │   │   ├── config/
│   │   │   │   │   ├── app_config.dart
│   │   │   │   │   ├── api_config.dart
│   │   │   │   │   └── env.dart
│   │   │   │   ├── theme/
│   │   │   │   │   ├── app_theme.dart
│   │   │   │   │   ├── colors.dart
│   │   │   │   │   └── typography.dart
│   │   │   │   ├── constants/
│   │   │   │   ├── router/
│   │   │   │   └── di/
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── remote/
│   │   │   │   │   └── local/
│   │   │   │   ├── repositories/
│   │   │   │   └── models/
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   │
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── home/
│   │   │   │   │   ├── search/
│   │   │   │   │   ├── restaurant/
│   │   │   │   │   ├── cart/
│   │   │   │   │   ├── checkout/
│   │   │   │   │   ├── orders/
│   │   │   │   │   ├── tracking/
│   │   │   │   │   ├── chat/
│   │   │   │   │   ├── profile/
│   │   │   │   │   └── auth/
│   │   │   │   ├── widgets/
│   │   │   │   └── blocs/
│   │   │   │
│   │   │   ├── l10n/
│   │   │   └── main.dart
│   │   │
│   │   ├── assets/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── mobile-provider/               # App Flutter Prestataire
│   │   ├── lib/
│   │   │   ├── core/
│   │   │   │   ├── config/
│   │   │   │   ├── theme/
│   │   │   │   ├── constants/
│   │   │   │   ├── router/
│   │   │   │   └── di/
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── repositories/
│   │   │   │   └── models/
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   │
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── dashboard/
│   │   │   │   │   ├── orders/
│   │   │   │   │   ├── menu/
│   │   │   │   │   ├── products/
│   │   │   │   │   ├── stock/
│   │   │   │   │   ├── stats/
│   │   │   │   │   ├── finances/
│   │   │   │   │   ├── settings/
│   │   │   │   │   └── auth/
│   │   │   │   ├── widgets/
│   │   │   │   └── blocs/
│   │   │   │
│   │   │   ├── l10n/
│   │   │   └── main.dart
│   │   │
│   │   ├── assets/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── mobile-driver/                 # App Flutter Livreur
│   │   ├── lib/
│   │   │   ├── core/
│   │   │   │   ├── config/
│   │   │   │   ├── theme/
│   │   │   │   ├── constants/
│   │   │   │   ├── router/
│   │   │   │   └── di/
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── repositories/
│   │   │   │   └── models/
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   │
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── home/
│   │   │   │   │   ├── deliveries/
│   │   │   │   │   ├── navigation/
│   │   │   │   │   ├── grocery_list/
│   │   │   │   │   ├── earnings/
│   │   │   │   │   ├── stats/
│   │   │   │   │   ├── profile/
│   │   │   │   │   ├── documents/
│   │   │   │   │   └── auth/
│   │   │   │   ├── widgets/
│   │   │   │   └── blocs/
│   │   │   │
│   │   │   ├── l10n/
│   │   │   └── main.dart
│   │   │
│   │   ├── assets/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── web-admin/                     # Dashboard Nuxt 4 Admin
│       ├── app/
│       │   ├── assets/
│       │   │   ├── css/
│       │   │   └── images/
│       │   │
│       │   ├── components/
│       │   │   ├── ui/
│       │   │   │   ├── Button.vue
│       │   │   │   ├── Card.vue
│       │   │   │   ├── Modal.vue
│       │   │   │   ├── DataTable.vue
│       │   │   │   └── Input.vue
│       │   │   ├── dashboard/
│       │   │   │   ├── StatCard.vue
│       │   │   │   ├── Chart.vue
│       │   │   │   └── ActivityFeed.vue
│       │   │   ├── orders/
│       │   │   ├── users/
│       │   │   └── providers/
│       │   │
│       │   ├── composables/
│       │   │   ├── useAuth.ts
│       │   │   ├── useApi.ts
│       │   │   ├── useWebSocket.ts
│       │   │   └── useNotifications.ts
│       │   │
│       │   ├── layouts/
│       │   │   ├── default.vue
│       │   │   ├── auth.vue
│       │   │   └── error.vue
│       │   │
│       │   ├── middleware/
│       │   │   ├── auth.ts
│       │   │   └── role.ts
│       │   │
│       │   ├── pages/
│       │   │   ├── index.vue
│       │   │   ├── login.vue
│       │   │   ├── users/
│       │   │   │   ├── index.vue
│       │   │   │   ├── [id].vue
│       │   │   │   └── clients.vue
│       │   │   ├── providers/
│       │   │   ├── drivers/
│       │   │   ├── orders/
│       │   │   ├── deliveries/
│       │   │   ├── finance/
│       │   │   ├── marketing/
│       │   │   ├── support/
│       │   │   └── settings/
│       │   │
│       │   ├── plugins/
│       │   │   ├── api.ts
│       │   │   └── toast.ts
│       │   │
│       │   └── utils/
│       │       ├── formatters.ts
│       │       └── validators.ts
│       │
│       ├── server/
│       │   ├── api/
│       │   ├── middleware/
│       │   └── utils/
│       │
│       ├── stores/                    # Pinia stores
│       │   ├── auth.ts
│       │   ├── users.ts
│       │   ├── orders.ts
│       │   └── notifications.ts
│       │
│       ├── types/
│       │   ├── user.ts
│       │   ├── order.ts
│       │   └── api.ts
│       │
│       ├── public/
│       ├── nuxt.config.ts
│       ├── tailwind.config.ts
│       ├── package.json
│       └── tsconfig.json
│
├── services/                          # Backend microservices
│   │
│   ├── message-broker/                # Communication asynchrone inter-services
│   │   └── rabbitmq/                  # RabbitMQ (ou Kafka selon le volume)
│   │       # Échange d'événements : OrderCreated, PaymentCompleted, DeliveryAssigned...
│   │       # Découple les services, garantit la livraison des messages
│   │
│   ├── service-registry/              # Service Discovery & Configuration
│   │   ├── consul/                    # Découverte dynamique des services
│   │   └── vault/                     # Gestion centralisée des secrets (API keys, DB passwords)
│   │       # Chaque service s'enregistre au démarrage
│   │       # Rotation automatique des credentials
│   │
│   ├── gateway/                       # API Gateway
│   │   ├── nginx.conf
│   │   ├── kong.yml
│   │   └── docker-compose.yml
│   │
│   ├── auth-service/                  # FastAPI - Authentification
│   │   ├── app/
│   │   │   ├── api/
│   │   │   │   └── v1/
│   │   │   │       ├── auth.py
│   │   │   │       ├── users.py
│   │   │   │       └── kyc.py
│   │   │   ├── core/
│   │   │   │   ├── config.py
│   │   │   │   ├── security.py
│   │   │   │   └── dependencies.py
│   │   │   ├── models/
│   │   │   ├── schemas/
│   │   │   ├── services/
│   │   │   └── main.py
│   │   ├── tests/
│   │   ├── alembic/
│   │   ├── requirements.txt
│   │   ├── Dockerfile
│   │   └── pyproject.toml
│   │
│   ├── user-service/                  # FastAPI - Gestion Utilisateurs
│   │   └── [structure FastAPI similaire]
│   │
│   ├── admin-service/                 # FastAPI - Administration
│   │   └── [structure FastAPI similaire]
│   │
│   ├── ai-service/                    # FastAPI - IA & Chatbot
│   │   ├── app/
│   │   │   ├── api/
│   │   │   ├── ml/
│   │   │   │   ├── chatbot/
│   │   │   │   ├── recommendations/
│   │   │   │   └── fraud_detection/
│   │   │   └── main.py
│   │   └── [structure FastAPI similaire]
│   │
│   ├── notification-service/          # Fastify - Notifications
│   │   ├── src/
│   │   │   ├── plugins/
│   │   │   ├── routes/
│   │   │   ├── services/
│   │   │   │   ├── push.service.ts
│   │   │   │   ├── sms.service.ts
│   │   │   │   └── email.service.ts
│   │   │   ├── websocket/
│   │   │   └── app.ts
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── chat-service/                  # Fastify - Messagerie temps réel
│   │   └── [structure Fastify similaire]
│   │
│   ├── payment-service/               # Fastify - Paiements
│   │   ├── src/
│   │   │   ├── providers/
│   │   │   │   ├── cinetpay.provider.ts
│   │   │   │   ├── wave.provider.ts
│   │   │   │   └── wallet.provider.ts
│   │   │   ├── routes/
│   │   │   └── services/
│   │   └── [structure Fastify similaire]
│   │
│   ├── order-service/                 # Actix Web - Commandes
│   │   ├── src/
│   │   │   ├── api/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── orders.rs
│   │   │   │   └── restaurants.rs
│   │   │   ├── domain/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── order.rs
│   │   │   │   └── restaurant.rs
│   │   │   ├── infrastructure/
│   │   │   │   ├── db/
│   │   │   │   └── cache/
│   │   │   ├── services/
│   │   │   └── main.rs
│   │   ├── tests/
│   │   ├── Cargo.toml
│   │   └── Dockerfile
│   │
│   ├── delivery-service/              # Actix Web - Livraisons & Matching
│   │   ├── src/
│   │   │   ├── api/
│   │   │   ├── domain/
│   │   │   ├── matching/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── scorer.rs
│   │   │   │   └── optimizer.rs
│   │   │   ├── geo/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── distance.rs
│   │   │   │   └── routing.rs
│   │   │   └── main.rs
│   │   └── [structure Actix similaire]
│   │
│   ├── pricing-service/               # Actix Web - Tarification
│   │   └── [structure Actix similaire]
│   │
│   └── saga-orchestrator/             # Orchestration des transactions distribuées
│       # Gère les workflows complexes : Commande → Paiement → Préparation → Livraison
│       # Compensation automatique en cas d'échec (rollback distribué)
│       # Pattern Saga pour maintenir la cohérence sans transactions ACID
│
├── contracts/                         # Contrats d'API & Événements
│   ├── events/                        # Définition des événements métier
│   │   # order.events.json, payment.events.json, delivery.events.json
│   │   # Schema validation (JSON Schema ou Avro)
│   │
│   ├── api/                           # Contrats OpenAPI par service
│   │   # Versioning des API inter-services
│   │   # Consumer-Driven Contract Testing (Pact)
│   │
│   └── proto/                         # Définitions gRPC (optionnel)
│       # Communication haute performance entre services Rust
│
├── infrastructure/                    # Configuration infrastructure
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   ├── docker-compose.prod.yml
│   │   └── docker-compose.test.yml
│   │
│   ├── kubernetes/
│   │   ├── base/
│   │   │   ├── namespace.yaml
│   │   │   ├── configmaps/
│   │   │   ├── secrets/
│   │   │   └── services/
│   │   └── overlays/
│   │       ├── staging/
│   │       └── production/
│   │
│   ├── terraform/
│   │   ├── modules/
│   │   │   ├── vpc/
│   │   │   ├── eks/
│   │   │   ├── rds/
│   │   │   └── redis/
│   │   ├── environments/
│   │   │   ├── staging/
│   │   │   └── production/
│   │   └── main.tf
│   │
│   ├── resilience/                    # Patterns de résilience
│   │   ├── circuit-breaker/           # Configuration Hystrix/Resilience4j
│   │   │   # Coupe-circuit automatique si un service est down
│   │   │   # Fallback gracieux, évite les cascades d'erreurs
│   │   │
│   │   ├── rate-limiting/             # Limitation de débit par service
│   │   │   # Protection contre les abus, équité entre clients
│   │   │
│   │   └── retry-policies/            # Politiques de retry
│   │       # Exponential backoff, jitter
│   │       # Idempotence des requêtes
│   │
│   └── scripts/
│       ├── setup-dev.sh
│       ├── migrate-db.sh
│       └── seed-data.sh
│
├── observability/                     # Stack d'observabilité complète
│   │
│   ├── monitoring/                    # Métriques et alerting
│   │   ├── prometheus/                # Collecte des métriques (CPU, latence, requêtes/sec)
│   │   ├── grafana/                   # Dashboards et visualisation
│   │   └── alertmanager/              # Gestion des alertes (Slack, PagerDuty)
│   │       # Chaque service expose /metrics (format Prometheus)
│   │
│   ├── tracing/                       # Tracing distribué
│   │   └── jaeger/                    # Suivi des requêtes à travers les services
│   │       # Trace ID propagé : Client → Gateway → Order → Payment → Notification
│   │       # Identification des goulots d'étranglement
│   │
│   ├── logging/                       # Logs centralisés
│   │   ├── elasticsearch/             # Stockage et indexation
│   │   ├── logstash/                  # Ingestion et transformation
│   │   └── kibana/                    # Recherche et visualisation
│   │       # Format structuré JSON avec correlation_id
│   │
│   └── healthcheck/                   # Endpoints de santé
│       # Définition des /health et /ready pour chaque service
│       # Intégration Kubernetes liveness/readiness probes
│
├── databases/                         # Schémas et migrations par service
│   ├── auth/
│   │   ├── migrations/
│   │   ├── seeds/
│   │   └── schema.sql
│   ├── users/
│   │   ├── migrations/
│   │   ├── seeds/
│   │   └── schema.sql
│   ├── orders/
│   │   ├── migrations/
│   │   ├── seeds/
│   │   └── schema.sql
│   ├── deliveries/
│   │   ├── migrations/
│   │   ├── seeds/
│   │   └── schema.sql
│   ├── payments/
│   │   ├── migrations/
│   │   ├── seeds/
│   │   └── schema.sql
│   ├── notifications/
│   │   ├── migrations/
│   │   ├── seeds/
│   │   └── schema.sql
│   └── shared/                        # Scripts communs
│       ├── extensions.sql             # Extensions PostgreSQL (PostGIS, uuid-ossp)
│       └── init.sql
│
├── docs/                              # Documentation
│   ├── api/
│   │   └── openapi.yaml
│   │
│   ├── architecture/
│   │   ├── decisions/                 # ADR (Architecture Decision Records)
│   │   ├── diagrams/
│   │   └── service-mesh/              # Documentation des interactions inter-services
│   │
│   ├── events/                        # Catalogue des événements
│   │   # Liste exhaustive des événements publiés/consommés par chaque service
│   │   # Schémas, exemples, versioning des événements
│   │
│   ├── workflows/                     # Documentation des Sagas
│   │   # order-workflow.md : Création → Validation → Paiement → Préparation → Livraison
│   │   # Diagrammes de séquence, cas d'erreur, compensations
│   │
│   ├── runbooks/                      # Procédures opérationnelles
│   │   # Incidents courants, scaling, disaster recovery
│   │   # Playbooks pour l'équipe Ops
│   │
│   └── guides/
│       ├── setup.md
│       ├── deployment.md
│       └── contributing.md
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── cd-staging.yml
│       └── cd-production.yml
│
├── .env.example
├── README.md
├── CHANGELOG.md
└── Makefile
```

---

## Stratégie : Monolith-First

> **Approche progressive** : On commence par un monolithe modulaire bien structuré, puis on extrait les services quand le besoin se fait sentir.

**Documentation complète** : [docs/02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md)

| Phase | Description | Équipe | Infrastructure |
|-------|-------------|--------|----------------|
| **Phase 1** | Monolithe modulaire (MVP) | 1-5 devs | 1 DB, Docker Compose |
| **Phase 2** | Extraction progressive | 5-15 devs | 2-3 DBs, RabbitMQ |
| **Phase 3** | Microservices complets | 15+ devs | N DBs, Kubernetes |

L'arborescence ci-dessus représente la **cible finale** (Phase 3). Les dossiers `observability/`, `contracts/`, `message-broker/` ne sont nécessaires qu'en Phase 2-3.

---

## Notes Importantes

### 3 Applications Flutter Séparées

Chaque application (`mobile-client`, `mobile-provider`, `mobile-driver`) a sa propre codebase, permettant des cycles de release indépendants et une maintenance ciblée.

### Nuxt 4 pour l'Admin

Structure `app/` de Nuxt 4 avec Vue 3 Composition API, Pinia pour le state management, Nitro server pour les API routes, et Tailwind CSS pour le styling.

### Communication Frontend-Backend

Les types peuvent être générés automatiquement depuis l'OpenAPI spec (`docs/api/openapi.yaml`) vers Dart et TypeScript.

---

## Résumé de l'Architecture

### Applications

| Composant | Technologie | Description |
|-----------|-------------|-------------|
| mobile-client | Flutter | Application consommateurs B2C |
| mobile-provider | Flutter | Application prestataires B2B |
| mobile-driver | Flutter | Application livreurs B2B |
| web-admin | Nuxt 4 | Dashboard administration |

### Backend (évolution progressive)

| Phase | Composant | Description |
|-------|-----------|-------------|
| 1 | nelo-api (FastAPI) | Monolithe modulaire - MVP |
| 2 | + message-broker | RabbitMQ pour événements async |
| 2 | + service-registry | Consul + Vault |
| 3 | services séparés | FastAPI / Fastify / Actix |

### Infrastructure Microservices (Phase 2-3)

| Dossier | Rôle |
|---------|------|
| `message-broker/` | Communication asynchrone (RabbitMQ/Kafka) |
| `service-registry/` | Découverte de services + secrets (Consul/Vault) |
| `contracts/` | Événements, OpenAPI inter-services, gRPC |
| `observability/` | Monitoring, tracing, logs (Prometheus/Jaeger/ELK) |
| `infrastructure/resilience/` | Circuit breaker, rate limiting, retry |
| `saga-orchestrator/` | Transactions distribuées |
| `docs/workflows/` | Documentation des Sagas |
| `docs/runbooks/` | Procédures opérationnelles |# nelo
