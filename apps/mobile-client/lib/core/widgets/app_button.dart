import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Button variants
enum AppButtonVariant { primary, secondary, outline, text }

/// Button sizes
enum AppButtonSize { small, medium, large }

/// Custom application button widget
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.width,
    this.borderRadius,
  });

  /// Button text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button variant
  final AppButtonVariant variant;

  /// Button size
  final AppButtonSize size;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Whether the button is disabled
  final bool isDisabled;

  /// Optional icon
  final IconData? icon;

  /// Icon position (left or right)
  final IconPosition iconPosition;

  /// Optional fixed width
  final double? width;

  /// Custom border radius
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;

    return SizedBox(
      width: width ?? double.infinity,
      height: _getHeight(),
      child: _buildButton(effectiveOnPressed),
    );
  }

  Widget _buildButton(VoidCallback? onPressed) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimaryButton(onPressed);
      case AppButtonVariant.secondary:
        return _buildSecondaryButton(onPressed);
      case AppButtonVariant.outline:
        return _buildOutlineButton(onPressed);
      case AppButtonVariant.text:
        return _buildTextButton(onPressed);
    }
  }

  Widget _buildPrimaryButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        ),
        textStyle: _getTextStyle(),
        minimumSize: Size.zero,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildSecondaryButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        ),
        textStyle: _getTextStyle(),
        minimumSize: Size.zero,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildOutlineButton(VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        ),
        side: BorderSide(
          color: isDisabled ? AppColors.grey300 : AppColors.primary,
        ),
        textStyle: _getTextStyle(),
        minimumSize: Size.zero,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildTextButton(VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: _getPadding(),
        textStyle: _getTextStyle(),
        minimumSize: Size.zero,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.outline || variant == AppButtonVariant.text
                ? AppColors.primary
                : AppColors.white,
          ),
        ),
      );
    }

    if (icon == null) {
      return Text(text);
    }

    final iconWidget = Icon(icon, size: _getIconSize());
    final textWidget = Text(text);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconPosition == IconPosition.left
          ? [
              iconWidget,
              const SizedBox(width: AppSpacing.xs),
              textWidget,
            ]
          : [
              textWidget,
              const SizedBox(width: AppSpacing.xs),
              iconWidget,
            ],
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall;
      case AppButtonSize.medium:
        return AppTypography.buttonMedium;
      case AppButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }
}

/// Icon position in button
enum IconPosition { left, right }
