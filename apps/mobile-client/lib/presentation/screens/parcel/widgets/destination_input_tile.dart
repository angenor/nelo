import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/parcel_destination.dart';

/// A single destination input tile for the parcel delivery form
class DestinationInputTile extends StatelessWidget {
  const DestinationInputTile({
    super.key,
    required this.index,
    required this.destination,
    required this.onTap,
    required this.onDelete,
    this.canDelete = true,
  });

  /// Index of this destination (0-based, displayed as B1, B2, etc.)
  final int index;

  /// The destination data
  final ParcelDestination destination;

  /// Called when the tile is tapped to select address
  final VoidCallback onTap;

  /// Called when delete button is pressed
  final VoidCallback onDelete;

  /// Whether the delete button should be shown
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final hasAddress = destination.address != null && destination.address!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasAddress ? AppColors.info : AppColors.grey300,
          width: hasAddress ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // Destination marker badge (B1, B2, etc.)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    'B${index + 1}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Address text or placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAddress
                          ? destination.address!
                          : 'Ajouter une destination',
                      style: hasAddress
                          ? AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            )
                          : AppTypography.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (destination.contactName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        destination.contactName!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Delete button
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.grey500,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
