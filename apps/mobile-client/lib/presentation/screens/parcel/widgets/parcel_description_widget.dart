import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Widget for entering parcel description or recording a voice note
class ParcelDescriptionWidget extends StatelessWidget {
  const ParcelDescriptionWidget({
    super.key,
    required this.description,
    required this.onDescriptionChanged,
    required this.isRecording,
    required this.hasRecording,
    this.recordingDuration = Duration.zero,
    required this.onVoiceRecordTap,
    required this.onVoiceRecordDelete,
    required this.onVoicePlayTap,
    this.isPlaying = false,
    required this.onAddPhotoTap,
    this.photoCount = 0,
  });

  /// Text description of the parcel
  final String description;

  /// Called when description text changes
  final ValueChanged<String> onDescriptionChanged;

  /// Whether currently recording
  final bool isRecording;

  /// Whether a recording exists
  final bool hasRecording;

  /// Duration of the recording
  final Duration recordingDuration;

  /// Called when record button is tapped
  final VoidCallback onVoiceRecordTap;

  /// Called when delete recording button is pressed
  final VoidCallback onVoiceRecordDelete;

  /// Called when play button is pressed
  final VoidCallback onVoicePlayTap;

  /// Whether the recording is playing
  final bool isPlaying;

  /// Called when add photo button is tapped
  final VoidCallback onAddPhotoTap;

  /// Number of photos added
  final int photoCount;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Description du colis (optionnel)',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Description text field with mic button
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Column(
            children: [
              TextField(
                onChanged: onDescriptionChanged,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: Enveloppe, petit carton...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                ),
                style: AppTypography.bodyMedium,
              ),

              // Bottom row with mic button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Voice recording indicator or button
                    if (hasRecording && !isRecording) ...[
                      // Compact playback controls
                      GestureDetector(
                        onTap: onVoicePlayTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(recordingDuration),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: onVoiceRecordDelete,
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else if (isRecording) ...[
                      // Recording indicator
                      GestureDetector(
                        onTap: onVoiceRecordTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stop,
                                size: 14,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(recordingDuration),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Photo button with count badge
                    GestureDetector(
                      onTap: onAddPhotoTap,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: photoCount > 0
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.grey100,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              photoCount > 0
                                  ? Icons.photo_library
                                  : Icons.add_photo_alternate_outlined,
                              size: 20,
                              color: photoCount > 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            if (photoCount > 0)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$photoCount',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    // Mic button (only show when not recording and no recording exists)
                    if (!isRecording && !hasRecording)
                      GestureDetector(
                        onTap: onVoiceRecordTap,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_none,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
