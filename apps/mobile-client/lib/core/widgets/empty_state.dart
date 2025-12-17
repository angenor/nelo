import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_button.dart';

/// Empty state widget for lists and screens
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Optional message
  final String? message;

  /// Optional action button text
  final String? actionText;

  /// Action button callback
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                width: 200,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
