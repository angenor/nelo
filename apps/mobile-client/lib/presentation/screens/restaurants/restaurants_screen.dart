import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import '../home/widgets/home_header.dart';
import 'widgets/widgets.dart';

/// Restaurant listing screen with visual filters
class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  List<Provider> _restaurants = [];
  bool _isLoading = true;

  // Filter
  CuisineType? _selectedCuisine;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      var results = MockData.allRestaurants;

      // Filter by cuisine type
      if (_selectedCuisine != null) {
        results = results
            .where((r) => r.cuisineType == _selectedCuisine)
            .toList();
      }

      // Sort by popularity (featured first, then by orders)
      results = [...results]..sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.totalOrders.compareTo(a.totalOrders);
        });

      if (mounted) {
        setState(() {
          _restaurants = results;
          _isLoading = false;
        });
      }
    });
  }

  void _onCuisineSelected(CuisineType? cuisine) {
    setState(() {
      _selectedCuisine = cuisine;
    });
    _loadRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with delivery address (like home page)
            HomeHeader(
              location: 'Tiassale, Centre-ville',
              onLocationTap: () {
                // TODO: Open location picker
              },
              onNotificationTap: () {
                context.push('/notifications');
              },
            ),

            // Page title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Restaurants',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: GestureDetector(
                onTap: () => context.push('/search?type=restaurants'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Rechercher un restaurant...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Cuisine filter grid with images
            CuisineFilterGrid(
              selectedCuisine: _selectedCuisine,
              onCuisineSelected: _onCuisineSelected,
            ),

            const SizedBox(height: AppSpacing.md),

            // Restaurant list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _restaurants.isEmpty
                      ? _EmptyState(
                          onClearFilter: () => _onCuisineSelected(null),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _restaurants.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.lg),
                          itemBuilder: (context, index) {
                            final restaurant = _restaurants[index];
                            return RestaurantCard(
                              restaurant: restaurant,
                              onTap: () {
                                context.push('/provider/${restaurant.id}');
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClearFilter});

  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun restaurant trouve',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Essayez un autre type de cuisine',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onClearFilter,
              child: Text(
                'Voir tous les restaurants',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
