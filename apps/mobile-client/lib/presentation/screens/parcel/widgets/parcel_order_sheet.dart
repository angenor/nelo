import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/parcel_destination.dart';
import 'pickup_address_widget.dart';
import 'destination_list_widget.dart';
import 'parcel_description_widget.dart';
import 'route_summary_card.dart';

/// Bottom sheet containing the parcel order form
class ParcelOrderSheet extends StatelessWidget {
  const ParcelOrderSheet({
    super.key,
    required this.scrollController,
    required this.savedAddresses,
    required this.pickupAddress,
    required this.onPickupAddressChanged,
    required this.onUseMyLocation,
    required this.isLoadingLocation,
    required this.destinations,
    required this.onDestinationChanged,
    required this.onDestinationDelete,
    required this.onAddDestination,
    required this.description,
    required this.onDescriptionChanged,
    required this.isRecording,
    required this.hasRecording,
    required this.recordingDuration,
    required this.onVoiceRecordTap,
    required this.onVoiceRecordDelete,
    required this.onVoicePlayTap,
    required this.isPlaying,
    required this.onAddPhotoTap,
    this.photoCount = 0,
    required this.totalDistanceKm,
    required this.estimatedPrice,
    required this.onSubmit,
    required this.isProcessing,
    required this.canSubmit,
  });

  final ScrollController scrollController;

  // Saved addresses for picker
  final List<Map<String, dynamic>> savedAddresses;

  // Pickup
  final Map<String, dynamic>? pickupAddress;
  final ValueChanged<Map<String, dynamic>> onPickupAddressChanged;
  final VoidCallback onUseMyLocation;
  final bool isLoadingLocation;

  // Destinations
  final List<ParcelDestination> destinations;
  final void Function(int index, Map<String, dynamic> address) onDestinationChanged;
  final void Function(int index) onDestinationDelete;
  final void Function(Map<String, dynamic> address) onAddDestination;

  // Description
  final String description;
  final ValueChanged<String> onDescriptionChanged;

  // Voice recording
  final bool isRecording;
  final bool hasRecording;
  final Duration recordingDuration;
  final VoidCallback onVoiceRecordTap;
  final VoidCallback onVoiceRecordDelete;
  final VoidCallback onVoicePlayTap;
  final bool isPlaying;

  // Photos
  final VoidCallback onAddPhotoTap;
  final int photoCount;

  // Summary
  final double totalDistanceKm;
  final int estimatedPrice;

  // Submit
  final VoidCallback onSubmit;
  final bool isProcessing;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Colis Express',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Pickup address section
                PickupAddressWidget(
                  address: pickupAddress,
                  savedAddresses: savedAddresses,
                  onAddressChanged: onPickupAddressChanged,
                  onUseMyLocation: onUseMyLocation,
                  isLoadingLocation: isLoadingLocation,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Destinations section
                DestinationListWidget(
                  destinations: destinations,
                  savedAddresses: savedAddresses,
                  onDestinationChanged: onDestinationChanged,
                  onDestinationDelete: onDestinationDelete,
                  onAddDestination: onAddDestination,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description section
                ParcelDescriptionWidget(
                  description: description,
                  onDescriptionChanged: onDescriptionChanged,
                  isRecording: isRecording,
                  hasRecording: hasRecording,
                  recordingDuration: recordingDuration,
                  onVoiceRecordTap: onVoiceRecordTap,
                  onVoiceRecordDelete: onVoiceRecordDelete,
                  onVoicePlayTap: onVoicePlayTap,
                  isPlaying: isPlaying,
                  onAddPhotoTap: onAddPhotoTap,
                  photoCount: photoCount,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Route summary
                RouteSummaryCard(
                  totalDistanceKm: totalDistanceKm,
                  estimatedPrice: estimatedPrice,
                  numberOfStops: destinations.where((d) => d.isValid).length,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canSubmit && !isProcessing ? onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grey300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delivery_dining, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Demander un livreur',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Bottom padding for safe area
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
