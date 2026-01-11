import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Mock voice player widget for listening to recorded voice notes
/// Simulates audio playback with animated progress
class VoicePlayerWidget extends StatefulWidget {
  const VoicePlayerWidget({
    super.key,
    required this.recordingUrl,
    required this.onDelete,
  });

  /// URL of the recording (mock)
  final String recordingUrl;

  /// Called when delete is requested
  final VoidCallback onDelete;

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isPlaying = false;

  // Mock duration in seconds
  static const int _mockDuration = 12;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _mockDuration),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isPlaying = false;
        });
        _progressController.reset();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _progressController.forward();
    } else {
      _progressController.stop();
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'enregistrement ?'),
        content: const Text(
          'Voulez-vous supprimer la note vocale enregistrée ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Progress bar and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.grey300,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _progressController.value,
                        onChanged: (value) {
                          _progressController.value = value;
                        },
                        onChangeEnd: (value) {
                          if (_isPlaying) {
                            _progressController.forward();
                          }
                        },
                      ),
                    );
                  },
                ),

                // Time display
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final currentSeconds =
                          (_progressController.value * _mockDuration).round();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(currentSeconds),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            _formatDuration(_mockDuration),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Delete button
          IconButton(
            onPressed: _showDeleteDialog,
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}
