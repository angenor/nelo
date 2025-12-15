# Plan Web Admin - web-admin

**Dashboard Administration Nuxt 4**

---

## Vue d'Ensemble

| Element | Detail |
|---------|--------|
| **Framework** | Nuxt 4 |
| **UI Framework** | Vue 3 Composition API |
| **State Management** | Pinia |
| **CSS** | Tailwind CSS |
| **Charts** | Chart.js / vue-chartjs |

---

## Prerequis Backend

| Fonctionnalite | Milestone Backend | Endpoints requis |
|----------------|-------------------|------------------|
| Auth Admin | M2 | `/auth/*` (role admin) |
| Users | M2 | `/admin/users/*` |
| Providers | M3 | `/admin/providers/*` |
| Orders | M4 | `/admin/orders/*` |
| Drivers | M4 | `/admin/drivers/*` |
| Finance | M5 | `/admin/transactions/*`, `/admin/payouts/*` |

---

## Structure du Projet

```
apps/web-admin/
├── app/
│   ├── components/
│   │   ├── ui/                 # Composants de base
│   │   │   ├── Button.vue
│   │   │   ├── Input.vue
│   │   │   ├── Modal.vue
│   │   │   ├── DataTable.vue
│   │   │   ├── Card.vue
│   │   │   └── Badge.vue
│   │   ├── layout/
│   │   │   ├── Sidebar.vue
│   │   │   ├── Header.vue
│   │   │   └── Footer.vue
│   │   └── charts/
│   │       ├── LineChart.vue
│   │       ├── BarChart.vue
│   │       └── PieChart.vue
│   │
│   ├── composables/
│   │   ├── useAuth.ts
│   │   ├── useApi.ts
│   │   └── useNotification.ts
│   │
│   ├── layouts/
│   │   ├── default.vue
│   │   └── auth.vue
│   │
│   ├── middleware/
│   │   └── auth.ts
│   │
│   ├── pages/
│   │   ├── index.vue           # Dashboard
│   │   ├── login.vue
│   │   ├── users/
│   │   ├── providers/
│   │   ├── drivers/
│   │   ├── orders/
│   │   ├── transactions/
│   │   ├── zones/
│   │   ├── promotions/
│   │   └── settings/
│   │
│   └── stores/
│       ├── auth.ts
│       ├── users.ts
│       ├── providers.ts
│       └── orders.ts
│
├── public/
├── server/
│   └── api/                    # API routes (proxy optionnel)
│
├── nuxt.config.ts
├── tailwind.config.js
└── package.json
```

---

## Pages et Fonctionnalites

### Phase 1: Setup + Auth (avec Backend M2)

#### 1.1 Setup Projet
- [ ] Creer le projet Nuxt 4
- [ ] Configurer Tailwind CSS
- [ ] Configurer Pinia
- [ ] Creer les composants UI de base
- [ ] Layout avec sidebar

#### 1.2 Authentification
- [ ] Page de login
- [ ] Gestion des sessions
- [ ] Middleware d'authentification
- [ ] Deconnexion

#### 1.3 Dashboard (base)
- [ ] Layout principal
- [ ] Sidebar navigation
- [ ] Header avec user info
- [ ] Placeholder KPIs

### Phase 2: Gestion Users + Providers (avec Backend M2/M3)

#### 2.1 Gestion Utilisateurs
- [ ] Liste des utilisateurs (DataTable)
  - Pagination
  - Recherche
  - Filtres (role, statut)
- [ ] Detail utilisateur
- [ ] Modification utilisateur
- [ ] Desactivation compte
- [ ] Export CSV

#### 2.2 Gestion Prestataires
- [ ] Liste des prestataires
  - Filtres (type, statut, zone)
- [ ] Detail prestataire
- [ ] Validation prestataire (pending -> approved)
- [ ] Modification informations
- [ ] Suspension prestataire
- [ ] Statistiques prestataire

### Phase 3: Gestion Orders + Drivers (avec Backend M4)

#### 3.1 Gestion Commandes
- [ ] Liste des commandes
  - Filtres (statut, date, prestataire)
  - Tri (date, montant)
- [ ] Detail commande
  - Timeline statuts
  - Informations client
  - Informations prestataire
  - Informations livreur
- [ ] Actions (annuler, rembourser)
- [ ] Vue temps reel (WebSocket)

#### 3.2 Gestion Livreurs
- [ ] Liste des livreurs
  - Filtres (statut, zone, vehicule)
- [ ] Detail livreur
  - Documents soumis
  - Historique courses
  - Note moyenne
- [ ] Validation livreur
  - Verification documents
  - Approbation / Rejet
- [ ] Suspension livreur

#### 3.3 Carte Temps Reel
- [ ] Carte avec livreurs en ligne
- [ ] Commandes en cours
- [ ] Zones de livraison

### Phase 4: Finance (avec Backend M5)

#### 4.1 Transactions
- [ ] Liste des transactions
  - Filtres (type, date, montant)
- [ ] Detail transaction
- [ ] Export comptable

#### 4.2 Versements (Payouts)
- [ ] Liste des versements en attente
- [ ] Validation versement
- [ ] Historique versements
- [ ] Export pour paiement

#### 4.3 Rapports Financiers
- [ ] Chiffre d'affaires
- [ ] Commissions collectees
- [ ] Graphiques evolution

### Phase 5: Configuration

#### 5.1 Zones de Livraison
- [ ] Liste des zones
- [ ] Creation zone (dessin sur carte)
- [ ] Tarification par zone
- [ ] Activation/Desactivation

#### 5.2 Promotions
- [ ] Liste des promotions
- [ ] Creation promotion
  - Code promo
  - Reduction (% ou fixe)
  - Conditions
  - Dates validite
- [ ] Statistiques utilisation

#### 5.3 Parametres Generaux
- [ ] Commissions par defaut
- [ ] Limites wallet
- [ ] Messages systeme
- [ ] Configuration SMS

---

## Dashboard KPIs

### Vue d'ensemble
- [ ] Commandes du jour
- [ ] Chiffre d'affaires du jour
- [ ] Nouveaux utilisateurs
- [ ] Livreurs en ligne

### Graphiques
- [ ] Evolution commandes (7 jours)
- [ ] Repartition par type de service
- [ ] Top prestataires
- [ ] Heatmap zones de livraison

---

## Composants Reutilisables

### DataTable
- [ ] Pagination
- [ ] Tri par colonne
- [ ] Recherche globale
- [ ] Filtres avances
- [ ] Selection multiple
- [ ] Actions bulk
- [ ] Export CSV

### Charts
- [ ] Line Chart (evolution)
- [ ] Bar Chart (comparaison)
- [ ] Pie Chart (repartition)
- [ ] Doughnut Chart

### Formulaires
- [ ] Input avec validation
- [ ] Select / Multiselect
- [ ] Date picker
- [ ] File upload
- [ ] Rich text editor (optionnel)

### Feedback
- [ ] Toast notifications
- [ ] Modal confirmation
- [ ] Loading states
- [ ] Empty states

---

## Stack Technique

```json
{
  "dependencies": {
    "nuxt": "^3.9.0",
    "@pinia/nuxt": "^0.5.1",
    "@nuxtjs/tailwindcss": "^6.10.0",
    "chart.js": "^4.4.1",
    "vue-chartjs": "^5.3.0",
    "@vueuse/core": "^10.7.0",
    "@headlessui/vue": "^1.7.16",
    "@heroicons/vue": "^2.1.1",
    "dayjs": "^1.11.10"
  },
  "devDependencies": {
    "typescript": "^5.3.3",
    "@nuxt/devtools": "^1.0.0"
  }
}
```

---

## API Integration

```typescript
// composables/useApi.ts
export const useApi = () => {
  const config = useRuntimeConfig()
  const auth = useAuthStore()

  const $fetch = $fetch.create({
    baseURL: config.public.apiBase,
    headers: {
      Authorization: `Bearer ${auth.token}`
    }
  })

  return { $fetch }
}
```

---

## Tests

```bash
# Tests unitaires
npm run test

# Tests E2E
npm run test:e2e
```

---

## Checklist Pre-Release

- [ ] Toutes les pages implementees
- [ ] Authentification securisee
- [ ] DataTables fonctionnels
- [ ] Charts avec donnees reelles
- [ ] Responsive design
- [ ] Tests unitaires
- [ ] Configuration production
- [ ] HTTPS configure
