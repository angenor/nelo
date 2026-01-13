import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/parcel_destination.dart';
import '../../gas/widgets/address_picker_sheet.dart';
import 'destination_input_tile.dart';

/// Widget showing a list of delivery destinations with add/remove functionality
class DestinationListWidget extends StatelessWidget {
  const DestinationListWidget({
    super.key,
    required this.destinations,
    required this.savedAddresses,
    required this.onDestinationChanged,
    required this.onDestinationDelete,
    required this.onAddDestination,
    this.maxDestinations = 5,
  });

  /// List of destinations
  final List<ParcelDestination> destinations;

  /// List of saved addresses for picker
  final List<Map<String, dynamic>> savedAddresses;

  /// Called when a destination address is changed
  final void Function(int index, Map<String, dynamic> address) onDestinationChanged;

  /// Called when a destination should be deleted
  final void Function(int index) onDestinationDelete;

  /// Called when a new destination is added with an address
  final void Function(Map<String, dynamic> address) onAddDestination;

  /// Maximum number of destinations allowed
  final int maxDestinations;

  void _openAddressPicker(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => AddressPickerSheet(
            savedAddresses: savedAddresses,
            onAddressSelected: (selectedAddress) {
              // AddressPickerSheet already pops itself
              onDestinationChanged(index, selectedAddress);
            },
          ),
        ),
      ),
    );
  }

  void _openAddressPickerForNewDestination(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => AddressPickerSheet(
            savedAddresses: savedAddresses,
            onAddressSelected: (selectedAddress) {
              // AddressPickerSheet already pops itself
              onAddDestination(selectedAddress);
            },
          ),
        ),
      ),
    );
  }

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
            onTap: () => _openAddressPicker(context, index),
            onDelete: () => onDestinationDelete(index),
            canDelete: destinations.length > 1,
          ),
        ),

        // Add destination button
        if (canAddMore) ...[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => _openAddressPickerForNewDestination(context),
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
