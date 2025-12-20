import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Bottom sheet for search filters
class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  final SearchFilter currentFilter;
  final ValueChanged<SearchFilter> onApply;

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
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
        initialChildSize: 0.7,
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
                      onPressed: () {
                        setState(() {
                          _filter = _filter.clearAll();
                        });
                      },
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
                    // Categories
                    _FilterSection(
                      title: 'Categorie',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: ProviderType.values.map((type) {
                          final isSelected = _filter.categoryType == type;
                          return _SelectableChip(
                            label: _getCategoryLabel(type),
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _filter = _filter.copyWith(
                                  categoryType: isSelected ? null : type,
                                  clearCategory: isSelected,
                                );
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Distance
                    _FilterSection(
                      title: 'Distance maximale',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: DistanceOptions.values.map((distance) {
                          final isSelected = _filter.maxDistance == distance;
                          return _SelectableChip(
                            label: DistanceOptions.label(distance),
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _filter = _filter.copyWith(
                                  maxDistance: isSelected ? null : distance,
                                  clearDistance: isSelected,
                                );
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
                        children: RatingOptions.values.map((rating) {
                          final isSelected = _filter.minRating == rating;
                          return _SelectableChip(
                            label: RatingOptions.label(rating),
                            isSelected: isSelected,
                            icon: Icons.star,
                            onTap: () {
                              setState(() {
                                _filter = _filter.copyWith(
                                  minRating: isSelected ? null : rating,
                                  clearRating: isSelected,
                                );
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
                        isSelected: _filter.isOpenNow == true,
                        icon: Icons.access_time,
                        onTap: () {
                          setState(() {
                            _filter = _filter.copyWith(
                              isOpenNow: _filter.isOpenNow == true ? null : true,
                              clearOpenNow: _filter.isOpenNow == true,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Sort
                    _FilterSection(
                      title: 'Trier par',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: SearchSortBy.values.map((sortBy) {
                          final isSelected = _filter.sortBy == sortBy;
                          return _SelectableChip(
                            label: sortBy.label,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _filter = _filter.copyWith(sortBy: sortBy);
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
                      onPressed: () => widget.onApply(_filter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
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

  String _getCategoryLabel(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return 'Restaurant';
      case ProviderType.gasDepot:
        return 'Gaz';
      case ProviderType.grocery:
        return 'Epicerie';
      case ProviderType.pharmacy:
        return 'Pharmacie';
      case ProviderType.pressing:
        return 'Pressing';
      case ProviderType.artisan:
        return 'Artisan';
    }
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
