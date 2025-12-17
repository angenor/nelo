# Plan App Client - mobile-client

**Application Flutter pour les Consommateurs**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Framework** | Flutter |
| **Architecture** | Clean Architecture + BLoC |
| **State Management** | flutter_bloc |
| **Navigation** | go_router |
| **API Client** | dio |

---

## Prerequis Backend

| Fonctionnalite | Milestone Backend | Endpoints requis |
|----------------|-------------------|------------------|
| Auth | M2 | `/auth/*`, `/users/*` |
| Catalogue | M3 | `/providers/*`, `/products/*` |
| Commandes | M4 | `/orders/*` |
| Paiements | M5 | `/wallet/*` |

---

## Structure du Projet

```
apps/mobile-client/
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
│   │   └── widgets/              # Widgets reutilisables
│   │
│   ├── data/
│   │   ├── datasources/          # API calls
│   │   ├── models/               # DTOs
│   │   └── repositories/         # Implementations
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/         # Interfaces
│   │   └── usecases/
│   │
│   └── presentation/
│       ├── blocs/
│       └── screens/
│           ├── splash/
│           ├── onboarding/
│           ├── auth/
│           ├── home/
│           ├── search/
│           ├── provider_detail/
│           ├── cart/
│           ├── checkout/
│           ├── order_tracking/
│           ├── profile/
│           ├── addresses/
│           └── wallet/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── test/
└── pubspec.yaml
```

---

## Ecrans et Fonctionnalites

### Phase 1: Setup + Auth (avec Backend M2)

#### 1.1 Setup Projet
- [x] Creer le projet Flutter
- [x] Configurer la structure Clean Architecture
- [x] Configurer l'injection de dependances (get_it + injectable)
- [x] Configurer le theme (couleurs, typographie)
- [x] Creer les widgets de base (boutons, inputs, cards)

#### 1.2 Splash Screen
- [ ] Logo anime
- [ ] Verification de l'authentification
- [ ] Redirection appropriee

#### 1.3 Onboarding
- [ ] 3-4 slides de presentation
- [ ] Bouton "Commencer"
- [ ] Stockage local du premier lancement

#### 1.4 Authentification
- [ ] Ecran de connexion (telephone)
- [ ] Ecran d'inscription
- [ ] Ecran de verification OTP
- [ ] Gestion des tokens (stockage securise)
- [ ] Auto-refresh des tokens

### Phase 2: Home + Catalogue (avec Backend M3)

#### 2.1 Home Screen
- [ ] Header avec localisation actuelle
- [ ] Barre de recherche
- [ ] Categories de services (icones)
- [ ] Section promotions (carousel)
- [ ] Section "Restaurants populaires"
- [ ] Section "Pres de vous"
- [ ] Bottom navigation bar

#### 2.2 Recherche
- [ ] Barre de recherche avec suggestions
- [ ] Filtres (categorie, distance, note, prix)
- [ ] Liste des resultats
- [ ] Vue carte (Google Maps)
- [ ] Infinite scroll

#### 2.3 Detail Prestataire
- [ ] Header avec image, nom, note
- [ ] Informations (horaires, adresse, telephone)
- [ ] Menu par categories (tabs)
- [ ] Liste des produits
- [ ] Bouton panier flottant

#### 2.4 Detail Produit
- [ ] Image produit
- [ ] Description
- [ ] Options/Variations
- [ ] Selecteur quantite
- [ ] Bouton ajouter au panier

### Phase 3: Commandes (avec Backend M4)

#### 3.1 Panier
- [ ] Liste des articles
- [ ] Modification quantite
- [ ] Suppression article
- [ ] Sous-total par article
- [ ] Total commande
- [ ] Bouton commander

#### 3.2 Checkout
- [ ] Selection adresse de livraison
- [ ] Estimation temps de livraison
- [ ] Selection mode de paiement
- [ ] Application code promo
- [ ] Resume commande
- [ ] Confirmation et paiement

#### 3.3 Suivi Commande
- [ ] Timeline du statut
- [ ] Informations livreur (si assigne)
- [ ] Carte avec position livreur
- [ ] Bouton appel/message livreur
- [ ] Estimation temps restant

#### 3.4 Historique Commandes
- [ ] Liste des commandes passees
- [ ] Filtres (statut, date)
- [ ] Detail commande
- [ ] Bouton "Commander a nouveau"

### Phase 4: Paiements (avec Backend M5)

#### 4.1 Portefeuille
- [ ] Solde actuel
- [ ] Historique transactions
- [ ] Bouton recharger

#### 4.2 Recharge
- [ ] Saisie montant
- [ ] Selection methode (Wave, CinetPay)
- [ ] Redirection vers paiement
- [ ] Confirmation

### Phase 5: Profil

#### 5.1 Profil Utilisateur
- [ ] Avatar (upload/modification)
- [ ] Informations personnelles
- [ ] Modification mot de passe
- [ ] Deconnexion

#### 5.2 Adresses
- [ ] Liste des adresses
- [ ] Ajout nouvelle adresse
- [ ] Selection sur carte
- [ ] Modification/Suppression

#### 5.3 Parametres
- [ ] Notifications
- [ ] Langue
- [ ] A propos
- [ ] CGU / Politique de confidentialite

---

## Fonctionnalites Transverses

### Geolocalisation
- [ ] Permission de localisation
- [ ] Obtention position actuelle
- [ ] Geocoding inverse (coordonnees -> adresse)
- [ ] Selection sur carte

### Notifications Push
- [ ] Configuration Firebase Messaging
- [ ] Gestion des tokens FCM
- [ ] Reception notifications foreground/background
- [ ] Navigation depuis notification

### Gestion Erreurs
- [ ] Ecrans d'erreur generiques
- [ ] Mode hors-ligne (message)
- [ ] Retry automatique
- [ ] Pull-to-refresh

---

## Stack Technique

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  dio: ^5.4.0
  get_it: ^7.6.4
  injectable: ^2.3.2
  go_router: ^13.0.0
  geolocator: ^10.1.0
  google_maps_flutter: ^2.5.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.18.1
  equatable: ^2.0.5
  dartz: ^0.10.1

dev_dependencies:
  injectable_generator: ^2.4.1
  build_runner: ^2.4.7
  mockito: ^5.4.4
  bloc_test: ^9.1.5
```

---

## Tests

```bash
# Tests unitaires
flutter test

# Tests avec couverture
flutter test --coverage

# Tests d'integration
flutter test integration_test/
```

---

## Checklist Pre-Release

- [ ] Tous les ecrans implementes
- [ ] Gestion des erreurs complete
- [ ] Tests unitaires (>70% coverage)
- [ ] Tests d'integration
- [ ] Performance optimisee
- [ ] Assets optimises
- [ ] Configuration production (API URL, Firebase)
- [ ] Icone et splash screen
- [ ] Metadata store (screenshots, description)
