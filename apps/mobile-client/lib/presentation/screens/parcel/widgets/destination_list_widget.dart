import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/parcel_destination.dart';
import 'destination_input_tile.dart';

/// Widget showing a list of delivery destinations with add/remove functionality
class DestinationListWidget extends StatelessWidget {
  const DestinationListWidget({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
    required this.onDestinationDelete,
    required this.onAddDestination,
    this.maxDestinations = 5,
  });

  /// List of destinations
  final List<ParcelDestination> destinations;

  /// Called when a destination tile is tapped
  final void Function(int index) onDestinationTap;

  /// Called when a destination should be deleted
  final void Function(int index) onDestinationDelete;

  /// Called when "Add destination" is pressed
  final VoidCallback onAddDestination;

  /// Maximum number of destinations allowed
  final int maxDestinations;

  @override
  Widget build(BuildContext context) {
    final canAddMore = destinations.length < maxDestinations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(
              Icons.flag,
              size: 20,
              color: AppColors.info,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Destinations de livraison',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Destination tiles
        ...List.generate(
          destinations.length,
          (index) => DestinationInputTile(
            index: index,
            destination: destinations[index],
            onTap: () => onDestinationTap(index),
            onDelete: () => onDestinationDelete(index),
            canDelete: destinations.length > 1,
          ),
        ),

        // Add destination button
        if (canAddMore) ...[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: onAddDestination,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.info,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ajouter une destination',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Max destinations hint
        if (!canAddMore) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Maximum $maxDestinations destinations atteint',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
