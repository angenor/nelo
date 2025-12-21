import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
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

  // Scroll tracking for header title
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInHeader = false;
  static const double _titleScrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > _titleScrollThreshold;
    if (shouldShow != _showTitleInHeader) {
      setState(() {
        _showTitleInHeader = shouldShow;
      });
    }
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
          ),

          // Title or Location info (animated transition)
          Expanded(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _showTitleInHeader
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Text(
                'Restaurants',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              secondChild: GestureDetector(
                onTap: () {
                  // TODO: Open location picker
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Livrer à',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Tiassalé, Centre-ville',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Notifications
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            _buildHeader(context),

            // Scrollable content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : CustomScrollView(
                      controller: _scrollController,
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
