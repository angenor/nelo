import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/otp_verification_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/main/main_shell.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/restaurants/restaurants_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String home = '/home';
  static const String search = '/search';

  // MVP Service routes
  static const String restaurants = '/restaurants';
  static const String gas = '/gas';
  static const String errands = '/errands';
  static const String parcel = '/parcel';

  static const String providerDetail = '/provider/:id';
  static const String productDetail = '/product/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderTracking = '/order/:id/tracking';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String addresses = '/addresses';
  static const String wallet = '/wallet';
  static const String notifications = '/notifications';
}

/// Application router configuration
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// GoRouter instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final mode = state.uri.queryParameters['mode'] ?? 'login';
          final referralCode = state.uri.queryParameters['referral_code'];
          return OtpVerificationScreen(
            phone: phone,
            mode: mode,
            referralCode: referralCode,
          );
        },
      ),

      // Main app with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Search tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                builder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  return SearchScreen(
                    initialCategoryType: type,
                  );
                },
              ),
            ],
          ),
          // Orders tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                name: 'orders',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Mes commandes'),
              ),
            ],
          ),
          // Wallet tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wallet,
                name: 'wallet',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Portefeuille'),
              ),
            ],
          ),
          // Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Mon profil'),
              ),
            ],
          ),
        ],
      ),

      // Detail routes (outside bottom navigation)
      GoRoute(
        path: AppRoutes.providerDetail,
        name: 'providerDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _PlaceholderScreen(title: 'Prestataire: $id');
        },
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _PlaceholderScreen(title: 'Produit: $id');
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const _PlaceholderScreen(title: 'Panier'),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Paiement'),
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _PlaceholderScreen(title: 'Suivi commande: $id');
        },
      ),
      GoRoute(
        path: AppRoutes.addresses,
        name: 'addresses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Mes adresses'),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Notifications'),
      ),

      // MVP Service routes
      GoRoute(
        path: AppRoutes.restaurants,
        name: 'restaurants',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RestaurantsScreen(),
      ),
      GoRoute(
        path: AppRoutes.gas,
        name: 'gas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _ServicePlaceholderScreen(
              title: 'Commander du Gaz',
              icon: Icons.local_fire_department,
              color: Color(0xFFFF9500),
              description: 'Carte + selection depot + bouteille',
            ),
      ),
      GoRoute(
        path: AppRoutes.errands,
        name: 'errands',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _ServicePlaceholderScreen(
              title: 'Faire mes courses',
              icon: Icons.shopping_basket,
              color: Color(0xFF34C759),
              description: 'Carte + liste de courses + note vocale',
            ),
      ),
      GoRoute(
        path: AppRoutes.parcel,
        name: 'parcel',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _ServicePlaceholderScreen(
              title: 'Envoyer un colis',
              icon: Icons.local_shipping,
              color: Color(0xFF007AFF),
              description: 'Carte multi-points + description colis',
            ),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ecran en cours de developpement',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service placeholder screen with custom icon and color
class _ServicePlaceholderScreen extends StatelessWidget {
  const _ServicePlaceholderScreen({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 56, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction, size: 20, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'En cours de developpement',
                    style: TextStyle(color: Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for invalid routes
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page introuvable',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
