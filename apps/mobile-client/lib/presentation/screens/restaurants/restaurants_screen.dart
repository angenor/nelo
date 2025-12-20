import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'widgets/widgets.dart';

/// Restaurant listing screen with filters
class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  List<Provider> _restaurants = [];
  bool _isLoading = true;

  // Filters
  CuisineType? _selectedCuisine;
  double? _minRating;
  int? _maxPrepTime;
  bool _openNowOnly = false;
  RestaurantSortBy _sortBy = RestaurantSortBy.popularity;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    setState(() => _isLoading = true);

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      var results = MockData.allRestaurants;

      // Apply filters
      results = _applyFilters(results);

      // Apply sorting
      results = _applySorting(results);

      if (mounted) {
        setState(() {
          _restaurants = results;
          _isLoading = false;
        });
      }
    });
  }

  List<Provider> _applyFilters(List<Provider> restaurants) {
    var filtered = restaurants;

    // Filter by cuisine type
    if (_selectedCuisine != null) {
      filtered = filtered
          .where((r) => r.cuisineType == _selectedCuisine)
          .toList();
    }

    // Filter by minimum rating
    if (_minRating != null) {
      filtered = filtered
          .where((r) => (r.averageRating ?? 0) >= _minRating!)
          .toList();
    }

    // Filter by max prep time
    if (_maxPrepTime != null) {
      filtered = filtered
          .where((r) => r.averagePrepTime <= _maxPrepTime!)
          .toList();
    }

    // Filter by open status
    if (_openNowOnly) {
      filtered = filtered.where((r) => r.isOpen).toList();
    }

    return filtered;
  }

  List<Provider> _applySorting(List<Provider> restaurants) {
    switch (_sortBy) {
      case RestaurantSortBy.popularity:
        return [...restaurants]..sort((a, b) {
            // Featured first, then by order count
            if (a.isFeatured && !b.isFeatured) return -1;
            if (!a.isFeatured && b.isFeatured) return 1;
            return b.totalOrders.compareTo(a.totalOrders);
          });
      case RestaurantSortBy.rating:
        return [...restaurants]..sort((a, b) {
            final ratingA = a.averageRating ?? 0;
            final ratingB = b.averageRating ?? 0;
            return ratingB.compareTo(ratingA);
          });
      case RestaurantSortBy.distance:
        return [...restaurants]..sort((a, b) {
            final distA = a.distanceKm ?? double.infinity;
            final distB = b.distanceKm ?? double.infinity;
            return distA.compareTo(distB);
          });
      case RestaurantSortBy.prepTime:
        return [...restaurants]..sort((a, b) {
            return a.averagePrepTime.compareTo(b.averagePrepTime);
          });
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCuisine != null) count++;
    if (_minRating != null) count++;
    if (_maxPrepTime != null) count++;
    if (_openNowOnly) count++;
    return count;
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantFiltersSheet(
        selectedCuisine: _selectedCuisine,
        minRating: _minRating,
        maxPrepTime: _maxPrepTime,
        openNowOnly: _openNowOnly,
        sortBy: _sortBy,
        onApply: (cuisine, rating, prepTime, openNow, sortBy) {
          Navigator.pop(context);
          setState(() {
            _selectedCuisine = cuisine;
            _minRating = rating;
            _maxPrepTime = prepTime;
            _openNowOnly = openNow;
            _sortBy = sortBy;
          });
          _loadRestaurants();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCuisine = null;
      _minRating = null;
      _maxPrepTime = null;
      _openNowOnly = false;
      _sortBy = RestaurantSortBy.popularity;
    });
    _loadRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Restaurants',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => context.push('/search?type=restaurants'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Filter button
                _FilterButton(
                  activeCount: _activeFilterCount,
                  onTap: _openFilters,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Cuisine quick filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Open now chip
                        _QuickFilterChip(
                          label: 'Ouvert',
                          icon: Icons.access_time,
                          isSelected: _openNowOnly,
                          onTap: () {
                            setState(() => _openNowOnly = !_openNowOnly);
                            _loadRestaurants();
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),

                        // Cuisine chips
                        ...CuisineType.values.take(4).map((cuisine) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: _QuickFilterChip(
                              label: cuisine.label,
                              isSelected: _selectedCuisine == cuisine,
                              onTap: () {
                                setState(() {
                                  _selectedCuisine =
                                      _selectedCuisine == cuisine ? null : cuisine;
                                });
                                _loadRestaurants();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_restaurants.length} restaurants',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_activeFilterCount > 0)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Effacer filtres',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Restaurant list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _restaurants.isEmpty
                    ? _EmptyState(onClearFilters: _clearFilters)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _restaurants.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
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
    );
  }
}

/// Sort options for restaurants
enum RestaurantSortBy {
  popularity,
  rating,
  distance,
  prepTime,
}

extension RestaurantSortByLabel on RestaurantSortBy {
  String get label {
    switch (this) {
      case RestaurantSortBy.popularity:
        return 'Popularite';
      case RestaurantSortBy.rating:
        return 'Note';
      case RestaurantSortBy.distance:
        return 'Distance';
      case RestaurantSortBy.prepTime:
        return 'Temps de preparation';
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: activeCount > 0 ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: activeCount > 0 ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: activeCount > 0 ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Filtres',
              style: AppTypography.labelMedium.copyWith(
                color: activeCount > 0 ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClearFilters});

  final VoidCallback onClearFilters;

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
              'Essayez de modifier vos filtres',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onClearFilters,
              child: Text(
                'Effacer les filtres',
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
