import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Categories section with icons
class CategoriesSection extends StatelessWidget {
  const CategoriesSection({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  final List<ProviderCategory> categories;
  final void Function(ProviderCategory category)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryItem(
              category: category,
              onTap: () => onCategoryTap?.call(category),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    this.onTap,
  });

  final ProviderCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCategoryColor(category.providerType)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                _getCategoryIcon(category.providerType),
                color: _getCategoryColor(category.providerType),
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.name,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return Icons.restaurant;
      case ProviderType.gasDepot:
        return Icons.local_fire_department;
      case ProviderType.grocery:
        return Icons.local_grocery_store;
      case ProviderType.pharmacy:
        return Icons.local_pharmacy;
      case ProviderType.pressing:
        return Icons.dry_cleaning;
      case ProviderType.artisan:
        return Icons.handyman;
    }
  }

  Color _getCategoryColor(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return AppColors.primary;
      case ProviderType.gasDepot:
        return AppColors.warning;
      case ProviderType.grocery:
        return AppColors.success;
      case ProviderType.pharmacy:
        return AppColors.info;
      case ProviderType.pressing:
        return AppColors.secondary;
      case ProviderType.artisan:
        return AppColors.primaryDark;
    }
  }
}
