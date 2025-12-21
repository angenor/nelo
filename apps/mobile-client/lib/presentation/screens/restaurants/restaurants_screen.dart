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

  // Favorites (local state for now)
  final Set<String> _favoriteIds = {};

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

  void _toggleFavorite(String restaurantId) {
    setState(() {
      if (_favoriteIds.contains(restaurantId)) {
        _favoriteIds.remove(restaurantId);
      } else {
        _favoriteIds.add(restaurantId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with delivery address (stays fixed)
            HomeHeader(
              location: 'Tiassale, Centre-ville',
              onLocationTap: () {
                // TODO: Open location picker
              },
              onNotificationTap: () {
                context.push('/notifications');
              },
            ),

            // Scrollable content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Page title
                        SliverToBoxAdapter(
                          child: Padding(
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
                        ),

                        // Search bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: GestureDetector(
                              onTap: () => context.push('/search?type=restaurants'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusFull),
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
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.md),
                        ),

                        // Cuisine filter grid with images
                        SliverToBoxAdapter(
                          child: CuisineFilterGrid(
                            selectedCuisine: _selectedCuisine,
                            onCuisineSelected: _onCuisineSelected,
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.md),
                        ),

                        // Restaurant list or empty state
                        if (_restaurants.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              onClearFilter: () => _onCuisineSelected(null),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final restaurant = _restaurants[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index < _restaurants.length - 1
                                          ? AppSpacing.lg
                                          : 0,
                                    ),
                                    child: RestaurantCard(
                                      restaurant: restaurant,
                                      isFavorite:
                                          _favoriteIds.contains(restaurant.id),
                                      onFavoriteTap: () =>
                                          _toggleFavorite(restaurant.id),
                                      onTap: () {
                                        context.push('/restaurants/${restaurant.id}');
                                      },
                                    ),
                                  );
                                },
                                childCount: _restaurants.length,
                              ),
                            ),
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
