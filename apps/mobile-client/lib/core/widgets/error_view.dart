import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_button.dart';

/// Error view widget
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Une erreur est survenue',
    this.message,
    this.onRetry,
    this.retryText = 'Réessayer',
  });

  /// Error title
  final String title;

  /// Error message
  final String? message;

  /// Retry callback
  final VoidCallback? onRetry;

  /// Retry button text
  final String retryText;

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
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
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
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: retryText,
                onPressed: onRetry,
                width: 200,
                size: AppButtonSize.medium,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No internet connection view
class NoInternetView extends StatelessWidget {
  const NoInternetView({
    super.key,
    this.onRetry,
  });

  /// Retry callback
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: 'Pas de connexion internet',
      message: 'Vérifiez votre connexion et réessayez.',
      onRetry: onRetry,
    );
  }
}
