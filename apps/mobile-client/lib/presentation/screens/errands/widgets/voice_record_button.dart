import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Discrete voice recording button for errands
/// Compact circular button (48x48) with mic icon
class VoiceRecordButton extends StatefulWidget {
  const VoiceRecordButton({
    super.key,
    required this.isRecording,
    required this.hasRecording,
    required this.onTap,
    required this.onDelete,
  });

  /// Whether currently recording
  final bool isRecording;

  /// Whether a recording exists
  final bool hasRecording;

  /// Called when button is tapped (start/stop recording)
  final VoidCallback onTap;

  /// Called to delete existing recording
  final VoidCallback onDelete;

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.hasRecording && !widget.isRecording
          ? _showDeleteDialog
          : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.isRecording ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.isRecording
                ? AppColors.error
                : AppColors.grey100,
            shape: BoxShape.circle,
            border: widget.hasRecording && !widget.isRecording
                ? Border.all(
                    color: AppColors.primary,
                    width: 2,
                  )
                : null,
            boxShadow: widget.isRecording
                ? [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: widget.isRecording
                    ? AppColors.white
                    : (widget.hasRecording
                        ? AppColors.primary
                        : AppColors.textSecondary),
                size: 24,
              ),
              // Recording indicator badge
              if (widget.hasRecording && !widget.isRecording)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
