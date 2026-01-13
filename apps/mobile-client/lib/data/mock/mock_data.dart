import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';

/// Mock data for development without backend
class MockData {
  MockData._();

  /// MVP Services - 4 main services on home screen
  static const List<ServiceCategory> services = [
    ServiceCategory(
      id: 'srv-restaurant',
      name: 'Restaurants',
      type: ServiceType.restaurant,
      icon: Icons.restaurant,
      color: Color(0xFFFF6B35),
      routePath: '/restaurants',
      description: 'Commander vos repas',
    ),
    ServiceCategory(
      id: 'srv-gas',
      name: 'Gaz',
      type: ServiceType.gas,
      icon: Icons.local_fire_department,
      color: Color(0xFFFF9500),
      routePath: '/gas',
      description: 'Recharge ou echange de bouteilles',
    ),
    ServiceCategory(
      id: 'srv-errands',
      name: 'Courses',
      type: ServiceType.errands,
      icon: Icons.shopping_basket,
      color: Color(0xFF34C759),
      routePath: '/errands',
      description: 'Faites faire vos courses',
    ),
    ServiceCategory(
      id: 'srv-parcel',
      name: 'Colis',
      type: ServiceType.parcel,
      icon: Icons.local_shipping,
      color: Color(0xFF007AFF),
      routePath: '/parcel',
      description: 'Envoyez vos colis',
    ),
  ];

  /// Provider categories (for search/filter)
  static const List<ProviderCategory> categories = [
    ProviderCategory(
      id: '1',
      name: 'Restaurants',
      slug: 'restaurants',
      providerType: ProviderType.restaurant,
      displayOrder: 1,
    ),
    ProviderCategory(
      id: '2',
      name: 'Gaz',
      slug: 'gaz',
      providerType: ProviderType.gasDepot,
      displayOrder: 2,
    ),
    ProviderCategory(
      id: '3',
      name: 'Epiceries',
      slug: 'epiceries',
      providerType: ProviderType.grocery,
      displayOrder: 3,
    ),
    ProviderCategory(
      id: '4',
      name: 'Pharmacies',
      slug: 'pharmacies',
      providerType: ProviderType.pharmacy,
      displayOrder: 4,
    ),
    ProviderCategory(
      id: '5',
      name: 'Pressing',
      slug: 'pressing',
      providerType: ProviderType.pressing,
      displayOrder: 5,
    ),
    ProviderCategory(
      id: '6',
      name: 'Artisans',
      slug: 'artisans',
      providerType: ProviderType.artisan,
      displayOrder: 6,
    ),
  ];

  /// Popular restaurants
  static const List<Provider> popularProviders = [
    Provider(
      id: 'p1',
      name: 'Chez Tantine Marie',
      slug: 'chez-tantine-marie',
      description: 'Cuisine africaine traditionnelle',
      type: ProviderType.restaurant,
      cuisineType: CuisineType.african,
      phone: '0707000001',
      addressLine1: 'Quartier Commerce, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8983,
      longitude: -4.8228,
      logoUrl: 'https://i.pravatar.cc/150?u=r1',
      coverImageUrl: 'https://picsum.photos/seed/r1/400/200',
      averageRating: 4.5,
      ratingCount: 127,
      totalOrders: 523,
      isOpen: true,
      isFeatured: true,
      averagePrepTime: 25,
      minOrderAmount: 1500,
      distanceKm: 0.8,
    ),
    Provider(
      id: 'p2',
      name: 'Le Maquis du Port',
      slug: 'le-maquis-du-port',
      description: 'Poissons braisés et attiéké',
      type: ProviderType.restaurant,
      cuisineType: CuisineType.seafood,
      phone: '0707000002',
      addressLine1: 'Près du port, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8990,
      longitude: -4.8235,
      logoUrl: 'https://i.pravatar.cc/150?u=r2',
      coverImageUrl: 'https://picsum.photos/seed/r2/400/200',
      averageRating: 4.8,
      ratingCount: 89,
      totalOrders: 342,
      isOpen: true,
      isFeatured: true,
      averagePrepTime: 30,
      minOrderAmount: 2000,
      distanceKm: 1.2,
    ),
    Provider(
      id: 'p3',
      name: 'Fast Food Abi',
      slug: 'fast-food-abi',
      description: 'Hamburgers, shawarmas, pizzas',
      type: ProviderType.restaurant,
      cuisineType: CuisineType.fastFood,
      phone: '0707000003',
      addressLine1: 'Centre-ville, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8975,
      longitude: -4.8220,
      logoUrl: 'https://i.pravatar.cc/150?u=r3',
      coverImageUrl: 'https://picsum.photos/seed/r3/400/200',
      averageRating: 4.2,
      ratingCount: 156,
      totalOrders: 678,
      isOpen: false,
      isFeatured: false,
      averagePrepTime: 20,
      minOrderAmount: 1000,
      distanceKm: 0.5,
    ),
    Provider(
      id: 'p4',
      name: 'Restaurant Le Palmier',
      slug: 'restaurant-le-palmier',
      description: 'Cuisine ivoirienne et européenne',
      type: ProviderType.restaurant,
      cuisineType: CuisineType.ivorian,
      phone: '0707000004',
      addressLine1: 'Route de Divo, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.9000,
      longitude: -4.8250,
      logoUrl: 'https://i.pravatar.cc/150?u=r4',
      coverImageUrl: 'https://picsum.photos/seed/r4/400/200',
      averageRating: 4.6,
      ratingCount: 72,
      totalOrders: 215,
      isOpen: true,
      isFeatured: true,
      averagePrepTime: 35,
      minOrderAmount: 2500,
      distanceKm: 1.8,
    ),
  ];

  /// Nearby providers (all types)
  static const List<Provider> nearbyProviders = [
    Provider(
      id: 'n1',
      name: 'Dépôt Gaz Yao',
      slug: 'depot-gaz-yao',
      description: 'Bouteilles de gaz toutes tailles',
      type: ProviderType.gasDepot,
      phone: '0707000010',
      addressLine1: 'Quartier Résidentiel, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8980,
      longitude: -4.8225,
      logoUrl: 'https://i.pravatar.cc/150?u=g1',
      averageRating: 4.7,
      ratingCount: 45,
      isOpen: true,
      distanceKm: 0.3,
    ),
    Provider(
      id: 'n2',
      name: 'Pharmacie du Marché',
      slug: 'pharmacie-du-marche',
      description: 'Médicaments et produits de santé',
      type: ProviderType.pharmacy,
      phone: '0707000011',
      addressLine1: 'Marché central, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8985,
      longitude: -4.8230,
      logoUrl: 'https://i.pravatar.cc/150?u=ph1',
      averageRating: 4.9,
      ratingCount: 67,
      isOpen: true,
      distanceKm: 0.6,
    ),
    Provider(
      id: 'n3',
      name: 'Épicerie Chez Konan',
      slug: 'epicerie-chez-konan',
      description: 'Produits alimentaires et ménagers',
      type: ProviderType.grocery,
      phone: '0707000012',
      addressLine1: 'Quartier Commerce, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8978,
      longitude: -4.8222,
      logoUrl: 'https://i.pravatar.cc/150?u=e1',
      averageRating: 4.3,
      ratingCount: 34,
      isOpen: true,
      distanceKm: 0.4,
    ),
    Provider(
      id: 'n4',
      name: 'Pressing Moderne',
      slug: 'pressing-moderne',
      description: 'Nettoyage à sec et repassage',
      type: ProviderType.pressing,
      phone: '0707000013',
      addressLine1: 'Centre-ville, Tiassalé',
      cityId: 'tiassale',
      latitude: 5.8982,
      longitude: -4.8232,
      logoUrl: 'https://i.pravatar.cc/150?u=pr1',
      averageRating: 4.4,
      ratingCount: 28,
      isOpen: true,
      distanceKm: 0.7,
    ),
  ];

  /// All providers combined for search
  static List<Provider> get allProviders => [
        ...popularProviders,
        ...nearbyProviders,
        // Additional providers for search
        const Provider(
          id: 'p5',
          name: 'Grillades du Soir',
          slug: 'grillades-du-soir',
          description: 'Viandes grillées et brochettes',
          type: ProviderType.restaurant,
          cuisineType: CuisineType.grilled,
          phone: '0707000005',
          addressLine1: 'Quartier Résidentiel, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.8995,
          longitude: -4.8240,
          logoUrl: 'https://i.pravatar.cc/150?u=r5',
          coverImageUrl: 'https://picsum.photos/seed/r5/400/200',
          averageRating: 4.1,
          ratingCount: 98,
          totalOrders: 412,
          isOpen: true,
          isFeatured: false,
          averagePrepTime: 25,
          minOrderAmount: 1500,
          distanceKm: 2.1,
        ),
        const Provider(
          id: 'p6',
          name: 'Snack Chez Adjoua',
          slug: 'snack-chez-adjoua',
          description: 'Allocodrome et garba',
          type: ProviderType.restaurant,
          cuisineType: CuisineType.ivorian,
          phone: '0707000006',
          addressLine1: 'Gare routière, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.8960,
          longitude: -4.8210,
          logoUrl: 'https://i.pravatar.cc/150?u=r6',
          coverImageUrl: 'https://picsum.photos/seed/r6/400/200',
          averageRating: 4.4,
          ratingCount: 234,
          totalOrders: 1023,
          isOpen: true,
          isFeatured: false,
          averagePrepTime: 15,
          minOrderAmount: 500,
          distanceKm: 1.5,
        ),
        const Provider(
          id: 'n5',
          name: 'Dépôt Gaz Express',
          slug: 'depot-gaz-express',
          description: 'Livraison rapide de gaz',
          type: ProviderType.gasDepot,
          phone: '0707000014',
          addressLine1: 'Route principale, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.9010,
          longitude: -4.8260,
          logoUrl: 'https://i.pravatar.cc/150?u=g2',
          averageRating: 4.5,
          ratingCount: 67,
          isOpen: true,
          distanceKm: 2.5,
        ),
        const Provider(
          id: 'n6',
          name: 'Pharmacie Santé Plus',
          slug: 'pharmacie-sante-plus',
          description: 'Pharmacie de garde 24h/24',
          type: ProviderType.pharmacy,
          phone: '0707000015',
          addressLine1: 'Centre hospitalier, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.8970,
          longitude: -4.8215,
          logoUrl: 'https://i.pravatar.cc/150?u=ph2',
          averageRating: 4.8,
          ratingCount: 123,
          isOpen: true,
          distanceKm: 0.9,
        ),
        const Provider(
          id: 'n7',
          name: 'Mini Market 24',
          slug: 'mini-market-24',
          description: 'Épicerie ouverte tard le soir',
          type: ProviderType.grocery,
          phone: '0707000016',
          addressLine1: 'Place du marché, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.8988,
          longitude: -4.8228,
          logoUrl: 'https://i.pravatar.cc/150?u=e2',
          averageRating: 4.0,
          ratingCount: 56,
          isOpen: false,
          distanceKm: 0.5,
        ),
        const Provider(
          id: 'n8',
          name: 'Pressing VIP',
          slug: 'pressing-vip',
          description: 'Service pressing premium',
          type: ProviderType.pressing,
          phone: '0707000017',
          addressLine1: 'Quartier chic, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.9005,
          longitude: -4.8245,
          logoUrl: 'https://i.pravatar.cc/150?u=pr2',
          averageRating: 4.7,
          ratingCount: 89,
          isOpen: true,
          distanceKm: 1.8,
        ),
        const Provider(
          id: 'n9',
          name: 'Artisan Menuisier Koffi',
          slug: 'artisan-menuisier-koffi',
          description: 'Menuiserie et ébénisterie',
          type: ProviderType.artisan,
          phone: '0707000018',
          addressLine1: 'Zone artisanale, Tiassalé',
          cityId: 'tiassale',
          latitude: 5.8950,
          longitude: -4.8200,
          logoUrl: 'https://i.pravatar.cc/150?u=a1',
          averageRating: 4.6,
          ratingCount: 34,
          isOpen: true,
          distanceKm: 2.2,
        ),
      ];

  /// All restaurants for restaurant list screen
  static List<Provider> get allRestaurants => allProviders
      .where((p) => p.type == ProviderType.restaurant)
      .toList();

  /// Search suggestions
  static const List<String> searchSuggestions = [
    'Restaurant',
    'Pizza',
    'Poulet braisé',
    'Attiéké',
    'Gaz',
    'Pharmacie',
    'Pressing',
    'Hamburger',
    'Poisson',
    'Garba',
  ];

  /// Recent searches (mock)
  static const List<String> recentSearches = [
    'Chez Tantine Marie',
    'Pizza',
    'Gaz 12kg',
  ];

  /// Grocery suggestions for errands service
  static const List<String> grocerySuggestions = [
    'Riz',
    'Huile',
    'Sel',
    'Sucre',
    'Tomates',
    'Oignons',
    'Poulet',
    'Poisson',
    'Attiéké',
    'Pain',
    'Lait',
    'Oeufs',
    'Savon',
    'Eau minérale',
    'Piment',
    'Cube Maggi',
    'Bananes plantain',
    'Igname',
    'Manioc',
    'Haricots',
  ];

  /// Provider schedules (for restaurant p1 - Chez Tantine Marie)
  static const List<ProviderSchedule> restaurantP1Schedules = [
    ProviderSchedule(id: 'sch1', providerId: 'p1', dayOfWeek: 0, openTime: '08:00', closeTime: '22:00'),
    ProviderSchedule(id: 'sch2', providerId: 'p1', dayOfWeek: 1, openTime: '08:00', closeTime: '22:00'),
    ProviderSchedule(id: 'sch3', providerId: 'p1', dayOfWeek: 2, openTime: '08:00', closeTime: '22:00'),
    ProviderSchedule(id: 'sch4', providerId: 'p1', dayOfWeek: 3, openTime: '08:00', closeTime: '22:00'),
    ProviderSchedule(id: 'sch5', providerId: 'p1', dayOfWeek: 4, openTime: '08:00', closeTime: '23:00'),
    ProviderSchedule(id: 'sch6', providerId: 'p1', dayOfWeek: 5, openTime: '10:00', closeTime: '23:00'),
    ProviderSchedule(id: 'sch7', providerId: 'p1', dayOfWeek: 6, openTime: '10:00', closeTime: '21:00'),
  ];

  /// Menu categories for restaurant p1 - Chez Tantine Marie
  static const List<MenuCategory> restaurantP1Menu = [
    MenuCategory(
      id: 'cat1',
      providerId: 'p1',
      name: 'Plats populaires',
      displayOrder: 0,
      products: [
        Product(
          id: 'prod1',
          providerId: 'p1',
          categoryId: 'cat1',
          name: 'Poulet braisé + Attiéké',
          description: 'Poulet braisé mariné aux épices locales, servi avec attiéké frais et piment',
          imageUrl: 'https://picsum.photos/seed/poulet1/300/200',
          price: 2500,
          isFeatured: true,
          prepTime: 25,
          options: [
            MenuOption(
              id: 'opt1',
              productId: 'prod1',
              name: 'Portion',
              type: MenuOptionType.single,
              isRequired: true,
              items: [
                MenuOptionItem(id: 'opt1_1', optionId: 'opt1', name: 'Normal', priceAdjustment: 0),
                MenuOptionItem(id: 'opt1_2', optionId: 'opt1', name: 'Grande portion', priceAdjustment: 500),
                MenuOptionItem(id: 'opt1_3', optionId: 'opt1', name: 'XL (2 personnes)', priceAdjustment: 1500),
              ],
            ),
            MenuOption(
              id: 'opt2',
              productId: 'prod1',
              name: 'Sauce',
              type: MenuOptionType.single,
              isRequired: false,
              items: [
                MenuOptionItem(id: 'opt2_1', optionId: 'opt2', name: 'Piment fort', priceAdjustment: 0),
                MenuOptionItem(id: 'opt2_2', optionId: 'opt2', name: 'Piment doux', priceAdjustment: 0),
                MenuOptionItem(id: 'opt2_3', optionId: 'opt2', name: 'Sans piment', priceAdjustment: 0),
              ],
            ),
            MenuOption(
              id: 'opt3',
              productId: 'prod1',
              name: 'Suppléments',
              type: MenuOptionType.multiple,
              isRequired: false,
              maxSelections: 3,
              items: [
                MenuOptionItem(id: 'opt3_1', optionId: 'opt3', name: 'Oeuf frit', priceAdjustment: 200),
                MenuOptionItem(id: 'opt3_2', optionId: 'opt3', name: 'Avocat', priceAdjustment: 300),
                MenuOptionItem(id: 'opt3_3', optionId: 'opt3', name: 'Banane plantain', priceAdjustment: 250),
              ],
            ),
          ],
        ),
        Product(
          id: 'prod2',
          providerId: 'p1',
          categoryId: 'cat1',
          name: 'Poisson braisé + Alloco',
          description: 'Poisson frais braisé au charbon, servi avec bananes plantains frites',
          imageUrl: 'https://picsum.photos/seed/poisson1/300/200',
          price: 3000,
          isFeatured: true,
          prepTime: 30,
          options: [
            MenuOption(
              id: 'opt4',
              productId: 'prod2',
              name: 'Type de poisson',
              type: MenuOptionType.single,
              isRequired: true,
              items: [
                MenuOptionItem(id: 'opt4_1', optionId: 'opt4', name: 'Carpe', priceAdjustment: 0),
                MenuOptionItem(id: 'opt4_2', optionId: 'opt4', name: 'Tilapia', priceAdjustment: 0),
                MenuOptionItem(id: 'opt4_3', optionId: 'opt4', name: 'Capitaine', priceAdjustment: 500),
              ],
            ),
            MenuOption(
              id: 'opt5',
              productId: 'prod2',
              name: 'Cuisson',
              type: MenuOptionType.single,
              isRequired: false,
              items: [
                MenuOptionItem(id: 'opt5_1', optionId: 'opt5', name: 'Bien braisé', priceAdjustment: 0),
                MenuOptionItem(id: 'opt5_2', optionId: 'opt5', name: 'Légèrement braisé', priceAdjustment: 0),
              ],
            ),
          ],
        ),
        Product(
          id: 'prod3',
          providerId: 'p1',
          categoryId: 'cat1',
          name: 'Garba',
          description: 'Attiéké garba avec thon frit, oignons et piment frais',
          imageUrl: 'https://picsum.photos/seed/garba/300/200',
          price: 1000,
          isFeatured: true,
          prepTime: 10,
        ),
      ],
    ),
    MenuCategory(
      id: 'cat2',
      providerId: 'p1',
      name: 'Entrées',
      displayOrder: 1,
      products: [
        Product(
          id: 'prod4',
          providerId: 'p1',
          categoryId: 'cat2',
          name: 'Salade africaine',
          description: 'Salade fraîche avec avocat, tomates et vinaigrette maison',
          imageUrl: 'https://picsum.photos/seed/salade/300/200',
          price: 1500,
          isVegetarian: true,
          prepTime: 10,
        ),
        Product(
          id: 'prod5',
          providerId: 'p1',
          categoryId: 'cat2',
          name: 'Brochettes de boeuf',
          description: '4 brochettes de boeuf marinées et grillées',
          imageUrl: 'https://picsum.photos/seed/brochette/300/200',
          price: 2000,
          prepTime: 15,
          options: [
            MenuOption(
              id: 'opt6',
              productId: 'prod5',
              name: 'Nombre de brochettes',
              type: MenuOptionType.single,
              isRequired: true,
              items: [
                MenuOptionItem(id: 'opt6_1', optionId: 'opt6', name: '4 brochettes', priceAdjustment: 0),
                MenuOptionItem(id: 'opt6_2', optionId: 'opt6', name: '6 brochettes', priceAdjustment: 800),
                MenuOptionItem(id: 'opt6_3', optionId: 'opt6', name: '8 brochettes', priceAdjustment: 1500),
              ],
            ),
          ],
        ),
      ],
    ),
    MenuCategory(
      id: 'cat3',
      providerId: 'p1',
      name: 'Plats principaux',
      displayOrder: 2,
      products: [
        Product(
          id: 'prod6',
          providerId: 'p1',
          categoryId: 'cat3',
          name: 'Foutou banane + Sauce graine',
          description: 'Foutou de banane plantain avec sauce graine de palme et viande',
          imageUrl: 'https://picsum.photos/seed/foutou/300/200',
          price: 3500,
          prepTime: 35,
          options: [
            MenuOption(
              id: 'opt7',
              productId: 'prod6',
              name: 'Viande',
              type: MenuOptionType.single,
              isRequired: true,
              items: [
                MenuOptionItem(id: 'opt7_1', optionId: 'opt7', name: 'Poulet', priceAdjustment: 0),
                MenuOptionItem(id: 'opt7_2', optionId: 'opt7', name: 'Viande de boeuf', priceAdjustment: 500),
                MenuOptionItem(id: 'opt7_3', optionId: 'opt7', name: 'Escargots', priceAdjustment: 1000),
              ],
            ),
          ],
        ),
        Product(
          id: 'prod7',
          providerId: 'p1',
          categoryId: 'cat3',
          name: 'Riz sauce arachide + Poulet',
          description: 'Riz blanc avec sauce arachide maison et morceau de poulet',
          imageUrl: 'https://picsum.photos/seed/riz/300/200',
          price: 2500,
          prepTime: 25,
        ),
        Product(
          id: 'prod8',
          providerId: 'p1',
          categoryId: 'cat3',
          name: 'Kedjenou de poulet',
          description: 'Poulet mijoté à l\'étouffée avec légumes et épices',
          imageUrl: 'https://picsum.photos/seed/kedjenou/300/200',
          price: 4000,
          isSpicy: true,
          prepTime: 40,
        ),
        Product(
          id: 'prod9',
          providerId: 'p1',
          categoryId: 'cat3',
          name: 'Tiep bou dien',
          description: 'Riz au poisson sénégalais avec légumes',
          imageUrl: 'https://picsum.photos/seed/tiep/300/200',
          price: 3500,
          prepTime: 35,
        ),
      ],
    ),
    MenuCategory(
      id: 'cat4',
      providerId: 'p1',
      name: 'Boissons',
      displayOrder: 3,
      products: [
        Product(
          id: 'prod10',
          providerId: 'p1',
          categoryId: 'cat4',
          name: 'Bissap',
          description: 'Jus d\'hibiscus frais fait maison',
          imageUrl: 'https://picsum.photos/seed/bissap/300/200',
          price: 500,
          isVegetarian: true,
          prepTime: 2,
        ),
        Product(
          id: 'prod11',
          providerId: 'p1',
          categoryId: 'cat4',
          name: 'Gingembre',
          description: 'Jus de gingembre frais épicé',
          imageUrl: 'https://picsum.photos/seed/ginger/300/200',
          price: 500,
          isVegetarian: true,
          isSpicy: true,
          prepTime: 2,
        ),
        Product(
          id: 'prod12',
          providerId: 'p1',
          categoryId: 'cat4',
          name: 'Coca-Cola',
          description: 'Bouteille 50cl',
          imageUrl: 'https://picsum.photos/seed/coca/300/200',
          price: 500,
          isVegetarian: true,
          prepTime: 1,
        ),
        Product(
          id: 'prod13',
          providerId: 'p1',
          categoryId: 'cat4',
          name: 'Eau minerale',
          description: 'Bouteille 1.5L',
          imageUrl: 'https://picsum.photos/seed/water/300/200',
          price: 500,
          isVegetarian: true,
          prepTime: 1,
        ),
      ],
    ),
    MenuCategory(
      id: 'cat5',
      providerId: 'p1',
      name: 'Desserts',
      displayOrder: 4,
      products: [
        Product(
          id: 'prod14',
          providerId: 'p1',
          categoryId: 'cat5',
          name: 'Fruits frais',
          description: 'Assiette de fruits de saison (mangue, ananas, papaye)',
          imageUrl: 'https://picsum.photos/seed/fruits/300/200',
          price: 1000,
          isVegetarian: true,
          prepTime: 5,
        ),
        Product(
          id: 'prod15',
          providerId: 'p1',
          categoryId: 'cat5',
          name: 'Dêguê',
          description: 'Bouillie de mil au lait caillé sucré',
          imageUrl: 'https://picsum.photos/seed/degue/300/200',
          price: 800,
          isVegetarian: true,
          prepTime: 5,
        ),
      ],
    ),
  ];

  /// Get schedules for a provider
  static List<ProviderSchedule> getSchedulesForProvider(String providerId) {
    if (providerId == 'p1') return restaurantP1Schedules;
    // Default schedules for other providers
    return List.generate(7, (index) => ProviderSchedule(
      id: 'sch_${providerId}_$index',
      providerId: providerId,
      dayOfWeek: index,
      openTime: '08:00',
      closeTime: '21:00',
    ));
  }

  /// Get menu for a provider
  static List<MenuCategory> getMenuForProvider(String providerId) {
    if (providerId == 'p1') return restaurantP1Menu;
    // Default menu for other providers
    return [
      MenuCategory(
        id: 'default_cat',
        providerId: providerId,
        name: 'Menu',
        products: [
          Product(
            id: 'default_prod1',
            providerId: providerId,
            name: 'Plat du jour',
            description: 'Notre spécialité du jour',
            imageUrl: 'https://picsum.photos/seed/$providerId/300/200',
            price: 2500,
          ),
        ],
      ),
    ];
  }

  /// Gas depots (filtered from allProviders)
  static List<Provider> get gasDepots =>
      allProviders.where((p) => p.type == ProviderType.gasDepot).toList();

  /// Gas products for depot n1 (Dépôt Gaz Yao)
  static const List<GasProduct> gasDepotN1Products = [
    // Total brand
    GasProduct(
      id: 'gas1',
      providerId: 'n1',
      brand: GasBrand.total,
      bottleSize: GasBottleSize.small,
      refillPrice: 3500,
      exchangePrice: 4000,
      quantityAvailable: 15,
    ),
    GasProduct(
      id: 'gas2',
      providerId: 'n1',
      brand: GasBrand.total,
      bottleSize: GasBottleSize.medium,
      refillPrice: 5500,
      exchangePrice: 6500,
      quantityAvailable: 20,
    ),
    GasProduct(
      id: 'gas3',
      providerId: 'n1',
      brand: GasBrand.total,
      bottleSize: GasBottleSize.large,
      refillPrice: 18000,
      exchangePrice: 22000,
      quantityAvailable: 5,
    ),
    // Shell brand
    GasProduct(
      id: 'gas4',
      providerId: 'n1',
      brand: GasBrand.shell,
      bottleSize: GasBottleSize.small,
      refillPrice: 3600,
      exchangePrice: 4200,
      quantityAvailable: 10,
    ),
    GasProduct(
      id: 'gas5',
      providerId: 'n1',
      brand: GasBrand.shell,
      bottleSize: GasBottleSize.medium,
      refillPrice: 5700,
      exchangePrice: 6800,
      quantityAvailable: 12,
    ),
  ];

  /// Gas products for depot n5 (Dépôt Gaz Express)
  static const List<GasProduct> gasDepotN5Products = [
    // Oryx brand
    GasProduct(
      id: 'gas6',
      providerId: 'n5',
      brand: GasBrand.oryx,
      bottleSize: GasBottleSize.small,
      refillPrice: 3400,
      exchangePrice: 3900,
      quantityAvailable: 25,
    ),
    GasProduct(
      id: 'gas7',
      providerId: 'n5',
      brand: GasBrand.oryx,
      bottleSize: GasBottleSize.medium,
      refillPrice: 5400,
      exchangePrice: 6300,
      quantityAvailable: 30,
    ),
    GasProduct(
      id: 'gas8',
      providerId: 'n5',
      brand: GasBrand.oryx,
      bottleSize: GasBottleSize.large,
      refillPrice: 17500,
      exchangePrice: 21000,
      quantityAvailable: 8,
    ),
    // Total brand
    GasProduct(
      id: 'gas9',
      providerId: 'n5',
      brand: GasBrand.total,
      bottleSize: GasBottleSize.medium,
      refillPrice: 5500,
      exchangePrice: 6500,
      quantityAvailable: 15,
    ),
  ];

  /// Get gas products for a provider
  static List<GasProduct> getGasProductsForProvider(String providerId) {
    switch (providerId) {
      case 'n1':
        return gasDepotN1Products;
      case 'n5':
        return gasDepotN5Products;
      default:
        // Default products for other gas depots
        return [
          GasProduct(
            id: 'gas_default_1',
            providerId: providerId,
            brand: GasBrand.other,
            bottleSize: GasBottleSize.small,
            refillPrice: 3500,
            exchangePrice: 4000,
            quantityAvailable: 10,
          ),
          GasProduct(
            id: 'gas_default_2',
            providerId: providerId,
            brand: GasBrand.other,
            bottleSize: GasBottleSize.medium,
            refillPrice: 5500,
            exchangePrice: 6500,
            quantityAvailable: 10,
          ),
        ];
    }
  }

  /// Get available bottle sizes for a provider
  static List<GasBottleSize> getAvailableSizesForProvider(String providerId) {
    final products = getGasProductsForProvider(providerId);
    return products.map((p) => p.bottleSize).toSet().toList()
      ..sort((a, b) => a.kg.compareTo(b.kg));
  }

  /// Get available brands for a provider and size
  static List<GasBrand> getAvailableBrandsForSize(
      String providerId, GasBottleSize size) {
    final products = getGasProductsForProvider(providerId);
    return products
        .where((p) => p.bottleSize == size)
        .map((p) => p.brand)
        .toSet()
        .toList();
  }

  /// Get gas product by provider, size and brand
  static GasProduct? getGasProduct(
      String providerId, GasBottleSize size, GasBrand brand) {
    final products = getGasProductsForProvider(providerId);
    return products.cast<GasProduct?>().firstWhere(
          (p) => p!.bottleSize == size && p.brand == brand,
          orElse: () => null,
        );
  }

  /// User saved addresses (mock)
  static const List<Map<String, dynamic>> userAddresses = [
    {
      'id': 'addr1',
      'label': 'Maison',
      'address': 'Quartier Résidentiel, Tiassalé',
      'latitude': 5.8980,
      'longitude': -4.8225,
      'isDefault': true,
    },
    {
      'id': 'addr2',
      'label': 'Bureau',
      'address': 'Centre-ville, Tiassalé',
      'latitude': 5.8975,
      'longitude': -4.8220,
      'isDefault': false,
    },
    {
      'id': 'addr3',
      'label': 'Chez Maman',
      'address': 'Route de Divo, Tiassalé',
      'latitude': 5.9000,
      'longitude': -4.8250,
      'isDefault': false,
    },
  ];

  // ============================================
  // PARCEL SERVICE PRICING
  // ============================================

  /// Parcel delivery pricing configuration in FCFA
  static const Map<String, int> parcelPricing = {
    'base_fee': 500, // Base delivery fee
    'per_km_rate': 200, // Price per kilometer
    'additional_stop_fee': 300, // Fee for each additional destination
    'min_fee': 1000, // Minimum delivery fee
    'max_distance_km': 20, // Maximum delivery distance
  };

  /// Calculate parcel delivery price based on total distance and number of stops
  static int calculateParcelPrice(double totalDistanceKm, int numberOfStops) {
    final baseFee = parcelPricing['base_fee']!;
    final perKmRate = parcelPricing['per_km_rate']!;
    final additionalStopFee = parcelPricing['additional_stop_fee']!;
    final minFee = parcelPricing['min_fee']!;

    // Calculate: base + (distance * rate) + (extra stops * stop fee)
    int price = baseFee + (totalDistanceKm * perKmRate).round();
    if (numberOfStops > 1) {
      price += (numberOfStops - 1) * additionalStopFee;
    }

    return price < minFee ? minFee : price;
  }

  /// Calculate distance between two points using simplified Haversine
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (3.141592653589793 / 180);

  /// Calculate total route distance from pickup through all destinations
  static double calculateTotalRouteDistance(
    Map<String, dynamic> pickup,
    List<Map<String, dynamic>> destinations,
  ) {
    if (destinations.isEmpty) return 0;

    final pickupLat = pickup['latitude'] as double?;
    final pickupLng = pickup['longitude'] as double?;

    if (pickupLat == null || pickupLng == null) return 0;

    double totalDistance = 0;
    double prevLat = pickupLat;
    double prevLng = pickupLng;

    for (final dest in destinations) {
      final destLat = dest['latitude'] as double?;
      final destLng = dest['longitude'] as double?;
      if (destLat != null && destLng != null) {
        totalDistance += calculateDistance(prevLat, prevLng, destLat, destLng);
        prevLat = destLat;
        prevLng = destLng;
      }
    }

    return totalDistance;
  }

  /// Format price for display (e.g., "1 500 FCFA")
  static String formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }

  /// Current promotions
  static final List<Promotion> promotions = [
    Promotion(
      id: 'promo1',
      code: 'BIENVENUE',
      name: 'Bienvenue sur NELO !',
      description: '20% sur votre première commande',
      type: PromotionType.percentage,
      discountValue: 20,
      maxDiscount: 2000,
      imageUrl: 'https://picsum.photos/seed/promo1/600/300',
      endsAt: DateTime.now().add(const Duration(days: 30)),
    ),
    Promotion(
      id: 'promo2',
      name: 'Livraison offerte',
      description: 'Livraison gratuite dès 5000F',
      type: PromotionType.freeDelivery,
      discountValue: 0,
      minOrderAmount: 5000,
      imageUrl: 'https://picsum.photos/seed/promo2/600/300',
      endsAt: DateTime.now().add(const Duration(days: 7)),
    ),
    Promotion(
      id: 'promo3',
      code: 'GAZ500',
      name: 'Promo Gaz',
      description: '500F de réduction sur le gaz',
      type: PromotionType.fixed,
      discountValue: 500,
      imageUrl: 'https://picsum.photos/seed/promo3/600/300',
      endsAt: DateTime.now().add(const Duration(days: 14)),
    ),
  ];

  // ============================================
  // WALLET & TRANSACTIONS
  // ============================================

  /// Current user wallet balance (mock)
  static const int walletBalance = 5000;

  /// Mock wallet transactions
  static List<Map<String, dynamic>> get walletTransactions => [
        {
          'id': 'tx1',
          'type': 'topUp',
          'amount': 5000,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
          'description': 'Recharge via Wave',
          'reference': 'WAV-2024-001234',
          'paymentMethod': 'wave',
        },
        {
          'id': 'tx2',
          'type': 'payment',
          'amount': 3500,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'description': 'Commande Gaz #ORD-2024-0003',
          'orderId': 'ord3',
        },
        {
          'id': 'tx3',
          'type': 'topUp',
          'amount': 10000,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'description': 'Recharge via Orange Money',
          'reference': 'OM-2024-005678',
          'paymentMethod': 'orangeMoney',
        },
        {
          'id': 'tx4',
          'type': 'payment',
          'amount': 2500,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'description': 'Commande Restaurant #ORD-2024-0002',
          'orderId': 'ord2',
        },
        {
          'id': 'tx5',
          'type': 'cashback',
          'amount': 500,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'description': 'Cashback première commande',
        },
        {
          'id': 'tx6',
          'type': 'refund',
          'amount': 1500,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(days: 5)),
          'description': 'Remboursement commande annulée',
          'orderId': 'ord_cancelled',
        },
      ];

  /// Preset top-up amounts in FCFA
  static const List<int> topUpAmounts = [1000, 2000, 5000, 10000];

  // ============================================
  // ORDERS
  // ============================================

  /// Mock orders for order history
  static List<Map<String, dynamic>> get orders => [
        // Active order - in transit
        {
          'id': 'ord1',
          'orderNumber': 'ORD-2024-0001',
          'serviceType': 'restaurant',
          'status': 'inTransit',
          'totalAmount': 4500,
          'deliveryFee': 500,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 25)),
          'providerName': 'Chez Tantine Marie',
          'providerLogoUrl': 'https://i.pravatar.cc/150?u=r1',
          'deliveryAddress': 'Quartier Résidentiel, Tiassalé',
          'paymentMethod': 'wallet',
          'itemsSummary': 'Poulet braisé + Attiéké, Bissap',
          'itemsCount': 2,
          'confirmationCode': '4523',
          'estimatedDeliveryTime': DateTime.now().add(const Duration(minutes: 15)),
          'driver': {
            'id': 'drv1',
            'name': 'Konan Yao',
            'phone': '+225 07 00 00 01',
            'photoUrl': 'https://i.pravatar.cc/150?u=driver1',
            'vehicleType': 'Moto',
            'vehiclePlate': 'AB 1234 CI',
            'rating': 4.8,
            'currentLatitude': 5.8985,
            'currentLongitude': -4.8228,
          },
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
            },
            {
              'status': 'confirmed',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 23)),
            },
            {
              'status': 'preparing',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 20)),
            },
            {
              'status': 'readyForPickup',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
            },
            {
              'status': 'pickedUp',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
            },
            {
              'status': 'inTransit',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
            },
          ],
        },
        // Completed order - restaurant
        {
          'id': 'ord2',
          'orderNumber': 'ORD-2024-0002',
          'serviceType': 'restaurant',
          'status': 'delivered',
          'totalAmount': 3000,
          'deliveryFee': 500,
          'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          'providerName': 'Le Maquis du Port',
          'providerLogoUrl': 'https://i.pravatar.cc/150?u=r2',
          'deliveryAddress': 'Centre-ville, Tiassalé',
          'paymentMethod': 'cash',
          'itemsSummary': 'Poisson braisé + Alloco',
          'itemsCount': 1,
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
            },
            {
              'status': 'confirmed',
              'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 55)),
            },
            {
              'status': 'preparing',
              'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 50)),
            },
            {
              'status': 'delivered',
              'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
            },
          ],
        },
        // Completed order - gas
        {
          'id': 'ord3',
          'orderNumber': 'ORD-2024-0003',
          'serviceType': 'gas',
          'status': 'delivered',
          'totalAmount': 4000,
          'deliveryFee': 500,
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'providerName': 'Dépôt Gaz Yao',
          'providerLogoUrl': 'https://i.pravatar.cc/150?u=g1',
          'deliveryAddress': 'Quartier Résidentiel, Tiassalé',
          'paymentMethod': 'wallet',
          'itemsSummary': 'Bouteille 6kg - Échange',
          'itemsCount': 1,
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 1)),
            },
            {
              'status': 'confirmed',
              'timestamp': DateTime.now().subtract(const Duration(days: 2, minutes: 55)),
            },
            {
              'status': 'delivered',
              'timestamp': DateTime.now().subtract(const Duration(days: 2)),
            },
          ],
        },
        // Completed order - errands
        {
          'id': 'ord4',
          'orderNumber': 'ORD-2024-0004',
          'serviceType': 'errands',
          'status': 'delivered',
          'totalAmount': 8500,
          'deliveryFee': 1000,
          'createdAt': DateTime.now().subtract(const Duration(days: 4)),
          'providerName': 'Service Courses',
          'deliveryAddress': 'Chez Maman, Route de Divo',
          'paymentMethod': 'wave',
          'itemsSummary': 'Riz 5kg, Huile 1L, Tomates, Oignons...',
          'itemsCount': 6,
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': DateTime.now().subtract(const Duration(days: 4, hours: 2)),
            },
            {
              'status': 'confirmed',
              'timestamp': DateTime.now().subtract(const Duration(days: 4, hours: 1, minutes: 50)),
            },
            {
              'status': 'delivered',
              'timestamp': DateTime.now().subtract(const Duration(days: 4)),
            },
          ],
        },
        // Completed order - parcel
        {
          'id': 'ord5',
          'orderNumber': 'ORD-2024-0005',
          'serviceType': 'parcel',
          'status': 'delivered',
          'totalAmount': 1500,
          'deliveryFee': 0,
          'createdAt': DateTime.now().subtract(const Duration(days: 5)),
          'pickupAddress': 'Quartier Commerce, Tiassalé',
          'deliveryAddress': 'Gare routière, Tiassalé',
          'paymentMethod': 'cash',
          'itemsSummary': 'Colis express - 2 destinations',
          'itemsCount': 1,
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': DateTime.now().subtract(const Duration(days: 5, hours: 1)),
            },
            {
              'status': 'confirmed',
              'timestamp': DateTime.now().subtract(const Duration(days: 5, minutes: 55)),
            },
            {
              'status': 'delivered',
              'timestamp': DateTime.now().subtract(const Duration(days: 5)),
            },
          ],
        },
        // Cancelled order
        {
          'id': 'ord6',
          'orderNumber': 'ORD-2024-0006',
          'serviceType': 'restaurant',
          'status': 'cancelled',
          'totalAmount': 2000,
          'deliveryFee': 500,
          'createdAt': DateTime.now().subtract(const Duration(days: 6)),
          'providerName': 'Fast Food Abi',
          'providerLogoUrl': 'https://i.pravatar.cc/150?u=r3',
          'deliveryAddress': 'Centre-ville, Tiassalé',
          'paymentMethod': 'wallet',
          'itemsSummary': 'Hamburger, Frites',
          'itemsCount': 2,
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': DateTime.now().subtract(const Duration(days: 6, hours: 1)),
            },
            {
              'status': 'cancelled',
              'timestamp': DateTime.now().subtract(const Duration(days: 6)),
              'note': 'Annulée par le client',
            },
          ],
        },
      ];

  /// Get active orders (in progress)
  static List<Map<String, dynamic>> get activeOrders =>
      orders.where((o) => _isActiveStatus(o['status'] as String)).toList();

  /// Get completed orders
  static List<Map<String, dynamic>> get completedOrders =>
      orders.where((o) => !_isActiveStatus(o['status'] as String)).toList();

  /// Get orders by service type
  static List<Map<String, dynamic>> getOrdersByService(String serviceType) =>
      orders.where((o) => o['serviceType'] == serviceType).toList();

  static bool _isActiveStatus(String status) {
    return status != 'delivered' && status != 'cancelled' && status != 'refunded';
  }
}
