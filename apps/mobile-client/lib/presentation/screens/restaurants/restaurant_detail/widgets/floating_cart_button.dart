import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';

/// Floating cart button showing item count and total
class FloatingCartButton extends StatelessWidget {
  const FloatingCartButton({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onPressed,
  });

  final int itemCount;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '$itemCount',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Cart icon and text
                const Icon(
                  Icons.shopping_cart,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Voir le panier',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Separator
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.white.withValues(alpha: 0.3),
                ),

                const SizedBox(width: AppSpacing.md),

                // Total
                Text(
                  '${_formatPrice(total)}F',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    }
    return price.toString();
  }
}
