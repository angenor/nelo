import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Filter chips displayed below search bar
class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.filter,
    required this.onFilterTap,
    this.onCategoryRemove,
    this.onOpenNowToggle,
  });

  final SearchFilter filter;
  final VoidCallback onFilterTap;
  final VoidCallback? onCategoryRemove;
  final VoidCallback? onOpenNowToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            // Filter button
            _FilterButton(
              onTap: onFilterTap,
              hasActiveFilters: filter.hasActiveFilters,
              filterCount: filter.activeFilterCount,
            ),
            const SizedBox(width: AppSpacing.xs),

            // Category chip (if selected)
            if (filter.categoryType != null) ...[
              _FilterChip(
                label: _getCategoryLabel(filter.categoryType!),
                isSelected: true,
                onTap: onCategoryRemove,
                showClose: true,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // Open now toggle
            _FilterChip(
              label: 'Ouvert',
              isSelected: filter.isOpenNow == true,
              onTap: onOpenNowToggle,
              icon: Icons.access_time,
            ),
            const SizedBox(width: AppSpacing.xs),

            // Sort chip
            _FilterChip(
              label: filter.sortBy.label,
              isSelected: filter.sortBy != SearchSortBy.relevance,
              onTap: onFilterTap,
              icon: Icons.sort,
            ),
          ],
        ),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onTap,
    required this.hasActiveFilters,
    required this.filterCount,
  });

  final VoidCallback onTap;
  final bool hasActiveFilters;
  final int filterCount;

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
          color: hasActiveFilters ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: hasActiveFilters ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: hasActiveFilters ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Filtres',
              style: AppTypography.labelMedium.copyWith(
                color: hasActiveFilters ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (filterCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasActiveFilters ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$filterCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: hasActiveFilters ? AppColors.primary : Colors.white,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.onTap,
    this.showClose = false,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showClose;
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
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
            if (showClose) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
