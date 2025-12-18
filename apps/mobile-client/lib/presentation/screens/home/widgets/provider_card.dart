import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Card widget for displaying a provider (restaurant, etc.)
class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.provider,
    this.onTap,
    this.width = 200,
  });

  final Provider provider;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: provider.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: provider.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.grey200,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.grey200,
                              child: const Icon(Icons.restaurant),
                            ),
                          )
                        : Container(
                            color: AppColors.grey200,
                            child: const Icon(Icons.restaurant, size: 40),
                          ),
                  ),
                  // Open/Closed badge
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isOpen ? Colors.green : Colors.red,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        provider.isOpen ? 'Ouvert' : 'Fermé',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    provider.name,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Type
                  Text(
                    _getProviderTypeLabel(provider.type),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Rating and delivery time
                  Row(
                    children: [
                      // Rating
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        provider.ratingText,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${provider.ratingCount})',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // Delivery time
                      const Icon(
                        Icons.access_time,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        provider.deliveryTimeText,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProviderTypeLabel(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return 'Restaurant';
      case ProviderType.gasDepot:
        return 'Dépôt de gaz';
      case ProviderType.grocery:
        return 'Épicerie';
      case ProviderType.pharmacy:
        return 'Pharmacie';
      case ProviderType.pressing:
        return 'Pressing';
      case ProviderType.artisan:
        return 'Artisan';
    }
  }
}

/// Compact provider card for lists
class ProviderListTile extends StatelessWidget {
  const ProviderListTile({
    super.key,
    required this.provider,
    this.onTap,
  });

  final Provider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: 60,
                height: 60,
                child: provider.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: provider.logoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.grey200,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.grey200,
                          child: Icon(
                            _getProviderIcon(provider.type),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.grey200,
                        child: Icon(
                          _getProviderIcon(provider.type),
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.name,
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: provider.isOpen ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getProviderTypeLabel(provider.type),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        provider.ratingText,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (provider.distanceKm != null) ...[
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          provider.distanceText,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(ProviderType type) {
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

  String _getProviderTypeLabel(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return 'Restaurant';
      case ProviderType.gasDepot:
        return 'Dépôt de gaz';
      case ProviderType.grocery:
        return 'Épicerie';
      case ProviderType.pharmacy:
        return 'Pharmacie';
      case ProviderType.pressing:
        return 'Pressing';
      case ProviderType.artisan:
        return 'Artisan';
    }
  }
}
