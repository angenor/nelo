# Cahier des Charges - NELO

**Everything App pour les Services de Proximité en Afrique**

| | |
|:--|:--|
| **Version** | 1.0 |
| **Date** | 14 Décembre 2025 |
| **Statut** | Document de spécification |

---

## Table des Matières

1. [Vision et Objectifs](#1-vision-et-objectifs)
2. [Périmètre Fonctionnel](#2-périmètre-fonctionnel)
3. [Architecture Technique](#3-architecture-technique)
4. [Spécifications des Applications](#4-spécifications-des-applications)
5. [Base de Données](#5-base-de-données)
6. [API et Communication](#6-api-et-communication)
7. [Sécurité](#7-sécurité)
8. [Adaptations Contextuelles](#8-adaptations-contextuelles)
9. [Roadmap et Versioning](#9-roadmap-et-versioning)
10. [Annexes](#10-annexes)

---

## 1. Vision et Objectifs

### 1.1 Vision

Créer un écosystème numérique unifié ("Everything App") connectant les prestataires de services aux consommateurs en Afrique, en répondant aux défis spécifiques du continent : connectivité variable, diversité des moyens de paiement, et nécessité d'inclusion numérique.

### 1.2 Objectifs Stratégiques

| Objectif | Description | Indicateur de Succès |
|:--|:--|:--|
| Accessibilité | App fonctionnelle même avec connexion limitée | Mode offline opérationnel à 80% |
| Inclusion | Interface utilisable par tous les profils | Taux d'abandon < 15% |
| Scalabilité | Architecture évolutive multi-pays | Support de 100K utilisateurs simultanés |
| Rentabilité | Modèle économique viable | Break-even en 6 mois |

### 1.3 Proposition de Valeur

| CLIENTS | PRESTATAIRES | LIVREURS |
|:--|:--|:--|
| • Commande facile | • Visibilité accrue | • Revenus flexibles |
| • Multi-services | • Gestion simplifiée | • Autonomie |
| • Paiement local | • Analytics | • Formation |
| • Confiance | • Crédit accès | • Protection |

---

## 2. Périmètre Fonctionnel

### 2.1 Version 1.0 (MVP)

#### Services Prioritaires

| Service | Description | Acteurs Impliqués |
|:--|:--|:--|
| Restauration | Commande et livraison de repas | Client, Restaurant, Livreur |
| Livraison Gaz | Recharge et échange de bouteilles | Client, Fournisseur, Livreur |
| Courses | Achats délégués avec liste | Client, Livreur |
| Colis Express | Livraison point à point | Client, Livreur |

#### Flux Principal - Restauration

```
┌──────────┐    ┌────────────┐    ┌──────────┐    ┌──────────┐
│  CLIENT  │───▶│ RESTAURANT │───▶│ SYSTÈME  │───▶│ LIVREUR  │
│          │    │            │    │          │    │          │
│ 1.Commande│   │ 2.Validation│   │3.Matching │   │4.Collecte│
│          │    │            │    │           │   │5.Livraison│
│          │◀───│            │◀───│           │◀──│6.Confirm │
│ 7.Note   │    │            │    │           │   │          │
└──────────┘    └────────────┘    └──────────┘    └──────────┘
```

### 2.2 Versions Futures

#### Version 2.0 - Extension Services

| Service | Priorité | Complexité |
|:--|:--|:--|
| Supermarché | Haute | Moyenne |
| Pressing | Moyenne | Faible |
| Résidences/Hôtels | Moyenne | Haute |

#### Version 3.0 - Services Spécialisés

| Service | Priorité | Complexité |
|:--|:--|:--|
| Électricien | Moyenne | Moyenne |
| Plombier | Moyenne | Moyenne |
| Maçon | Basse | Haute |
| Déménagement | Basse | Haute |

#### Version 4.0 - Commerce International

| Service | Priorité | Complexité |
|:--|:--|:--|
| Import/Export | Basse | Très Haute |
| Livraison Inter-villes | Moyenne | Haute |
| Marketplace B2B | Basse | Haute |

---

## 3. Architecture Technique

### 3.1 Philosophie : Monolith-First, Microservice-Ready

L'architecture adopte une approche modulaire monolithique permettant une extraction progressive vers des microservices selon les besoins de scaling.

### 3.2 Stack Technologique

#### Backend - Répartition par Technologie

| Technologie | Domaine | Justification |
|:--|:--|:--|
| FastAPI (Python) | Auth, Users, Admin, AI/ML | Écosystème ML riche, développement rapide |
| Fastify (Node.js) | Notifications, Chat, WebSocket, Payments | I/O async, temps réel performant |
| Actix Web (Rust) | Orders, Delivery, Matching, Géolocalisation | Performance critique, calculs intensifs |

#### Infrastructure

| Composant | Technologie | Usage |
|:--|:--|:--|
| Base de données principale | PostgreSQL | Données relationnelles |
| Cache & Sessions | Redis 7 | Cache, queues, sessions, pub/sub |
| Message Broker | Redis Streams | Communication inter-services |
| Reverse Proxy | Nginx / Traefik | Load balancing, SSL |
| Conteneurisation | Docker + Docker Compose | Déploiement local et staging |
| Orchestration (prod) | Kubernetes / Docker Swarm | Production à grande échelle |
| CDN & Storage | Cloudflare R2 / MinIO | Assets statiques, images |

#### Frontend

| Application | Technologie | Justification |
|:--|:--|:--|
| App Client (Mobile) | Flutter | Cross-platform, performances natives |
| App Prestataire (Mobile) | Flutter | Réutilisation composants |
| App Livreur (Mobile) | Flutter | GPS natif, notifications |
| Dashboard Admin (Web) | Nuxt.js | SSR, SEO admin, Vue ecosystem |

### 3.3 Architecture Détaillée

```
                                ┌─────────────────┐
                                │   CDN / WAF     │
                                │  (Cloudflare)   │
                                └────────┬────────┘
                                         │
                                ┌────────▼────────┐
                                │  API Gateway    │
                                │  (Nginx/Kong)   │
                                └────────┬────────┘
                                         │
    ┌────────────────────────────────────┼────────────────────────────────────┐
    │                                    │                                    │
┌───────▼───────┐           ┌────────────▼────────────┐         ┌────────▼────────┐
│   FastAPI     │           │       Fastify           │         │   Actix Web     │
│   :8000       │           │       :3000             │         │   :8080         │
├───────────────┤           ├─────────────────────────┤         ├─────────────────┤
│ • Auth        │           │ • WebSocket Gateway     │         │ • Orders        │
│ • Users       │           │ • Notifications (Push)  │         │ • Delivery      │
│ • Admin       │           │ • Chat/Messaging        │         │ • Matching Algo │
│ • AI/ML       │           │ • Payment Integration   │         │ • Geolocation   │
│ • Analytics   │           │ • Real-time Events      │         │ • Pricing       │
│ • KYC         │           │                         │         │ • Inventory     │
└───────┬───────┘           └────────────┬────────────┘         └────────┬────────┘
        │                                │                                │
        └────────────────────────────────┼────────────────────────────────┘
                                         │
              ┌──────────────────────────┼──────────────────────┐
              │                          │                      │
     ┌────────▼────────┐        ┌───────▼───────┐      ┌───────▼───────┐
     │   PostgreSQL    │        │    Redis      │      │  Object Store │
     │   (Primary DB)  │        │ (Cache/Queue) │      │  (MinIO/R2)   │
     └─────────────────┘        └───────────────┘      └───────────────┘
```

### 3.4 Arborescence du Projet

Voir `README.md`

---

## 4. Spécifications des Applications

### 4.1 Application Client (B2C)

#### 4.1.1 Écrans et Navigation

```
┌─────────────────────────────────────────────────────────────────┐
│                      NAVIGATION PRINCIPALE                      │
├─────────────────────────────────────────────────────────────────┤
│  [Accueil]   [Commandes]    [Chat]            [Profil]         │
└─────────────────────────────────────────────────────────────────┘
```

**Accueil**
```
├── Localisation(adresse actuelle)
├── Bouton de recherche
├── Carousel Promotions
├── Services Rapides (Icônes)
├── Restaurants Recommandés
├── Commandes Récentes
└── Offres du Moment
```

**Recherche**
```
├── Barre de Recherche avec historique
├── Filtres (Type, Distance, Prix...)
└── Résultats avec Infinite Scroll
```

**Commandes**
```
├── En cours (Temps réel)
├── Historique
└── Planifiées
```

**Profil**
```
├── Informations Personnelles
├── Adresses Sauvegardées
├── Moyens de Paiement
├── Portefeuille NELO
└── Paramètres
```

#### 4.1.2 Fonctionnalités Détaillées

| Fonctionnalité | Description | Priorité |
|:--|:--|:--|
| Géolocalisation Auto | Détection automatique de la position | P0 |
| Mode Offline | Consultation menu, panier hors ligne, commande hors ligne (SMS) | P0 |
| Notifications Push | Statut commande, promotions | P0 |
| Commande Groupée | Partage de livraison entre voisins | P2 |
| Programme Fidélité | Points cumulés, réductions | P1 |
| Planification | Commander pour plus tard | P1 |
| Multi-panier | Plusieurs restaurants en une commande | P2 |

### 4.2 Application Prestataire (B2B)

#### 4.2.1 Types de Comptes

| Type | Services | Fonctionnalités Spécifiques |
|:--|:--|:--|
| Restaurant | Repas, Boissons, Dessert | Menu, préparation, cuisine |
| Dépôt Gaz | Bouteilles gaz | Stock, marques, échange |
| Boutique | Produits divers | Inventaire, catégories |
| Artisan (v2) | Services manuels | Disponibilité, devis |

#### 4.2.2 Fonctionnalités Avancées

| Fonctionnalité | Description | Priorité |
|:--|:--|:--|
| Impression Auto | Ticket commande sur imprimante thermique | P1 |
| Statistiques | Analytics ventes, pics d'activité | P1 |
| Promotions | Créer des offres temporaires | P1 |
| QR Code Menu | Menu digital pour clients sur place | P2 |
| Intégration Stock | Sync avec système existant | P3 |

### 4.3 Application Livreur (B2B)

#### 4.3.1 Algorithme de Matching Livreur

```
Score = w1 × Proximité + w2 × Disponibilité + w3 × Note + w4 × Véhicule + w5 × Historique

Où:
- Proximité (0-100)     : Distance au point de collecte
- Disponibilité (0/100) : Livreur libre ou non
- Note (0-100)          : Note moyenne normalisée
- Véhicule (0-100)      : Adéquation véhicule/colis
- Historique (0-100)    : Fiabilité passée

Pondérations (ajustables):
- w1 = 0.30 (Proximité)
- w2 = 0.25 (Disponibilité)
- w3 = 0.20 (Note)
- w4 = 0.15 (Véhicule)
- w5 = 0.10 (Historique)
```

### 4.4 Dashboard Admin (Web)

#### 4.4.1 Rôles et Permissions

| Rôle | Accès |
|:--|:--|
| Super Admin | Accès total, configuration système |
| Admin | Gestion utilisateurs, commandes, finances |
| Opérateur | Commandes, support, monitoring |
| Support | Tickets, chat, consultation |
| Finance | Transactions, paiements, rapports |
| Marketing | Promotions, notifications, analytics |

---

## 5. Base de Données

### 5.1 PostgreSQL - Schéma Principal

#### Diagramme Entité-Relation Simplifié

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    users     │       │   providers  │       │   drivers    │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │       │ id (PK)      │       │ id (PK)      │
│ phone        │       │ user_id (FK) │       │ user_id (FK) │
│ email        │       │ type         │       │ vehicle_type │
│ role         │       │ name         │       │ is_available │
└──────┬───────┘       └──────┬───────┘       └──────┬───────┘
       │                      │                      │
       │    ┌─────────────────┴──────────────────┐   │
       │    │                                    │   │
       ▼    ▼                                    ▼   ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   orders     │───────│ order_items  │       │  deliveries  │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │       │ id (PK)      │       │ id (PK)      │
│ user_id (FK) │       │ order_id(FK) │       │ order_id(FK) │
│ provider_id  │       │ product_id   │       │ driver_id(FK)│
│ status       │       │ quantity     │       │ status       │
│ total        │       │ price        │       │ delivered_at │
└──────────────┘       └──────────────┘       └──────────────┘
```

#### Tables Principales

Le schéma complet comprend les tables suivantes :

- `users`, `user_addresses` - Gestion des utilisateurs et adresses
- `providers`, `provider_schedules`, `provider_categories` - Prestataires
- `products`, `product_options`, `product_option_items` - Catalogue produits
- `gas_products` - Produits gaz spécifiques
- `drivers`, `driver_documents`, `driver_availability` - Livreurs
- `orders`, `order_items`, `order_status_history` - Commandes
- `deliveries`, `delivery_location_history` - Livraisons
- `wallets`, `transactions` - Paiements
- `ratings` - Évaluations
- `cities`, `zones`, `pricing_rules` - Zones et tarification
- `promotions`, `user_promotions` - Promotions
- `notifications`, `push_tokens` - Notifications
- `conversations`, `messages` - Chat

### 5.2 Redis - Structure des Données

```redis
# Sessions Utilisateurs
session:{user_id}                    # Hash: données session (TTL: 7 jours)

# Cache Restaurants
provider:{provider_id}               # Hash: infos provider cachées
provider:menu:{provider_id}          # String: menu JSON (TTL: 5 minutes)

# Livreurs Disponibles
drivers:available:{city}             # Sorted Set (score = timestamp)
driver:location:{driver_id}          # Geo: position actuelle (TTL: 30 sec)

# Commandes en Temps Réel
order:{order_id}:status              # String: statut actuel
orders:pending:{city}                # List: commandes en attente

# Pub/Sub Channels
channel:order:{order_id}             # Mises à jour commande
channel:driver:{driver_id}           # Notifications livreur

# Queues (Redis Streams)
stream:notifications                 # Queue notifications push
stream:matching                      # Queue matching livreurs
```

---

## 6. API et Communication

### 6.1 Convention API REST

#### Structure des Endpoints

```
Base URL: https://api.nelo.app/v1

Authentication:
  POST   /auth/register           # Inscription
  POST   /auth/login              # Connexion
  POST   /auth/verify-otp         # Vérification OTP
  POST   /auth/refresh            # Refresh token

Users:
  GET    /users/me                # Profil actuel
  PUT    /users/me                # Modifier profil
  GET    /users/me/addresses      # Mes adresses

Providers:
  GET    /providers               # Liste (filtres, pagination)
  GET    /providers/:id           # Détail
  GET    /providers/:id/menu      # Menu
  GET    /providers/nearby        # À proximité (géoloc)

Orders:
  POST   /orders                  # Créer commande
  GET    /orders                  # Mes commandes
  GET    /orders/:id              # Détail commande
  PUT    /orders/:id/cancel       # Annuler
  GET    /orders/:id/tracking     # Suivi temps réel

Payments:
  GET    /wallet                  # Solde portefeuille
  POST   /wallet/topup            # Recharger
  POST   /payments/initiate       # Initier paiement
```

### 6.2 WebSocket Events

```javascript
// Client Events (émis par le client)
{ "event": "subscribe:order", "data": { "order_id": "uuid" } }
{ "event": "driver:location", "data": { "lat": 5.3364, "lng": -4.0267 } }

// Server Events (émis par le serveur)
{ "event": "order:status_changed", "data": { "order_id": "uuid", "status": "preparing" } }
{ "event": "delivery:location_update", "data": { "delivery_id": "uuid", "eta_minutes": 8 } }
{ "event": "order:new", "data": { "order_id": "uuid", "total": 5500 } }  // Pour prestataires
```

---

## 7. Sécurité

### 7.1 Authentification

| Méthode | Usage | Détails |
|:--|:--|:--|
| JWT | API Auth | Access token (15min) + Refresh token (7j) |
| OTP SMS | Vérification téléphone | Code 6 chiffres, 5min validité |
| PIN | Transactions | Code 4 chiffres hashé |
| Biométrie | Login rapide | Touch ID / Face ID (optionnel) |

### 7.2 Sécurité API

**Rate Limiting:**

- Global: 1000 req/min par IP
- Auth endpoints: 10 req/min par IP
- OTP: 3 tentatives par numéro / 15min

**Chiffrement:**

- HTTPS obligatoire (TLS 1.3)
- Mots de passe: Argon2id
- Données sensibles: AES-256-GCM

### 7.3 Protection des Données

| Donnée | Classification | Protection |
|:--|:--|:--|
| Mots de passe | Critique | Hash Argon2id, jamais stocké en clair |
| Numéros téléphone | Sensible | Masquage partiel en affichage |
| Positions GPS | Sensible | Rétention 30 jours, anonymisation |
| Documents ID | Critique | Chiffrement, accès restreint |
| Transactions | Sensible | Audit trail complet |

### 7.4 KYC (Know Your Customer)

```
Prestataires:
├── Niveau 1 (Basique)
│   ├── Numéro téléphone vérifié
│   ├── Email vérifié (optionnel)
│   └── Limite: 500 000 XOF/mois
│
├── Niveau 2 (Standard)
│   ├── Pièce d'identité vérifiée
│   ├── Selfie avec ID
│   └── Limite: 5 000 000 XOF/mois
│
└── Niveau 3 (Business)
    ├── Documents entreprise
    ├── Registre commerce
    └── Limite: Illimitée

Livreurs:
├── Pièce d'identité obligatoire
├── Photo de profil vérifiée
├── Permis (si véhicule motorisé)
├── Assurance (si véhicule)
└── Photo véhicule
```

---

## 8. Adaptations Contextuelles

### 8.1 Mode Offline

| Disponible Offline | Requiert Connexion |
|:--|:--|
| Consultation menus | Passer commande |
| Panier (création/modif) | Paiement |
| Historique commandes | Tracking temps réel |
| Profil et adresses | Chat |
| Favoris | Notifications push |
| Recherche locale | Recherche distante |

### 8.2 Optimisation Réseau

| Technique | Implémentation |
|:--|:--|
| Compression Images | WebP avec fallback JPEG, plusieurs résolutions |
| Lazy Loading | Chargement progressif des listes |
| Delta Sync | Sync incrémentale des données |
| Compression API | Gzip/Brotli sur toutes les réponses |
| Cache Agressif | Menus, images avec ETag |

### 8.3 Paiements Locaux

**CINETPAY (Agrégateur Principal):**

- MTN Mobile Money
- Orange Money
- Wave
- Airtel Money
- M-Pesa
- Cartes bancaires

**PORTEFEUILLE NELO:**

- Rechargement via Mobile Money
- Points de vente partenaires
- Transfert P2P
- Cashback

**CASH:**

- Paiement à la livraison
- Confirmation par code

### 8.4 Multilingue

| Langue | Code | Priorité | Couverture |
|:--|:--|:--|:--|
| Français | fr | P0 | 100% |
| Anglais | en | P0 | 100% |

---

## 9. Roadmap et Versioning

### 9.1 Version 1.0 - MVP

**Objectifs:**

- Service restauration complet
- Service gaz complet
- Service courses simple
- 1 ville pilote (Tiassalé)

#### Fonctionnalités MVP

| Module | Fonctionnalités |
|:--|:--|
| CLIENT | Inscription/Connexion, Recherche, Commande, Tracking, Notification, Paiement, Notation |
| PRESTATAIRE | Inscription/Validation, Menu, Réception commandes, Dashboard |
| LIVREUR | Inscription/Validation, Réception courses, Navigation, Gains |
| ADMIN | Dashboard, Gestion utilisateurs/commandes, Support, Configuration |

### 9.2 Version 2.0 - Extension

**Objectifs:**

- Multi-villes (5 villes)
- Programme fidélité
- Amélioration UX
- Boutiques/Supermarchés

### 9.3 Version 3.0 - Services Avancés

**Objectifs:**

- IA et personnalisation
- Services artisans
- Import/Export
- Expansion régionale

---

## 10. Annexes

### 10.1 Glossaire

| Terme | Définition |
|:--|:--|
| Provider | Prestataire de service (restaurant, dépôt gaz, boutique) |
| Driver | Livreur/Coursier |
| Matching | Algorithme d'attribution des livreurs aux commandes |
| Surge Pricing | Tarification dynamique en période de forte demande |
| KYC | Know Your Customer - Vérification d'identité |
| Mobile Money | Paiement mobile (MTN, Orange, Wave) |

### 10.2 Références Techniques

| Technologie | Documentation |
|:--|:--|
| FastAPI | https://fastapi.tiangolo.com |
| Fastify | https://www.fastify.io |
| Actix Web | https://actix.rs |
| Flutter | https://flutter.dev |
| PostgreSQL | https://www.postgresql.org/docs |
| Redis | https://redis.io/documentation |
| CinetPay | https://cinetpay.com/documentation |

### 10.3 Contacts et Ressources

| Rôle | Responsabilité |
|:--|:--|
| Product Owner | Vision produit, priorisation |
| Tech Lead | Architecture, décisions techniques |
| Backend Lead | Services backend, API |
| Mobile Lead | Applications Flutter |
| DevOps | Infrastructure, CI/CD |
| QA Lead | Tests, qualité |

---

*Document rédigé le: 14 Décembre 2025*

*Version: 1.0 | Statut: Draft pour validation*

*Ce document est évolutif et sera mis à jour au fil du développement du projet.*