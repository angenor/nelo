# Plan App Provider - mobile-provider

**Application Flutter pour les Prestataires**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Framework** | Flutter |
| **Architecture** | Clean Architecture + BLoC |
| **Utilisateurs** | Restaurants, Depots gaz, Epiceries |

---

## Prerequis Backend

| Fonctionnalite | Milestone Backend | Endpoints requis |
|----------------|-------------------|------------------|
| Auth | M2 | `/auth/*`, `/users/*` |
| Mon commerce | M3 | `/providers/*`, `/products/*` |
| Commandes | M4 | `/orders/*` (provider view) |
| Finances | M5 | `/wallet/*`, `/payouts/*` |

---

## Structure du Projet

```
apps/mobile-provider/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   │
│   └── presentation/
│       ├── blocs/
│       └── screens/
│           ├── splash/
│           ├── auth/
│           ├── dashboard/
│           ├── orders/
│           ├── menu/
│           ├── products/
│           ├── schedules/
│           ├── finances/
│           └── settings/
│
├── assets/
├── test/
└── pubspec.yaml
```

---

## Ecrans et Fonctionnalites

### Phase 1: Setup + Auth (avec Backend M2)

#### 1.1 Setup Projet
- [ ] Creer le projet Flutter
- [ ] Configurer la structure Clean Architecture
- [ ] Configurer l'injection de dependances
- [ ] Theme adapte aux prestataires (couleurs pro)

#### 1.2 Authentification
- [ ] Connexion prestataire
- [ ] Verification OTP
- [ ] Gestion des tokens

### Phase 2: Dashboard + Menu (avec Backend M3)

#### 2.1 Dashboard
- [ ] Stats du jour
  - Nombre de commandes
  - Chiffre d'affaires
  - Note moyenne
- [ ] Commandes en attente (preview)
- [ ] Toggle Ouvert/Ferme
- [ ] Alertes (stock bas, etc.)

#### 2.2 Gestion Menu
- [ ] Liste des categories
- [ ] CRUD categories
- [ ] Organisation (drag & drop)

#### 2.3 Gestion Produits
- [ ] Liste des produits par categorie
- [ ] Ajout produit
  - Photo
  - Nom, description
  - Prix
  - Options/Variations
- [ ] Modification produit
- [ ] Toggle disponibilite
- [ ] Suppression produit

#### 2.4 Horaires
- [ ] Configuration horaires par jour
- [ ] Horaires exceptionnels
- [ ] Fermeture temporaire

### Phase 3: Commandes (avec Backend M4)

#### 3.1 Commandes Entrantes
- [ ] Liste temps reel des nouvelles commandes
- [ ] Notification sonore
- [ ] Detail commande
- [ ] Boutons Accepter / Refuser
- [ ] Timer pour reponse

#### 3.2 Commandes en Cours
- [ ] Liste des commandes acceptees
- [ ] Bouton "Pret" (commande terminee)
- [ ] Statut du livreur
- [ ] Contact client

#### 3.3 Historique
- [ ] Liste des commandes passees
- [ ] Filtres (date, statut)
- [ ] Export CSV (optionnel)

#### 3.4 Impression
- [ ] Integration imprimante thermique (Bluetooth)
- [ ] Format ticket de commande
- [ ] Impression automatique (optionnel)

### Phase 4: Finances (avec Backend M5)

#### 4.1 Tableau de Bord Financier
- [ ] Solde disponible
- [ ] Gains du jour/semaine/mois
- [ ] Commissions prelevees
- [ ] Graphique evolution

#### 4.2 Historique Transactions
- [ ] Liste des transactions
- [ ] Filtres (type, date)
- [ ] Detail transaction

#### 4.3 Versements
- [ ] Historique des versements
- [ ] Prochain versement prevu
- [ ] Configuration RIB/Mobile Money

### Phase 5: Parametres

#### 5.1 Profil Commerce
- [ ] Informations generales
- [ ] Logo et photos
- [ ] Adresse
- [ ] Description

#### 5.2 Notifications
- [ ] Son nouvelle commande
- [ ] Notifications push
- [ ] Alertes stock

#### 5.3 Equipe (optionnel MVP)
- [ ] Ajout employes
- [ ] Permissions

---

## Fonctionnalites Specifiques

### Notifications Sonores
- [ ] Son distinct pour nouvelle commande
- [ ] Repetition si non traite
- [ ] Volume configurable

### Mode Impression
- [ ] Detection imprimante Bluetooth
- [ ] Preview ticket
- [ ] Impression automatique a la confirmation

### Gestion Stock
- [ ] Alerte stock bas
- [ ] Desactivation auto si stock = 0
- [ ] Reapprovisionnement rapide

---

## Stack Technique

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  dio: ^5.4.0
  get_it: ^7.6.4
  injectable: ^2.3.2
  go_router: ^13.0.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
  audioplayers: ^5.2.1         # Sons notifications
  blue_thermal_printer: ^1.2.3 # Impression thermique
  fl_chart: ^0.66.0            # Graphiques
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  injectable_generator: ^2.4.1
  build_runner: ^2.4.7
  mockito: ^5.4.4
```

---

## Tests

```bash
# Tests unitaires
flutter test

# Tests d'integration
flutter test integration_test/
```

---

## Checklist Pre-Release

- [ ] Dashboard fonctionnel
- [ ] Gestion menu complete
- [ ] Reception commandes temps reel
- [ ] Notifications sonores
- [ ] Mode impression (optionnel)
- [ ] Tests unitaires
- [ ] Configuration production
- [ ] Assets et metadata store
