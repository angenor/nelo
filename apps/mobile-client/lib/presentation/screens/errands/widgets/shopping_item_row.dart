import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// A single display row for a shopping item (article + quantity + delete)
/// Tapping the row opens the quantity editor
class ShoppingItemRow extends StatelessWidget {
  const ShoppingItemRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final ErrandsItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Article name
            Expanded(
              child: Text(
                item.name,
                style: AppTypography.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Quantity/Price display or "Ajouter" hint
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: item.hasQuantity
                      ? (item.unit == ArticleUnit.fcfa
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.grey100)
                      : AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: item.hasQuantity
                      ? null
                      : Border.all(
                          color: AppColors.grey300,
                          style: BorderStyle.solid,
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.hasQuantity) ...[
                      Text(
                        item.formattedQuantity,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: item.unit == ArticleUnit.fcfa
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: item.unit == ArticleUnit.fcfa
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ] else ...[
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Qté/Prix',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            // Delete button
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.error,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Supprimer',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
