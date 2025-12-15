# Plan Lancement - MVP Tiassale

**Deploiement et Go-Live (M7)**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Ville pilote** | Tiassale, Cote d'Ivoire |
| **Population cible** | ~100,000 habitants |
| **Objectif MVP** | 5-10 restaurants, 10-20 livreurs |

---

## Prerequis

Avant de commencer M7, verifier que tous les plans sont completes:

- [ ] [Backend](01_BACKEND.md) - M1 a M5 termines
- [ ] [App Client](02_APP_CLIENT.md) - Toutes fonctionnalites P0
- [ ] [App Provider](03_APP_PROVIDER.md) - Dashboard + Commandes
- [ ] [App Driver](04_APP_DRIVER.md) - Courses + Navigation
- [ ] [Web Admin](05_WEB_ADMIN.md) - Gestion complete

---

## Phase 1: Preparation Technique (Semaine 16.1)

### 1.1 Tests End-to-End
- [ ] Scenario complet: inscription -> commande -> livraison -> paiement
- [ ] Test multi-utilisateurs simultanes
- [ ] Test de tous les modes de paiement
- [ ] Test des notifications
- [ ] Test du tracking GPS

### 1.2 Load Testing
- [ ] Configuration outils (k6, Locust)
- [ ] Test 100 utilisateurs simultanes
- [ ] Test 50 commandes/minute
- [ ] Identification goulots d'etranglement
- [ ] Optimisations necessaires

### 1.3 Security Audit
- [ ] Scan vulnerabilites (OWASP ZAP)
- [ ] Verification authentification
- [ ] Test injection SQL
- [ ] Test XSS
- [ ] Verification HTTPS
- [ ] Rate limiting en place

### 1.4 Backup Strategy
- [ ] Backup base de donnees (automatique, quotidien)
- [ ] Backup Redis
- [ ] Test de restoration
- [ ] Retention policy (30 jours)

### 1.5 Monitoring
- [ ] Logs centralises
- [ ] Alertes erreurs critiques
- [ ] Monitoring uptime
- [ ] Dashboard metriques

---

## Phase 2: Infrastructure Production (Semaine 16.2)

### 2.1 Serveur Production
- [ ] Provisioning serveur (VPS ou Cloud)
  - Recommande: 4 vCPU, 8GB RAM
  - Ubuntu 22.04 LTS
- [ ] Configuration firewall
- [ ] Configuration SSH securise
- [ ] Installation Docker

### 2.2 Configuration DNS
- [ ] Domaine principal: `nelo.ci` (ou equivalent)
- [ ] Sous-domaines:
  - `api.nelo.ci` - Backend API
  - `admin.nelo.ci` - Dashboard admin
- [ ] Configuration DNS records

### 2.3 SSL/TLS
- [ ] Installation Certbot
- [ ] Certificats Let's Encrypt
- [ ] Auto-renouvellement
- [ ] Verification HTTPS

### 2.4 Deploiement
- [ ] Docker Compose production
- [ ] Variables d'environnement production
- [ ] Deploiement API
- [ ] Deploiement Admin
- [ ] Verification health checks

---

## Phase 3: Publication Apps (Semaine 16.2-16.3)

### 3.1 Google Play Store
- [ ] Compte developpeur Google ($25)
- [ ] Preparation metadata:
  - Titre
  - Description courte/longue
  - Screenshots (min 2)
  - Icone (512x512)
  - Feature graphic (1024x500)
  - Categorie
- [ ] Build release signe
- [ ] Publication App Client
- [ ] Publication App Provider
- [ ] Publication App Driver
- [ ] Review Google (2-7 jours)

### 3.2 Apple App Store (optionnel MVP)
- [ ] Compte developpeur Apple ($99/an)
- [ ] Preparation metadata
- [ ] Build avec Xcode
- [ ] Soumission pour review
- [ ] Review Apple (1-3 jours)

---

## Phase 4: Onboarding Partenaires (Semaine 16.3)

### 4.1 Recrutement Restaurants
- [ ] Identifier 10-15 restaurants cibles
- [ ] Contact et presentation NELO
- [ ] Objectif: 5-10 restaurants signes
- [ ] Types prioritaires:
  - Restaurants locaux populaires
  - Fast-food
  - Grillades/Allocodrome
  - Boulangeries

### 4.2 Formation Prestataires
- [ ] Installation app Provider
- [ ] Configuration du compte
- [ ] Ajout menu/produits
- [ ] Configuration horaires
- [ ] Demo reception commande
- [ ] Support WhatsApp groupe

### 4.3 Recrutement Livreurs
- [ ] Annonces locales
- [ ] Criteres:
  - Moto en bon etat
  - Smartphone Android
  - Permis de conduire
  - Piece d'identite
- [ ] Objectif: 10-20 livreurs

### 4.4 Formation Livreurs
- [ ] Installation app Driver
- [ ] Soumission documents
- [ ] Validation compte
- [ ] Demo complete course
- [ ] Regles et procedures
- [ ] Support WhatsApp groupe

---

## Phase 5: Go-Live (Semaine 16.4)

### 5.1 Soft Launch (Beta)
- [ ] Ouverture limitee (50 premiers users)
- [ ] Monitoring intensif
- [ ] Feedback en temps reel
- [ ] Corrections bugs critiques
- [ ] Duree: 3-5 jours

### 5.2 Launch Public
- [ ] Annonce officielle
- [ ] Communication locale:
  - Reseaux sociaux
  - WhatsApp
  - Affiches chez partenaires
- [ ] Promotion lancement (ex: livraison gratuite)

### 5.3 Support Operationnel
- [ ] Equipe support disponible
- [ ] Numero WhatsApp support
- [ ] Process escalade
- [ ] Monitoring commandes en temps reel

---

## Checklists

### Technique
- [ ] Tous les tests passent
- [ ] Aucune vulnerabilite critique
- [ ] Backup automatique configure
- [ ] Monitoring et alertes actifs
- [ ] SSL/HTTPS configure
- [ ] Rate limiting en place
- [ ] Logs centralises

### Business
- [ ] CGU/CGV redigees
- [ ] Politique de confidentialite
- [ ] Contrats prestataires signes
- [ ] Contrats livreurs signes
- [ ] Compte Wave/Mobile Money configure
- [ ] Support client disponible

### Operationnel
- [ ] Equipe support formee
- [ ] Process gestion des incidents
- [ ] Canal WhatsApp support
- [ ] Numero support client actif
- [ ] Runbook procedures urgentes

---

## Metriques de Succes MVP

| Metrique | Objectif Semaine 1 | Objectif Mois 1 |
|----------|-------------------|-----------------|
| Telechargements | 100 | 500 |
| Utilisateurs actifs | 30 | 150 |
| Commandes | 20 | 200 |
| Prestataires actifs | 5 | 10 |
| Livreurs actifs | 10 | 20 |
| Note moyenne | > 4.0 | > 4.0 |

---

## Plan de Contingence

### Si bugs critiques
1. Rollback version precedente
2. Communication utilisateurs
3. Fix et re-deploiement

### Si manque de livreurs
1. Augmenter zone de recrutement
2. Bonus inscription
3. Livraison par prestataires (temporaire)

### Si peu de commandes
1. Promotions agressives
2. Communication renforcee
3. Partenariats locaux

---

## Post-Launch

### Semaine +1
- [ ] Analyse metriques
- [ ] Collecte feedback
- [ ] Priorisation bugs
- [ ] Planification ameliorations

### Mois +1
- [ ] Bilan MVP
- [ ] Decision extension zones
- [ ] Roadmap Phase 2
