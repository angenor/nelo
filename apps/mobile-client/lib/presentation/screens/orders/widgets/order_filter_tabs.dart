import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Filter options for orders
enum OrderFilter {
  all,
  active,
  restaurant,
  gas,
  errands,
  parcel;

  String get label {
    switch (this) {
      case OrderFilter.all:
        return 'Toutes';
      case OrderFilter.active:
        return 'En cours';
      case OrderFilter.restaurant:
        return 'Restaurant';
      case OrderFilter.gas:
        return 'Gaz';
      case OrderFilter.errands:
        return 'Courses';
      case OrderFilter.parcel:
        return 'Colis';
    }
  }

  IconData? get icon {
    switch (this) {
      case OrderFilter.all:
        return null;
      case OrderFilter.active:
        return Icons.local_shipping;
      case OrderFilter.restaurant:
        return Icons.restaurant;
      case OrderFilter.gas:
        return Icons.local_fire_department;
      case OrderFilter.errands:
        return Icons.shopping_basket;
      case OrderFilter.parcel:
        return Icons.inventory_2;
    }
  }

  Color? get color {
    switch (this) {
      case OrderFilter.all:
        return null;
      case OrderFilter.active:
        return AppColors.success;
      case OrderFilter.restaurant:
        return const Color(0xFFFF6B35);
      case OrderFilter.gas:
        return const Color(0xFFFF9500);
      case OrderFilter.errands:
        return const Color(0xFF34C759);
      case OrderFilter.parcel:
        return const Color(0xFF007AFF);
    }
  }
}

/// Horizontal scrollable filter tabs for orders
class OrderFilterTabs extends StatelessWidget {
  const OrderFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.activeOrdersCount = 0,
  });

  final OrderFilter selectedFilter;
  final ValueChanged<OrderFilter> onFilterChanged;
  final int activeOrdersCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final filter = OrderFilter.values[index];
          final isSelected = filter == selectedFilter;

          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (filter.color ?? AppColors.primary)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.grey300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.icon != null) ...[
                    Icon(
                      filter.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.white
                          : (filter.color ?? AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filter.label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  // Show badge for active orders
                  if (filter == OrderFilter.active && activeOrdersCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white.withValues(alpha: 0.2)
                            : AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeOrdersCount',
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
