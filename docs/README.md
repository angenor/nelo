# Documentation NELO

## Ordre de lecture recommande

| # | Document | Description |
|---|----------|-------------|
| 1 | [Cahier des Charges](01_CAHIER_DES_CHARGES.md) | Vision, specifications fonctionnelles, API |
| 2 | [Architecture](02_ARCHITECTURE.md) | Strategie Monolith-First, regles, patterns |
| 3 | [Plan MVP Phase 1](03_PLAN_MVP_PHASE1.md) | Vue d'ensemble et index des plans |

---

## Plans de Developpement (Parallele)

| Plan | Description |
|------|-------------|
| [Backend](plans/01_BACKEND.md) | Infrastructure + API FastAPI (M1-M5) |
| [App Client](plans/02_APP_CLIENT.md) | Application mobile consommateurs |
| [App Provider](plans/03_APP_PROVIDER.md) | Application mobile prestataires |
| [App Driver](plans/04_APP_DRIVER.md) | Application mobile livreurs |
| [Web Admin](plans/05_WEB_ADMIN.md) | Dashboard administration Nuxt 4 |
| [Lancement](plans/06_LANCEMENT.md) | Deploiement et go-live (M7) |

**Index complet** : [plans/README.md](plans/README.md)

---

## Structure de la documentation

```
docs/
├── README.md                    # Ce fichier (index)
├── 01_CAHIER_DES_CHARGES.md     # Specifications completes
├── 02_ARCHITECTURE.md           # Strategie Monolith-First
├── 03_PLAN_MVP_PHASE1.md        # Index des plans MVP
│
└── plans/                       # Plans detailles par application
    ├── README.md                # Index des plans
    ├── 01_BACKEND.md            # Backend FastAPI (M1-M5)
    ├── 02_APP_CLIENT.md         # App Flutter Client
    ├── 03_APP_PROVIDER.md       # App Flutter Provider
    ├── 04_APP_DRIVER.md         # App Flutter Driver
    ├── 05_WEB_ADMIN.md          # Dashboard Nuxt 4
    └── 06_LANCEMENT.md          # Deploiement (M7)
```

---

## Quick Start

### Pour commencer le developpement

1. **Lire** : [03_PLAN_MVP_PHASE1.md](03_PLAN_MVP_PHASE1.md) pour la vue d'ensemble
2. **Choisir** : Le plan correspondant a votre equipe dans `plans/`
3. **Commencer** : Backend M1 en premier ([plans/01_BACKEND.md](plans/01_BACKEND.md))

### Par equipe

| Equipe | Plan | A partir de |
|--------|------|-------------|
| Backend | [plans/01_BACKEND.md](plans/01_BACKEND.md) | Maintenant |
| Mobile Client | [plans/02_APP_CLIENT.md](plans/02_APP_CLIENT.md) | Apres M2 (Auth) |
| Mobile Provider | [plans/03_APP_PROVIDER.md](plans/03_APP_PROVIDER.md) | Apres M3 (Catalogue) |
| Mobile Driver | [plans/04_APP_DRIVER.md](plans/04_APP_DRIVER.md) | Apres M4 (Commandes) |
| Web Admin | [plans/05_WEB_ADMIN.md](plans/05_WEB_ADMIN.md) | Apres M2 (Auth) |

---

## Documents de reference

| Besoin | Document |
|--------|----------|
| Comprendre le projet | [01_CAHIER_DES_CHARGES.md](01_CAHIER_DES_CHARGES.md) |
| Architecture backend | [02_ARCHITECTURE.md](02_ARCHITECTURE.md) |
| Vue d'ensemble MVP | [03_PLAN_MVP_PHASE1.md](03_PLAN_MVP_PHASE1.md) |
| Structure cible | [../README.md](../README.md) |
| Schema SQL | `../databases/monolith/schema.sql` |

---

## Phases du projet

| Phase | Description | Statut |
|-------|-------------|--------|
| **Phase 1** | Monolithe modulaire (MVP) | **En cours** |
| Phase 2 | Extraction progressive | A venir |
| Phase 3 | Microservices complets | A venir |
