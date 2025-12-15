# Plan App Driver - mobile-driver

**Application Flutter pour les Livreurs**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Framework** | Flutter |
| **Architecture** | Clean Architecture + BLoC |
| **Utilisateurs** | Livreurs independants |

---

## Prerequis Backend

| Fonctionnalite | Milestone Backend | Endpoints requis |
|----------------|-------------------|------------------|
| Auth | M2 | `/auth/*`, `/users/*` |
| Inscription livreur | M4 | `/drivers/register` |
| Courses | M4 | `/drivers/*`, `/deliveries/*` |
| Gains | M5 | `/wallet/*`, `/payouts/*` |

---

## Structure du Projet

```
apps/mobile-driver/
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
│           ├── registration/
│           ├── home/
│           ├── offers/
│           ├── active_delivery/
│           ├── history/
│           ├── earnings/
│           ├── documents/
│           └── profile/
│
├── assets/
├── test/
└── pubspec.yaml
```

---

## Ecrans et Fonctionnalites

### Phase 1: Auth + Inscription (avec Backend M2/M4)

#### 1.1 Setup Projet
- [ ] Creer le projet Flutter
- [ ] Configurer la structure Clean Architecture
- [ ] Theme adapte aux livreurs

#### 1.2 Authentification
- [ ] Connexion livreur
- [ ] Verification OTP

#### 1.3 Inscription Livreur
- [ ] Etape 1: Informations personnelles
  - Nom, prenom
  - Telephone (deja verifie)
  - Photo de profil
- [ ] Etape 2: Vehicule
  - Type (moto, velo, voiture)
  - Marque, modele
  - Immatriculation
  - Photo vehicule
- [ ] Etape 3: Documents
  - Piece d'identite
  - Permis de conduire
  - Carte grise
- [ ] Etape 4: Compte bancaire
  - Mobile Money (Wave, Orange Money)
- [ ] Statut: En attente de validation

### Phase 2: Home + Courses (avec Backend M4)

#### 2.1 Home Screen
- [ ] Toggle Online/Offline
- [ ] Statistiques du jour
  - Courses effectuees
  - Gains du jour
  - Note moyenne
- [ ] Carte avec position actuelle
- [ ] Indicateur de zone (dans/hors zone)

#### 2.2 Offres de Courses
- [ ] Liste des offres disponibles
- [ ] Detail offre
  - Distance pickup
  - Distance livraison
  - Estimation gain
  - Temps estime
- [ ] Timer pour accepter
- [ ] Boutons Accepter / Refuser
- [ ] Notification sonore nouvelle offre

#### 2.3 Course en Cours

**Etape 1: Vers le restaurant**
- [ ] Navigation vers le point de collecte
- [ ] Informations restaurant
- [ ] Bouton "Arrive au restaurant"

**Etape 2: Collecte**
- [ ] Detail de la commande
- [ ] Verification articles
- [ ] Bouton "Commande recuperee"

**Etape 3: Vers le client**
- [ ] Navigation vers l'adresse de livraison
- [ ] Informations client
- [ ] Bouton appeler client

**Etape 4: Livraison**
- [ ] Confirmation livraison
- [ ] Collecte paiement cash (si applicable)
- [ ] Photo de preuve (optionnel)
- [ ] Bouton "Livraison terminee"

#### 2.4 Historique Courses
- [ ] Liste des courses effectuees
- [ ] Filtres (date, statut)
- [ ] Detail course
- [ ] Note recue

### Phase 3: Gains (avec Backend M5)

#### 3.1 Ecran Gains
- [ ] Gains du jour
- [ ] Gains de la semaine
- [ ] Gains du mois
- [ ] Graphique evolution

#### 3.2 Detail Gains
- [ ] Liste des gains par course
- [ ] Commissions prelevees
- [ ] Pourboires recus

#### 3.3 Versements
- [ ] Solde disponible
- [ ] Historique versements
- [ ] Prochain versement

### Phase 4: Profil + Documents

#### 4.1 Profil
- [ ] Informations personnelles
- [ ] Photo de profil
- [ ] Vehicule actuel
- [ ] Note moyenne

#### 4.2 Documents
- [ ] Liste des documents soumis
- [ ] Statut de chaque document
- [ ] Mise a jour document expire
- [ ] Upload nouveau document

#### 4.3 Parametres
- [ ] Notifications
- [ ] Mode navigation prefere
- [ ] Zone de travail preferee
- [ ] Deconnexion

---

## Fonctionnalites Critiques

### Tracking GPS Background
- [ ] Service de localisation en arriere-plan
- [ ] Envoi position au serveur (toutes les 10s)
- [ ] Optimisation batterie
- [ ] Gestion permission "toujours"

### Navigation Integree
- [ ] Integration Google Maps
- [ ] Navigation turn-by-turn
- [ ] Estimation temps de trajet
- [ ] Alternatives en cas de trafic

### Notifications
- [ ] Notification nouvelle offre (sonore + vibration)
- [ ] Notification course assignee
- [ ] Rappel si offline depuis longtemps

### Mode Hors-ligne
- [ ] Cache des courses en cours
- [ ] Mise a jour statut des que connecte
- [ ] Indication mode offline

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
  flutter_polyline_points: ^2.0.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
  audioplayers: ^5.2.1
  workmanager: ^0.5.2          # Background tasks
  flutter_background_service: ^5.0.5
  url_launcher: ^6.2.2         # Appels tel
  fl_chart: ^0.66.0
  image_picker: ^1.0.7
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  injectable_generator: ^2.4.1
  build_runner: ^2.4.7
  mockito: ^5.4.4
```

---

## Permissions Requises

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.CALL_PHONE" />
```

### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<key>NSLocationAlwaysUsageDescription</key>
<key>NSCameraUsageDescription</key>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
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

- [ ] Toggle online/offline fonctionnel
- [ ] Reception offres temps reel
- [ ] Navigation complete
- [ ] Tracking GPS background
- [ ] Gestion gains
- [ ] Upload documents
- [ ] Tests unitaires
- [ ] Optimisation batterie testee
- [ ] Configuration production
- [ ] Assets et metadata store
