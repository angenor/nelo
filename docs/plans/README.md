# Plans d'Implementation MVP Phase 1

**Developpement en parallele**

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

| # | Plan | Dependances | Description |
|---|------|-------------|-------------|
| 1 | [Backend](01_BACKEND.md) | - | Infrastructure + API FastAPI (M1-M5) |
| 2 | [App Client](02_APP_CLIENT.md) | Backend M2+ | Application mobile consommateurs |
| 3 | [App Provider](03_APP_PROVIDER.md) | Backend M3+ | Application mobile prestataires |
| 4 | [App Driver](04_APP_DRIVER.md) | Backend M4+ | Application mobile livreurs |
| 5 | [Web Admin](05_WEB_ADMIN.md) | Backend M2+ | Dashboard administration Nuxt 4 |
| 6 | [Lancement](06_LANCEMENT.md) | Tous | Deploiement et go-live (M7) |

---

## Ordre de Developpement Recommande

```
Semaine 1-2:   [Backend M1] Infrastructure
               ↓
Semaine 3-4:   [Backend M2] Auth    ──→  [App Client] Setup + Auth
               ↓                         [Web Admin] Setup + Auth
Semaine 5-6:   [Backend M3] Catalogue ─→ [App Client] Home + Catalogue
               ↓                         [App Provider] Setup + Dashboard
Semaine 7-9:   [Backend M4] Commandes ─→ [App Client] Commandes
               ↓                         [App Provider] Commandes
                                         [App Driver] Setup + Courses
Semaine 10-11: [Backend M5] Paiements ─→ [App Client] Wallet
               ↓                         [Web Admin] Gestion complete
Semaine 12-15: Integration + Tests
               ↓
Semaine 16:    [Lancement] MVP Live
```

---

## Developpement Parallele

### Equipe Backend
1. Commencer par [01_BACKEND.md](01_BACKEND.md)
2. Livrer les endpoints au fur et a mesure
3. Documenter l'API (Swagger)

### Equipe Mobile Client
1. Commencer [02_APP_CLIENT.md](02_APP_CLIENT.md) des que M2 (Auth) est pret
2. Utiliser des mocks en attendant les endpoints

### Equipe Mobile Provider
1. Commencer [03_APP_PROVIDER.md](03_APP_PROVIDER.md) des que M3 (Catalogue) est pret

### Equipe Mobile Driver
1. Commencer [04_APP_DRIVER.md](04_APP_DRIVER.md) des que M4 (Commandes) est pret

### Equipe Web Admin
1. Commencer [05_WEB_ADMIN.md](05_WEB_ADMIN.md) en parallele avec Backend M2

---

## Priorites P0 (MVP Obligatoire)

| Fonctionnalite | Backend | App Client | App Provider | App Driver | Web Admin |
|----------------|---------|------------|--------------|------------|-----------|
| Auth OTP | M2 | x | x | x | x |
| Geolocalisation | M3 | x | - | x | - |
| Commande restaurant | M4 | x | x | - | x |
| Paiement wallet | M5 | x | - | - | x |
| Tracking livraison | M4 | x | - | x | x |
| Notifications push | M6 | x | x | x | - |

---

## Documents de Reference

| Document | Lien |
|----------|------|
| Specifications | [01_CAHIER_DES_CHARGES.md](../01_CAHIER_DES_CHARGES.md) |
| Architecture | [02_ARCHITECTURE.md](../02_ARCHITECTURE.md) |
| Schema SQL | `databases/monolith/schema.sql` |
