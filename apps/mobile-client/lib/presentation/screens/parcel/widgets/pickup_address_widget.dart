import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../gas/widgets/address_picker_sheet.dart';

/// Widget for selecting the pickup address
class PickupAddressWidget extends StatelessWidget {
  const PickupAddressWidget({
    super.key,
    required this.address,
    required this.savedAddresses,
    required this.onAddressChanged,
    required this.onUseMyLocation,
    this.isLoadingLocation = false,
  });

  /// Current pickup address (null if not selected)
  final Map<String, dynamic>? address;

  /// List of saved addresses for picker
  final List<Map<String, dynamic>> savedAddresses;

  /// Called when address is selected/changed
  final ValueChanged<Map<String, dynamic>> onAddressChanged;

  /// Called when "Use my location" is pressed
  final VoidCallback onUseMyLocation;

  /// Whether location is being fetched
  final bool isLoadingLocation;

  void _openAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => AddressPickerSheet(
            savedAddresses: savedAddresses,
            onAddressSelected: (selectedAddress) {
              // AddressPickerSheet already pops itself
              onAddressChanged(selectedAddress);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null && address!['address'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Point de récupération',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Address card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: hasAddress ? AppColors.primary : AppColors.grey300,
              width: hasAddress ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Address row
              InkWell(
                onTap: () => _openAddressPicker(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: hasAddress ? AppColors.primary : AppColors.grey400,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          hasAddress
                              ? address!['address'] as String
                              : 'Entrez l\'adresse de récupération',
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
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.grey400,
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              const Divider(height: 1, color: AppColors.grey200),

              // Use my location button
              InkWell(
                onTap: isLoadingLocation ? null : onUseMyLocation,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoadingLocation) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Localisation...',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.my_location,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Utiliser ma position',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
