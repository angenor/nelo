# Plan Backend - nelo-api

**FastAPI Monolithe Modulaire (M1-M5)**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Framework** | FastAPI |
| **Base de donnees** | PostgreSQL + PostGIS |
| **Cache** | Redis |
| **ORM** | SQLAlchemy 2.0 |
| **Migrations** | Alembic |

---

## M1: Infrastructure de Base (Semaines 1-2)

### Objectif
Mettre en place l'environnement de developpement et l'infrastructure de base.

### 1.1 Structure du projet

Creer la structure selon [02_ARCHITECTURE.md](../02_ARCHITECTURE.md):

```
services/
└── nelo-api/
    ├── app/
    │   ├── modules/
    │   │   ├── auth/
    │   │   │   ├── __init__.py
    │   │   │   ├── router.py
    │   │   │   ├── service.py
    │   │   │   ├── schemas.py
    │   │   │   └── dependencies.py
    │   │   ├── users/
    │   │   ├── orders/
    │   │   ├── deliveries/
    │   │   ├── payments/
    │   │   └── notifications/
    │   ├── core/
    │   │   ├── config.py
    │   │   ├── database.py
    │   │   ├── security.py
    │   │   └── exceptions.py
    │   ├── shared/
    │   │   ├── interfaces/
    │   │   └── events/
    │   └── main.py
    ├── tests/
    ├── alembic/
    ├── pyproject.toml
    └── Dockerfile
```

- [x] Creer la structure de dossiers
- [x] Configurer `.gitignore`, `.editorconfig`, `.env.example`

### 1.2 Initialisation FastAPI
- [x] Initialiser le projet avec `pyproject.toml`
- [x] Configurer SQLAlchemy + Alembic
- [x] Configurer Pydantic settings
- [x] Implementer le health check endpoint
- [x] Configurer CORS

### 1.3 Base de donnees
- [x] Deployer PostgreSQL avec PostGIS
- [x] Creer les schemas (auth, users, orders, deliveries, payments, notifications)
- [x] Executer `databases/monolith/schema.sql`
- [x] Configurer Alembic pour les migrations
- [ ] Creer les seeds pour Tiassale (villes, zones)

### 1.4 Cache et Sessions
- [x] Deployer Redis
- [x] Configurer le client Redis async
- [ ] Implementer le gestionnaire de sessions

### 1.5 Docker
- [x] Creer `Dockerfile` pour nelo-api
- [x] Creer `docker-compose.yml` (api, postgres, redis)
- [x] Creer `docker-compose.dev.yml` avec hot-reload
- [x] Documenter le setup

### Livrables M1
- [x] Environnement Docker fonctionnel
- [x] API accessible sur `http://localhost:8000`
- [x] Documentation Swagger sur `/docs`
- [x] Base de donnees initialisee

---

## M2: Authentification & Utilisateurs (Semaines 3-4)

### Objectif
Implementer le systeme d'authentification et la gestion des utilisateurs.

### 2.1 Module Auth

**Endpoints:**
```
POST /api/v1/auth/register       # Inscription par telephone
POST /api/v1/auth/login          # Connexion
POST /api/v1/auth/send-otp       # Envoi OTP
POST /api/v1/auth/verify-otp     # Verification OTP
POST /api/v1/auth/refresh        # Refresh token
POST /api/v1/auth/logout         # Deconnexion
```

**Taches:**
- [x] Service OTP
  - [x] Generation code 6 chiffres
  - [x] Stockage Redis (TTL 5 min)
  - [x] Limite 3 tentatives
  - [ ] Integration SMS (Orange CI / Twilio) - stub cree, a integrer
- [x] Service JWT
  - [x] Access token (15 min)
  - [x] Refresh token (7 jours)
  - [x] Blacklist tokens (Redis)
- [x] Middleware d'authentification
- [x] Hashage mots de passe (Argon2)
- [x] Protection PIN (hash + rate limiting)

### 2.2 Module Users

**Endpoints:**
```
GET    /api/v1/users/me              # Profil courant
PUT    /api/v1/users/me              # Modifier profil
GET    /api/v1/users/me/addresses    # Lister adresses
POST   /api/v1/users/me/addresses    # Ajouter adresse
PUT    /api/v1/users/me/addresses/:id
DELETE /api/v1/users/me/addresses/:id
```

**Taches:**
- [x] Gestion des roles (client, provider, driver, admin)
- [ ] Upload avatar (vers MinIO/R2) - a implementer avec stockage
- [x] Systeme de parrainage (referral_code) - generation code auto

### 2.3 KYC de base
- [ ] Endpoint upload documents
- [ ] Stockage securise des documents
- [ ] Workflow de verification (manuel en MVP)

### Livrables M2
- [x] Authentification complete par OTP
- [x] Gestion des profils utilisateurs
- [ ] Tests unitaires et d'integration
- [x] Documentation API (OpenAPI) - auto-generee par FastAPI

---

## M3: Catalogue Prestataires & Produits (Semaines 5-6)

### Objectif
Implementer la gestion des prestataires, menus et produits.

### 3.1 Gestion des Prestataires

**Endpoints:**
```
GET  /api/v1/providers           # Liste avec filtres
GET  /api/v1/providers/nearby    # A proximite (geoloc)
GET  /api/v1/providers/:id       # Detail
GET  /api/v1/providers/:id/menu  # Menu complet
POST /api/v1/providers           # Creer (admin/provider)
PUT  /api/v1/providers/:id       # Modifier
```

**Taches:**
- [x] Types de prestataires (Restaurant, Depot gaz, Epicerie)
- [x] Recherche geospatiale (PostGIS)
  - [x] Providers dans un rayon
  - [x] Tri par distance
- [x] Systeme d'horaires (schedules)
- [x] Calcul `is_open` en temps reel

### 3.2 Gestion des Produits
- [x] CRUD produits standards
- [x] CRUD produits gaz (gas_products)
- [x] Categories de produits
- [x] Options et variations
- [x] Gestion des prix
- [x] Disponibilite (stock)

### 3.3 Cache et Performance
- [x] Cache Redis pour les menus (5 min TTL)
- [ ] Cache des providers proches - a optimiser
- [x] Pagination et infinite scroll

### Livrables M3
- [x] API catalogue complete
- [x] Recherche geolocalisee
- [ ] Tests de performance (< 200ms latence) - a valider

---

## M4: Systeme de Commandes (Semaines 7-9)

### Objectif
Implementer le flux complet de commande.

### 4.1 Creation de Commandes

**Endpoints:**
```
POST /api/v1/orders              # Creer commande
GET  /api/v1/orders              # Mes commandes
GET  /api/v1/orders/:id          # Detail
PUT  /api/v1/orders/:id/cancel   # Annuler
GET  /api/v1/orders/:id/tracking # Suivi
```

**Taches:**
- [x] Validation du panier
  - Verification disponibilite produits
  - Calcul des prix
  - Application des promotions
- [x] Snapshot de l'adresse de livraison (JSONB)
- [x] Generation reference unique (ORD-XXXXXXXX)

### 4.2 Machine d'Etats (Order Status)

```
pending -> confirmed -> preparing -> ready -> picked_up -> delivering -> delivered
    |          |            |          |           |             |
cancelled  cancelled   cancelled  cancelled   cancelled       failed
```

- [x] Implementer les transitions d'etat
- [x] Historique des changements (order_status_history)
- [x] Validation des transitions
- [x] Notifications a chaque changement

### 4.3 Module Livraisons

**Endpoints:**
```
POST /api/v1/drivers/register      # Inscription livreur
PUT  /api/v1/drivers/me/status     # Online/Offline
PUT  /api/v1/drivers/me/location   # MAJ position
GET  /api/v1/drivers/offers        # Courses disponibles
POST /api/v1/drivers/offers/:id/accept
POST /api/v1/drivers/offers/:id/reject
```

**Algorithme de matching:**
```python
score = (
    0.30 * proximite_score +
    0.25 * disponibilite_score +
    0.20 * note_score +
    0.15 * vehicule_score +
    0.10 * historique_score
)
```

- [x] Systeme d'offres (delivery_offers)
- [x] Acceptation/Refus des courses
- [x] Tracking GPS en temps reel

### 4.4 Bus d'Evenements Interne

- [x] Implementer EventBus (in-process) *(fait en M1)*
- [x] Evenements:
  - `order.created`
  - `order.confirmed`
  - `order.ready`
  - `delivery.assigned`
  - `delivery.picked_up`
  - `delivery.completed`
- [x] Handlers de notifications

### Livrables M4
- [x] Flux de commande complet
- [x] Matching livreurs fonctionnel
- [x] Suivi en temps reel (polling)

---

## M5: Systeme de Paiements (Semaines 10-11)

### Objectif
Implementer le portefeuille et les paiements.

### 5.1 Portefeuille NELO

**Endpoints:**
```
GET  /api/v1/wallet              # Solde
GET  /api/v1/wallet/transactions # Historique
POST /api/v1/wallet/topup        # Recharger
POST /api/v1/wallet/transfer     # Transfert P2P
```

**Taches:**
- [ ] Verification PIN pour transactions
- [ ] Limites journalieres/mensuelles
- [ ] Gel de compte si suspect

### 5.2 Integration Paiements

- [ ] Provider Wave (Mobile Money)
  - Initiation paiement
  - Webhook callback
  - Verification statut
- [ ] Provider CinetPay (backup)
- [ ] Paiement cash a la livraison
  - Collecte par livreur
  - Reconciliation

### 5.3 Transactions

**Types:**
- `topup` - recharge
- `payment` - paiement commande
- `refund` - remboursement
- `transfer` - transfert
- `commission` - prelevement

**Commissions:**
- Prestataires: 15% par defaut
- Livreurs: 10% par defaut

- [ ] Audit trail complet

### 5.4 Payouts (Versements)
- [ ] Calcul gains prestataires
- [ ] Calcul gains livreurs
- [ ] Export pour paiement manuel (MVP)

### Livrables M5
- [ ] Portefeuille fonctionnel
- [ ] Integration Wave
- [ ] Systeme de commissions

---

## Stack Technique

```toml
[project]
dependencies = [
    "fastapi>=0.109.0",
    "uvicorn[standard]>=0.27.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.13.0",
    "asyncpg>=0.29.0",
    "redis>=5.0.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[argon2]>=1.7.4",
    "httpx>=0.26.0",
    "geoalchemy2>=0.14.0",
    "shapely>=2.0.0",
    "python-multipart>=0.0.6",
    "pillow>=10.2.0",
    "boto3>=1.34.0",
]
```

---

## Tests

```bash
# Lancer tous les tests
pytest

# Tests avec couverture
pytest --cov=app --cov-report=html

# Tests d'un module specifique
pytest tests/test_auth.py -v
```

---

## Dependances Frontend

Les apps frontend peuvent commencer leur developpement:

| App | A partir de | Endpoints disponibles |
|-----|-------------|----------------------|
| App Client | M2 | Auth, Users |
| App Provider | M3 | + Providers, Products |
| App Driver | M4 | + Orders, Deliveries |
| Web Admin | M2 | Tous au fur et a mesure |
