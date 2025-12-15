# Stratégie Monolith-First

> **Approche progressive** : On commence par un monolithe modulaire bien structuré, puis on extrait les services quand le besoin se fait sentir.

---

## Pourquoi Monolith-First ?

### Le piège des microservices prématurés

| Problème | Impact |
|----------|--------|
| Complexité distribuée dès le jour 1 | Debugging difficile, latence réseau |
| Contrats d'API rigides | Refactoring coûteux |
| Infrastructure lourde | DevOps overhead, coûts serveurs |
| Équipe fragmentée | Communication inter-équipes |

### Avantages du monolithe modulaire

| Avantage | Description |
|----------|-------------|
| Déploiement simple | Un seul artefact à déployer |
| Debugging facile | Stack trace complète, pas de traces distribuées |
| Refactoring rapide | Pas de contrats d'API entre modules |
| Transactions ACID | Cohérence garantie par la DB |
| Vélocité maximale | Idéal pour équipe réduite (1-5 devs) |

---

## Les 3 Phases

```
Phase 1 (MVP)          Phase 2 (Scale)         Phase 3 (Enterprise)
┌─────────────┐        ┌─────────────┐         ┌─────────────┐
│  Monolithe  │   →    │  Monolithe  │    →    │ Microservices│
│  Modulaire  │        │ + Services  │         │   Complets   │
│             │        │  extraits   │         │              │
└─────────────┘        └─────────────┘         └─────────────┘
    1 DB                  2-3 DBs                 N DBs
    1 Deploy              2-3 Deploys             N Deploys
    1-5 devs              5-15 devs               15+ devs
```

---

## Phase 1 : Monolithe Modulaire (MVP → Product-Market Fit)

### Architecture

```
services/
└── nelo-api/                          # Monolithe FastAPI
    ├── app/
    │   ├── modules/                   # Modules métier isolés
    │   │   ├── auth/
    │   │   │   ├── api/
    │   │   │   │   └── v1/
    │   │   │   │       ├── routes.py
    │   │   │   │       └── schemas.py
    │   │   │   ├── services/
    │   │   │   │   └── auth_service.py
    │   │   │   ├── repositories/
    │   │   │   │   └── user_repository.py
    │   │   │   └── models.py
    │   │   │
    │   │   ├── users/
    │   │   │   ├── api/
    │   │   │   ├── services/
    │   │   │   ├── repositories/
    │   │   │   └── models.py
    │   │   │
    │   │   ├── orders/
    │   │   │   ├── api/
    │   │   │   ├── services/
    │   │   │   ├── repositories/
    │   │   │   └── models.py
    │   │   │
    │   │   ├── deliveries/
    │   │   │   ├── api/
    │   │   │   ├── services/
    │   │   │   ├── repositories/
    │   │   │   └── models.py
    │   │   │
    │   │   ├── payments/
    │   │   │   ├── api/
    │   │   │   ├── services/
    │   │   │   ├── repositories/
    │   │   │   └── models.py
    │   │   │
    │   │   ├── notifications/
    │   │   │   ├── api/
    │   │   │   ├── services/
    │   │   │   ├── repositories/
    │   │   │   └── models.py
    │   │   │
    │   │   └── ai/
    │   │       ├── api/
    │   │       ├── services/
    │   │       └── models.py
    │   │
    │   ├── core/                      # Infrastructure partagée
    │   │   ├── config.py
    │   │   ├── database.py
    │   │   ├── security.py
    │   │   ├── dependencies.py
    │   │   └── exceptions.py
    │   │
    │   ├── shared/                    # Code partagé entre modules
    │   │   ├── interfaces/            # Contrats entre modules
    │   │   │   ├── user_interface.py
    │   │   │   ├── order_interface.py
    │   │   │   └── payment_interface.py
    │   │   ├── events/                # Bus d'événements interne
    │   │   │   ├── event_bus.py
    │   │   │   └── handlers.py
    │   │   └── utils/
    │   │
    │   └── main.py
    │
    ├── tests/
    ├── alembic/
    ├── requirements.txt
    ├── Dockerfile
    └── pyproject.toml
```

### Règles d'or Phase 1

#### 1. Isolation des modules

Chaque module est autonome avec sa propre structure :

```python
# modules/orders/api/v1/routes.py
from fastapi import APIRouter, Depends
from app.modules.orders.services import OrderService
from app.modules.orders.api.v1.schemas import CreateOrderRequest

router = APIRouter(prefix="/orders", tags=["orders"])

@router.post("/")
async def create_order(
    request: CreateOrderRequest,
    service: OrderService = Depends()
):
    return await service.create_order(request)
```

#### 2. Communication via interfaces (pas d'imports directs)

```python
# shared/interfaces/user_interface.py
from abc import ABC, abstractmethod
from uuid import UUID

class UserInterface(ABC):
    @abstractmethod
    async def get_user_by_id(self, user_id: UUID) -> dict | None:
        pass

    @abstractmethod
    async def get_user_address(self, user_id: UUID, address_id: UUID) -> dict | None:
        pass
```

```python
# modules/users/services/user_service.py
from app.shared.interfaces.user_interface import UserInterface

class UserService(UserInterface):
    async def get_user_by_id(self, user_id: UUID) -> dict | None:
        # Implémentation
        pass
```

```python
# modules/orders/services/order_service.py
from app.shared.interfaces.user_interface import UserInterface

class OrderService:
    def __init__(self, user_service: UserInterface):
        self.user_service = user_service

    async def create_order(self, request: CreateOrderRequest):
        # Utilise l'interface, pas l'implémentation directe
        user = await self.user_service.get_user_by_id(request.user_id)
        address = await self.user_service.get_user_address(
            request.user_id,
            request.address_id
        )
        # ...
```

#### 3. Pas de JOINs SQL entre schémas

```python
# CORRECT - Composition dans le service
class OrderService:
    async def get_order_with_details(self, order_id: UUID):
        order = await self.order_repo.get_by_id(order_id)
        user = await self.user_service.get_user_by_id(order.user_id)
        driver = await self.delivery_service.get_driver_by_id(order.driver_id)

        return {
            **order.dict(),
            "user": user,
            "driver": driver
        }

# INCORRECT - JOIN SQL direct
# SELECT * FROM orders.orders o
# JOIN users.profiles u ON o.user_id = u.id
# JOIN deliveries.drivers d ON o.driver_id = d.user_id
```

#### 4. Bus d'événements interne

```python
# shared/events/event_bus.py
from typing import Callable, Dict, List
from dataclasses import dataclass

@dataclass
class Event:
    name: str
    data: dict

class EventBus:
    _handlers: Dict[str, List[Callable]] = {}

    @classmethod
    def subscribe(cls, event_name: str, handler: Callable):
        if event_name not in cls._handlers:
            cls._handlers[event_name] = []
        cls._handlers[event_name].append(handler)

    @classmethod
    async def publish(cls, event: Event):
        handlers = cls._handlers.get(event.name, [])
        for handler in handlers:
            await handler(event.data)
```

```python
# modules/orders/services/order_service.py
from app.shared.events.event_bus import EventBus, Event

class OrderService:
    async def create_order(self, request):
        order = await self.order_repo.create(request)

        # Publie un événement (découplage)
        await EventBus.publish(Event(
            name="order.created",
            data={"order_id": str(order.id), "user_id": str(order.user_id)}
        ))

        return order
```

```python
# modules/notifications/services/notification_service.py
from app.shared.events.event_bus import EventBus

class NotificationService:
    def __init__(self):
        EventBus.subscribe("order.created", self.on_order_created)
        EventBus.subscribe("order.delivered", self.on_order_delivered)

    async def on_order_created(self, data: dict):
        await self.send_push(
            user_id=data["user_id"],
            title="Commande confirmée",
            body=f"Votre commande a été reçue"
        )
```

### Base de données Phase 1

Une seule base PostgreSQL avec des schémas logiques :

```sql
-- Schémas isolés dans une seule DB
CREATE SCHEMA auth;
CREATE SCHEMA users;
CREATE SCHEMA orders;
CREATE SCHEMA deliveries;
CREATE SCHEMA payments;
CREATE SCHEMA notifications;

-- Références par UUID, PAS de FK inter-schémas
CREATE TABLE orders.orders (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,        -- Réf auth.users (pas de FK)
    driver_id UUID,               -- Réf deliveries.drivers (pas de FK)
    transaction_id UUID,          -- Réf payments.transactions (pas de FK)
    delivery_address_snapshot JSONB NOT NULL,  -- Copie des données
    -- ...
);
```

### Infrastructure Phase 1

```yaml
# docker-compose.yml
services:
  nelo-api:
    build: ./services/nelo-api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://...
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgis/postgis:15-3.3
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Phase 2 : Extraction Progressive (Scaling)

### Quand extraire un service ?

| Signal | Exemple | Action |
|--------|---------|--------|
| Charge différente | Orders reçoit 10x plus de requêtes | Extraire order-service |
| Équipe dédiée | 3 devs sur les paiements | Extraire payment-service |
| Techno différente | Besoin de Rust pour le matching | Extraire delivery-service |
| Scaling GPU | IA consomme trop de ressources | Extraire ai-service |
| Cycle de release | Notifications change 5x/jour | Extraire notification-service |

### Architecture Phase 2

```
services/
├── nelo-api/                    # Monolithe (modules restants)
│   └── modules/
│       ├── auth/
│       ├── users/
│       └── orders/
│
├── delivery-service/            # Extrait (Rust/Actix)
│   └── src/
│       ├── matching/
│       └── geo/
│
├── payment-service/             # Extrait (Node/Fastify)
│   └── src/
│       └── providers/
│
└── notification-service/        # Extrait (Node/Fastify)
    └── src/
        └── websocket/
```

### Communication Phase 2

Le bus d'événements interne devient externe (RabbitMQ) :

```python
# Avant (Phase 1) - EventBus interne
await EventBus.publish(Event(name="order.created", data={...}))

# Après (Phase 2) - RabbitMQ
await rabbitmq.publish(
    exchange="orders",
    routing_key="order.created",
    body=json.dumps({...})
)
```

### Migration d'un module

1. **Créer le nouveau service** avec la même interface
2. **Dupliquer le schéma DB** vers une nouvelle base
3. **Migrer les données** (sync bidirectionnelle temporaire)
4. **Basculer le trafic** progressivement (feature flag)
5. **Supprimer l'ancien module** du monolithe

```python
# Feature flag pour migration progressive
class OrderService:
    async def get_delivery_status(self, order_id: UUID):
        if feature_flags.is_enabled("use_delivery_service"):
            # Appel HTTP vers le nouveau service
            return await self.delivery_client.get_status(order_id)
        else:
            # Ancien code monolithique
            return await self.delivery_service.get_status(order_id)
```

---

## Phase 3 : Microservices Complets

### Architecture cible

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Gateway   │────▶│   Consul    │     │    Vault    │
│   (Kong)    │     │  (Registry) │     │  (Secrets)  │
└──────┬──────┘     └─────────────┘     └─────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│                    RabbitMQ                          │
└──────────────────────────────────────────────────────┘
       │
       ├─────────────┬─────────────┬─────────────┐
       ▼             ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│auth-service │ │order-service│ │delivery-svc │ │payment-svc  │
│  (FastAPI)  │ │   (Actix)   │ │   (Actix)   │ │  (Fastify)  │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │               │               │
       ▼               ▼               ▼               ▼
   [auth_db]       [orders_db]    [delivery_db]   [payments_db]
```

### Infrastructure Phase 3

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| API Gateway | Kong | Routing, rate limiting, auth |
| Service Registry | Consul | Découverte de services |
| Secrets | Vault | Gestion des credentials |
| Message Broker | RabbitMQ/Kafka | Communication async |
| Tracing | Jaeger | Suivi des requêtes |
| Monitoring | Prometheus + Grafana | Métriques |
| Logs | ELK Stack | Logs centralisés |

---

## Checklist de préparation

### Phase 1 (dès le début)

- [ ] Structurer le code en modules isolés
- [ ] Créer des interfaces entre modules
- [ ] Utiliser des schémas PostgreSQL séparés
- [ ] Pas de FK inter-schémas
- [ ] Pas de JOINs SQL inter-schémas
- [ ] Implémenter un bus d'événements interne
- [ ] Stocker des snapshots (pas de références live)

### Avant Phase 2

- [ ] Métriques par module (latence, erreurs)
- [ ] Identifier le module à extraire
- [ ] Documenter l'API du module
- [ ] Préparer l'infrastructure RabbitMQ
- [ ] Plan de migration des données

### Avant Phase 3

- [ ] CI/CD par service
- [ ] Observabilité complète (traces, logs, métriques)
- [ ] Runbooks opérationnels
- [ ] Tests de charge par service
- [ ] Plan de disaster recovery

---

## Résumé

| Aspect | Phase 1 | Phase 2 | Phase 3 |
|--------|---------|---------|---------|
| **Équipe** | 1-5 devs | 5-15 devs | 15+ devs |
| **Déploiement** | 1 service | 2-5 services | N services |
| **Base de données** | 1 DB, N schémas | 2-3 DBs | N DBs |
| **Communication** | In-process | HTTP + RabbitMQ | gRPC + Events |
| **Observabilité** | Logs basiques | APM simple | Stack complète |
| **Infra** | Docker Compose | Docker + quelques outils | Kubernetes |

**Règle d'or** : Ne passez à la phase suivante que lorsque la douleur du monolithe dépasse le coût de la complexité distribuée.
