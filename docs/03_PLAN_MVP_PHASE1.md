# Plan MVP Phase 1

**Version MVP - Monolith-First**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Approche** | Monolith-First, Microservice-Ready |
| **Stack Backend** | FastAPI (Python) - Monolithe modulaire |
| **Stack Frontend** | Flutter (Mobile) + Nuxt 4 (Admin) |
| **Base de donnees** | PostgreSQL + Redis |
| **Ville pilote** | Tiassale, Cote d'Ivoire |

---

## Plans par Application

Les plans sont separes pour permettre le developpement en parallele:

| # | Plan | Contenu |
|---|------|---------|
| 1 | [Backend](plans/01_BACKEND.md) | Infrastructure + API FastAPI (M1-M5) |
| 2 | [App Client](plans/02_APP_CLIENT.md) | Application mobile consommateurs |
| 3 | [App Provider](plans/03_APP_PROVIDER.md) | Application mobile prestataires |
| 4 | [App Driver](plans/04_APP_DRIVER.md) | Application mobile livreurs |
| 5 | [Web Admin](plans/05_WEB_ADMIN.md) | Dashboard administration Nuxt 4 |
| 6 | [Lancement](plans/06_LANCEMENT.md) | Deploiement et go-live (M7) |

**Index complet** : [plans/README.md](plans/README.md)

---

## Jalons (Milestones)

| Milestone | Semaines | Objectif | Plan |
|-----------|----------|----------|------|
| M1 | 1-2 | Infrastructure de Base | [Backend](plans/01_BACKEND.md#m1-infrastructure-de-base-semaines-1-2) |
| M2 | 3-4 | Auth & Users | [Backend](plans/01_BACKEND.md#m2-authentification--utilisateurs-semaines-3-4) |
| M3 | 5-6 | Catalogue | [Backend](plans/01_BACKEND.md#m3-catalogue-prestataires--produits-semaines-5-6) |
| M4 | 7-9 | Commandes | [Backend](plans/01_BACKEND.md#m4-systeme-de-commandes-semaines-7-9) |
| M5 | 10-11 | Paiements | [Backend](plans/01_BACKEND.md#m5-systeme-de-paiements-semaines-10-11) |
| M6 | 12-15 | Apps Frontend | [App Client](plans/02_APP_CLIENT.md), [Provider](plans/03_APP_PROVIDER.md), [Driver](plans/04_APP_DRIVER.md), [Admin](plans/05_WEB_ADMIN.md) |
| M7 | 16 | MVP Live | [Lancement](plans/06_LANCEMENT.md) |

---

## Ordre de Developpement

```
Semaine 1-2:   [Backend M1] Infrastructure
                    |
Semaine 3-4:   [Backend M2] Auth ──────> [App Client] Setup + Auth
                    |                    [Web Admin] Setup + Auth
                    |
Semaine 5-6:   [Backend M3] Catalogue ─> [App Client] Home + Catalogue
                    |                    [App Provider] Setup + Dashboard
                    |
Semaine 7-9:   [Backend M4] Commandes ─> [App Client] Commandes
                    |                    [App Provider] Commandes
                    |                    [App Driver] Setup + Courses
                    |
Semaine 10-11: [Backend M5] Paiements ─> [App Client] Wallet
                    |                    [Web Admin] Gestion complete
                    |
Semaine 12-15: Integration + Tests complets
                    |
Semaine 16:    [Lancement] MVP Live
```

---

## Developpement Parallele

### Equipe Backend
Commencer par [plans/01_BACKEND.md](plans/01_BACKEND.md)

### Equipe Mobile Client
Commencer [plans/02_APP_CLIENT.md](plans/02_APP_CLIENT.md) des que M2 (Auth) est pret

### Equipe Mobile Provider
Commencer [plans/03_APP_PROVIDER.md](plans/03_APP_PROVIDER.md) des que M3 (Catalogue) est pret

### Equipe Mobile Driver
Commencer [plans/04_APP_DRIVER.md](plans/04_APP_DRIVER.md) des que M4 (Commandes) est pret

### Equipe Web Admin
Commencer [plans/05_WEB_ADMIN.md](plans/05_WEB_ADMIN.md) en parallele avec Backend M2

---

## Priorites P0 (MVP Obligatoire)

| Fonctionnalite | Priorite | Milestone |
|----------------|----------|-----------|
| Auth OTP | P0 | M2 |
| Geolocalisation | P0 | M3 |
| Commande restaurant | P0 | M4 |
| Paiement wallet | P0 | M5 |
| Tracking livraison | P0 | M4 |
| Notifications push | P0 | M6 |

---

## Documents de Reference

| Document | Description |
|----------|-------------|
| [01_CAHIER_DES_CHARGES.md](01_CAHIER_DES_CHARGES.md) | Specifications fonctionnelles |
| [02_ARCHITECTURE.md](02_ARCHITECTURE.md) | Strategie Monolith-First |
| `databases/monolith/schema.sql` | Schema SQL complet |

---

## Prochaine Etape

**Commencer par le Backend M1** : [plans/01_BACKEND.md](plans/01_BACKEND.md)

1. Creer la structure de dossiers Phase 1
2. Initialiser le projet FastAPI
3. Configurer Docker Compose
4. Executer les migrations de base de donnees
