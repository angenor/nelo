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

## Services MVP (Priorite)

| Service | Type Provider | Description |
|---------|---------------|-------------|
| 🍔 **Restauration** | `restaurant` | Commande de repas avec menu |
| ⛽ **Gaz** | `gas_depot` | Recharge/échange bouteilles |
| 🛒 **Courses** | `grocery` | Liste d'achats déléguée |
| 📦 **Colis Express** | - | Livraison point à point |

---

## Prerequis Backend

| Fonctionnalite | Milestone Backend | Endpoints requis |
|----------------|-------------------|------------------|
| Auth | M2 | `/auth/*`, `/users/*` |
| Catalogue | M3 | `/providers/*`, `/products/*`, `/gas-products/*` |
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
│           │
│           │   # Services specifiques
│           ├── restaurant/           # Flux restauration
│           │   ├── restaurant_list/
│           │   ├── restaurant_detail/
│           │   ├── product_detail/
│           │   └── cart/
│           │
│           ├── gas/                  # Flux gaz
│           │   ├── gas_order/        # Map + bottom sheet
│           │   └── gas_confirmation/
│           │
│           ├── errands/              # Flux courses
│           │   ├── errands_order/    # Map + liste courses
│           │   └── errands_confirmation/
│           │
│           ├── parcel/               # Flux colis express
│           │   ├── parcel_order/     # Map multi-points
│           │   └── parcel_confirmation/
│           │
│           ├── checkout/
│           ├── order_tracking/
│           ├── orders_history/
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
- [x] Logo anime
- [x] Verification de l'authentification
- [x] Redirection appropriee

#### 1.3 Onboarding
- [x] 3-4 slides de presentation
- [x] Bouton "Commencer"
- [x] Stockage local du premier lancement

#### 1.4 Authentification
- [x] Ecran de connexion (telephone)
- [x] Ecran d'inscription
- [x] Ecran de verification OTP
- [x] Gestion des tokens (stockage securise)
- [x] Auto-refresh des tokens

### Phase 2: Home + Navigation (avec Backend M3)

#### 2.1 Home Screen
- [x] Header avec localisation actuelle
- [x] Barre de recherche
- [x] Categories de services (4 icones principales)
  - 🍔 Restaurants
  - ⛽ Gaz
  - 🛒 Courses
  - 📦 Colis
- [x] Section promotions (carousel)
- [x] Section "Restaurants populaires"
- [x] Section "Pres de vous"
- [x] Bottom navigation bar

#### 2.2 Recherche Globale
- [x] Barre de recherche avec suggestions
- [x] Filtres (categorie, distance, note, prix)
- [x] Liste des resultats
- [x] Vue carte (Google Maps)
- [ ] Infinite scroll

---

### Phase 3: Service RESTAURATION 🍔

> Flux classique : catalogue → panier → checkout

#### 3.1 Liste Restaurants
- [x] Liste des restaurants (`orders.providers` WHERE type='restaurant')
- [x] Filtres (cuisine, note, temps de preparation)
- [x] Tri (distance, popularite, note)
- [x] Indicateur ouvert/ferme (`is_open`)

#### 3.2 Detail Restaurant
- [x] Header (cover_image_url, logo_url, name, average_rating)
- [x] Infos (horaires via `provider_schedules`, adresse, telephone)
- [x] Menu par categories (`product_categories`)
- [x] Liste produits avec prix (`products`)
- [x] Bouton panier flottant avec total

#### 3.3 Detail Produit
- [ ] Image, nom, description
- [ ] Options/Variations (`product_options`, `product_option_items`)
- [ ] Prix avec ajustements
- [ ] Selecteur quantite
- [ ] Bouton ajouter au panier

#### 3.4 Panier Restaurant
- [ ] Liste articles avec options selectionnees
- [ ] Modification quantite / suppression
- [ ] Sous-total, frais livraison, total
- [ ] Champ instructions speciales
- [ ] Bouton "Commander"

---

### Phase 4: Service GAZ ⛽

> Flux simplifie : 1 ecran avec carte + bottom sheet
> **UX priorite** : Minimum de clics, selection automatique du depot proche

#### 4.1 Ecran Commande Gaz (`gas_order_screen`)

**Layout : Google Map plein ecran + DraggableScrollableSheet**

```
┌─────────────────────────────────────────┐
│                                         │
│            GOOGLE MAP                   │
│   [Markers: depots gaz proches]         │
│   [Marker: ma position]                 │
│   [Marker: depot selectionne ✓]         │
│                                         │
├─────────────────────────────────────────┤
│ ══════════════ (drag handle) ══════════ │
│                                         │
│  📍 Livrer a: [Adresse actuelle    ▼]  │
│     (dropdown adresses favorites)       │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  ⛽ Type de bouteille:                  │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │  6 kg  │ │ 12 kg  │ │ 38 kg  │      │
│  │ petite │ │moyenne │ │ grande │      │
│  └────────┘ └────────┘ └────────┘      │
│                                         │
│  🏷️ Marque: (auto selon depot)         │
│  [Total] [Shell] [Oryx] [Autre]        │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  🔄 Type de commande:                   │
│  ┌───────────────┐ ┌───────────────┐   │
│  │   RECHARGE    │ │   ECHANGE     │   │
│  │  (ma bouteille)│ │ (bouteille   │   │
│  │               │ │   vide)       │   │
│  └───────────────┘ └───────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  💰 Prix: 5,500 FCFA                    │
│  🏪 Depot: Gaz Express (1.2 km)         │
│  🚴 Livreur: Auto-assigne               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      COMMANDER MAINTENANT       │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Fonctionnalites:**
- [ ] Carte avec depots gaz (`providers` WHERE type='gas_depot')
- [ ] Detection position actuelle (geolocalisation)
- [ ] Selection automatique du depot le plus proche
- [ ] Possibilite de changer de depot en cliquant sur la carte
- [ ] Bottom sheet draggable (collapsed/expanded)
- [ ] Selection adresse livraison (dropdown adresses favorites)
- [ ] Selection taille bouteille (`gas_products.bottle_size`)
- [ ] Selection marque si plusieurs disponibles (`gas_products.brand`)
- [ ] Toggle Recharge/Echange (`refill_price` vs `exchange_price`)
- [ ] Affichage prix dynamique
- [ ] Affichage stock disponible (`quantity_available`)
- [ ] Bouton commander

**Donnees schema.sql:**
```sql
orders.gas_products: brand, bottle_size, refill_price, exchange_price, quantity_available
orders.providers: type='gas_depot', location, is_open
```

#### 4.2 Confirmation Gaz
- [ ] Resume commande (type, taille, prix)
- [ ] Adresse de livraison
- [ ] Mode de paiement
- [ ] Estimation temps livraison
- [ ] Bouton confirmer

---

### Phase 5: Service COURSES 🛒

> Flux simplifie : carte + liste de courses + note vocale optionnelle
> **UX priorite** : Interface epuree, note vocale pour non-lecteurs

#### 5.1 Ecran Commande Courses (`errands_order_screen`)

**Layout : Google Map (haut) + Formulaire (bas)**

```
┌─────────────────────────────────────────┐
│                                         │
│            GOOGLE MAP                   │
│   [Marker: lieu de livraison]           │
│   [Marker: lieu des courses (optionnel)]│
│                                         │
├─────────────────────────────────────────┤
│ ══════════════ (drag handle) ══════════ │
│                                         │
│  📍 Livrer a: [Mon adresse        ▼]   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  📝 Ma liste de courses:                │
│  ┌─────────────────────────────────┐   │
│  │ • 2 kg de riz                   │   │
│  │ • 1 poulet                      │   │
│  │ • Tomates, oignons              │   │
│  │ • ...                           │   │
│  │                                 │   │
│  │ [Ajouter un article...]         │   │
│  └─────────────────────────────────┘   │
│                                         │
│  🎤 Ou enregistrer une note vocale:     │
│  ┌─────────────────────────────────┐   │
│  │  [●] Appuyer pour enregistrer   │   │
│  │      (max 2 min)                │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  📍 Ou faire les courses? (optionnel)   │
│  [ Marche central, supermarche... ]    │
│  (petit champ discret, non obligatoire) │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  💰 Budget estime: [______] FCFA        │
│  (le coursier vous appellera si depasse)│
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      ENVOYER MA COMMANDE        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Fonctionnalites:**
- [ ] Carte avec adresse de livraison
- [ ] Selection adresse (dropdown ou recherche)
- [ ] Zone de texte pour liste de courses
- [ ] Ajout article un par un (simple)
- [ ] Enregistrement note vocale (audio_url)
- [ ] Champ optionnel discret : lieu des courses
- [ ] Champ budget estime
- [ ] Bouton envoyer

**Stockage commande:**
```sql
orders.orders: service_type='errands', special_instructions (JSON avec liste)
-- Note vocale: stockee en Object Storage, URL dans special_instructions
```

#### 5.2 Confirmation Courses
- [ ] Resume liste / lecture note vocale
- [ ] Adresse livraison
- [ ] Budget estime
- [ ] Mode de paiement (souvent cash a la livraison)
- [ ] Note: le coursier appellera pour confirmer les prix

---

### Phase 6: Service COLIS EXPRESS 📦

> Flux : carte multi-points + details colis + note
> **UX priorite** : Visuel clair des trajets, plusieurs destinations possibles

#### 6.1 Ecran Commande Colis (`parcel_order_screen`)

**Layout : Google Map avec tracé + Bottom sheet**

```
┌─────────────────────────────────────────┐
│                                         │
│            GOOGLE MAP                   │
│                                         │
│   [A] ●───────────────● [B1]           │
│             │                           │
│             └────────● [B2]             │
│                                         │
│   Legende:                              │
│   [A] = Recuperation                    │
│   [B] = Livraison(s)                    │
│                                         │
├─────────────────────────────────────────┤
│ ══════════════ (drag handle) ══════════ │
│                                         │
│  📍 RECUPERATION:                       │
│  ┌─────────────────────────────────┐   │
│  │ [Entrer l'adresse...]           │   │
│  │ ou 📍 Utiliser ma position      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  📍 LIVRAISON(S):                       │
│  ┌─────────────────────────────────┐   │
│  │ 1. [Adresse destination 1]  [×] │   │
│  │ 2. [Adresse destination 2]  [×] │   │
│  │                                 │   │
│  │ [+ Ajouter une destination]     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  📝 Description du colis:               │
│  ┌─────────────────────────────────┐   │
│  │ Ex: Enveloppe, petit carton...  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  🎤 Ou note vocale:                     │
│  ┌─────────────────────────────────┐   │
│  │  [●] Appuyer pour enregistrer   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  💰 Estimation: 1,500 FCFA              │
│  📏 Distance: 3.2 km                    │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      DEMANDER UN LIVREUR        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Fonctionnalites:**
- [ ] Carte avec tracé du parcours (polyline)
- [ ] Champ adresse de recuperation
- [ ] Bouton "Utiliser ma position"
- [ ] Liste destinations (ajout/suppression dynamique)
- [ ] Mise a jour carte en temps reel
- [ ] Description colis (texte)
- [ ] Note vocale alternative
- [ ] Calcul distance et prix automatique
- [ ] Bouton commander

**Stockage commande:**
```sql
orders.orders: service_type='parcel'
-- Multi-destinations: delivery_address_snapshot contient un array
-- Pickup: dans special_instructions ou champ dedie
```

#### 6.2 Confirmation Colis
- [ ] Carte avec trajet complet
- [ ] Points A → B1 → B2...
- [ ] Description / ecoute note vocale
- [ ] Prix total
- [ ] Mode de paiement
- [ ] Bouton confirmer

---

### Phase 7: Checkout Unifie + Paiements

#### 7.1 Checkout (commun a tous les services)
- [ ] Resume commande (adapte au service)
- [ ] Adresse de livraison
- [ ] Estimation temps de livraison
- [ ] Selection mode de paiement:
  - Portefeuille NELO
  - Mobile Money (Wave, Orange, MTN)
  - Cash a la livraison
- [ ] Application code promo
- [ ] Total final
- [ ] Bouton confirmer

#### 7.2 Suivi Commande (commun)
- [ ] Timeline du statut (`order_status_history`)
- [ ] Carte avec position livreur (temps reel)
- [ ] Infos livreur (photo, nom, vehicule)
- [ ] Boutons appel / message
- [ ] ETA dynamique
- [ ] Code de confirmation livraison

#### 7.3 Historique Commandes
- [ ] Liste commandes avec icone service (🍔⛽🛒📦)
- [ ] Filtres par service, statut, date
- [ ] Detail commande
- [ ] Bouton "Commander a nouveau" (si applicable)

#### 7.4 Portefeuille
- [ ] Solde actuel (`payments.wallets.balance`)
- [ ] Historique transactions (`payments.transactions`)
- [ ] Bouton recharger

#### 7.5 Recharge Portefeuille
- [ ] Montants pre-definis (1000, 2000, 5000, 10000)
- [ ] Montant personnalise
- [ ] Selection methode (Wave, Orange Money, MTN)
- [ ] Redirection vers paiement
- [ ] Confirmation

---

### Phase 8: Profil et Parametres

#### 8.1 Profil Utilisateur
- [ ] Avatar (upload/modification)
- [ ] Informations (`users.profiles`: first_name, last_name, phone, email)
- [ ] Code de parrainage (`referral_code`)
- [ ] Deconnexion

#### 8.2 Adresses Favorites
- [ ] Liste des adresses (`users.addresses`)
- [ ] Ajout nouvelle adresse (recherche ou carte)
- [ ] Labels (Maison, Bureau, Autre)
- [ ] Adresse par defaut
- [ ] Modification/Suppression

#### 8.3 Parametres
- [ ] Notifications (push, sms)
- [ ] Langue (fr/en)
- [ ] A propos
- [ ] CGU / Politique de confidentialite

---

## Fonctionnalites Transverses

### Geolocalisation
- [ ] Permission de localisation
- [ ] Obtention position actuelle
- [ ] Geocoding inverse (coordonnees -> adresse)
- [ ] Geocoding direct (adresse -> coordonnees)
- [ ] Selection sur carte (tap to select)
- [ ] Calcul distance entre points
- [ ] Tracé de parcours (polyline)

### Enregistrement Vocal
> Important pour l'accessibilite (utilisateurs non-lecteurs)
- [ ] Permission microphone
- [ ] Enregistrement audio (max 2 min)
- [ ] Lecture audio
- [ ] Upload vers Object Storage
- [ ] Affichage waveform (optionnel)

### Notifications Push
- [ ] Configuration Firebase Messaging
- [ ] Gestion des tokens FCM (`notifications.push_tokens`)
- [ ] Reception notifications foreground/background
- [ ] Navigation depuis notification
- [ ] Notifications silencieuses (mise a jour position livreur)

### Gestion Erreurs
- [ ] Ecrans d'erreur generiques
- [ ] Mode hors-ligne (message)
- [ ] Retry automatique
- [ ] Pull-to-refresh

### Accessibilite (UX simplifie)
- [ ] Boutons larges (min 48x48)
- [ ] Textes lisibles (16sp minimum)
- [ ] Icones explicites avec labels
- [ ] Feedback visuel et haptique
- [ ] Messages d'erreur clairs et simples

---

## Stack Technique

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Navigation
  go_router: ^13.0.0

  # Network
  dio: ^5.4.0

  # DI
  get_it: ^7.6.4
  injectable: ^2.3.2

  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.0
  flutter_polyline_points: ^2.0.0

  # Audio (notes vocales)
  record: ^5.0.0                    # Enregistrement
  audioplayers: ^5.2.0             # Lecture

  # Firebase
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  firebase_storage: ^11.5.0        # Upload audio

  # Notifications
  flutter_local_notifications: ^16.3.0

  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0

  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0

  # Utils
  intl: ^0.18.1
  dartz: ^0.10.1
  permission_handler: ^11.0.0

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

## Checklist Pre-Release MVP

### Services
- [ ] 🍔 Restauration : flux complet (liste → detail → panier → checkout → suivi)
- [ ] ⛽ Gaz : flux simplifie (carte + bottom sheet → confirmation → suivi)
- [ ] 🛒 Courses : flux simplifie (carte + liste/vocal → confirmation → suivi)
- [ ] 📦 Colis : flux multi-points (carte → confirmation → suivi)

### Core
- [ ] Authentification complete (OTP, tokens)
- [ ] Geolocalisation fonctionnelle
- [ ] Enregistrement vocal operationnel
- [ ] Paiements (Wallet, Mobile Money, Cash)
- [ ] Suivi temps reel (WebSocket)
- [ ] Notifications push

### Qualite
- [ ] Gestion des erreurs complete
- [ ] Tests unitaires (>70% coverage)
- [ ] Tests d'integration par service
- [ ] Tests sur appareils reels (Android + iOS)
- [ ] Performance optimisee (cold start < 3s)

### Production
- [ ] Configuration production (API URL, Firebase, Maps API)
- [ ] Icone et splash screen
- [ ] Assets optimises
- [ ] Metadata store (screenshots, description FR/EN)
- [ ] Privacy policy et CGU
