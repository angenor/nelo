import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../restaurants_screen.dart';

/// Bottom sheet for restaurant filters
class RestaurantFiltersSheet extends StatefulWidget {
  const RestaurantFiltersSheet({
    super.key,
    this.selectedCuisine,
    this.minRating,
    this.maxPrepTime,
    this.openNowOnly = false,
    this.sortBy = RestaurantSortBy.popularity,
    required this.onApply,
  });

  final CuisineType? selectedCuisine;
  final double? minRating;
  final int? maxPrepTime;
  final bool openNowOnly;
  final RestaurantSortBy sortBy;
  final void Function(
    CuisineType? cuisine,
    double? rating,
    int? prepTime,
    bool openNow,
    RestaurantSortBy sortBy,
  ) onApply;

  @override
  State<RestaurantFiltersSheet> createState() => _RestaurantFiltersSheetState();
}

class _RestaurantFiltersSheetState extends State<RestaurantFiltersSheet> {
  late CuisineType? _selectedCuisine;
  late double? _minRating;
  late int? _maxPrepTime;
  late bool _openNowOnly;
  late RestaurantSortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _selectedCuisine = widget.selectedCuisine;
    _minRating = widget.minRating;
    _maxPrepTime = widget.maxPrepTime;
    _openNowOnly = widget.openNowOnly;
    _sortBy = widget.sortBy;
  }

  void _clearAll() {
    setState(() {
      _selectedCuisine = null;
      _minRating = null;
      _maxPrepTime = null;
      _openNowOnly = false;
      _sortBy = RestaurantSortBy.popularity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'Reinitialiser',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'Filtres',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Fermer',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filters content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Cuisine type
                    _FilterSection(
                      title: 'Type de cuisine',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: CuisineType.values.map((cuisine) {
                          final isSelected = _selectedCuisine == cuisine;
                          return _SelectableChip(
                            label: '${cuisine.icon} ${cuisine.label}',
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCuisine =
                                    isSelected ? null : cuisine;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Rating
                    _FilterSection(
                      title: 'Note minimale',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [3.0, 3.5, 4.0, 4.5].map((rating) {
                          final isSelected = _minRating == rating;
                          return _SelectableChip(
                            label: '$rating+',
                            icon: Icons.star,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _minRating = isSelected ? null : rating;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Prep time
                    _FilterSection(
                      title: 'Temps de preparation max',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [15, 20, 30, 45].map((time) {
                          final isSelected = _maxPrepTime == time;
                          return _SelectableChip(
                            label: '$time min',
                            icon: Icons.access_time,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _maxPrepTime = isSelected ? null : time;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Open now
                    _FilterSection(
                      title: 'Disponibilite',
                      child: _SelectableChip(
                        label: 'Ouvert maintenant',
                        icon: Icons.schedule,
                        isSelected: _openNowOnly,
                        onTap: () {
                          setState(() {
                            _openNowOnly = !_openNowOnly;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Sort by
                    _FilterSection(
                      title: 'Trier par',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: RestaurantSortBy.values.map((sort) {
                          final isSelected = _sortBy == sort;
                          return _SelectableChip(
                            label: sort.label,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _sortBy = sort;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _selectedCuisine,
                          _minRating,
                          _maxPrepTime,
                          _openNowOnly,
                          _sortBy,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Appliquer les filtres',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
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
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
