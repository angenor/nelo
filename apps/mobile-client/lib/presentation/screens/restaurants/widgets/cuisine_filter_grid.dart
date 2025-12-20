import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Visual cuisine filter grid with images
class CuisineFilterGrid extends StatelessWidget {
  const CuisineFilterGrid({
    super.key,
    this.selectedCuisine,
    required this.onCuisineSelected,
  });

  final CuisineType? selectedCuisine;
  final ValueChanged<CuisineType?> onCuisineSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: CuisineType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final cuisine = CuisineType.values[index];
          final isSelected = selectedCuisine == cuisine;

          return _CuisineFilterItem(
            cuisine: cuisine,
            isSelected: isSelected,
            onTap: () {
              onCuisineSelected(isSelected ? null : cuisine);
            },
          );
        },
      ),
    );
  }
}

class _CuisineFilterItem extends StatelessWidget {
  const _CuisineFilterItem({
    required this.cuisine,
    required this.isSelected,
    required this.onTap,
  });

  final CuisineType cuisine;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular image
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipOval(
              child: Image.network(
                cuisine.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.grey100,
                  child: Center(
                    child: Text(
                      cuisine.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Label
          Text(
            cuisine.label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
