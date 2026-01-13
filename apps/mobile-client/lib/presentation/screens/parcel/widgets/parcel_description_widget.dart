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
              'Description du colis',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Description text field
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.grey300),
          ),
          child: TextField(
            onChanged: onDescriptionChanged,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Enveloppe, petit carton, documents...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
            style: AppTypography.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Voice note section
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              // Label
              Row(
                children: [
                  const Icon(
                    Icons.mic,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ou enregistrez une note vocale',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Recording controls
              if (hasRecording && !isRecording) ...[
                // Playback controls
                Row(
                  children: [
                    // Play button
                    IconButton(
                      onPressed: onVoicePlayTap,
                      icon: Icon(
                        isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),

                    // Duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note vocale',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(recordingDuration),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    IconButton(
                      onPressed: onVoiceRecordDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Record button
                GestureDetector(
                  onTap: onVoiceRecordTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isRecording ? AppColors.error : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: isRecording ? AppColors.error : AppColors.grey300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          size: 20,
                          color: isRecording ? AppColors.white : AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          isRecording
                              ? 'Arrêter (${_formatDuration(recordingDuration)})'
                              : 'Appuyer pour enregistrer',
                          style: AppTypography.labelMedium.copyWith(
                            color: isRecording ? AppColors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Max duration hint
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Maximum 2 minutes',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
