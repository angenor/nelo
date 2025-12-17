import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Loading indicator widget
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  });

  /// Size of the indicator
  final double size;

  /// Color of the indicator
  final Color? color;

  /// Stroke width
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
  });

  /// Optional loading message
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
