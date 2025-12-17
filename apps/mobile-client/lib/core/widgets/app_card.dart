import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Custom application card widget
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.onLongPress,
  });

  /// Card content
  final Widget child;

  /// Card padding
  final EdgeInsets? padding;

  /// Card margin
  final EdgeInsets? margin;

  /// Border radius
  final double? borderRadius;

  /// Card elevation
  final double? elevation;

  /// Card background color
  final Color? color;

  /// Border color
  final Color? borderColor;

  /// Border width
  final double? borderWidth;

  /// Tap callback
  final VoidCallback? onTap;

  /// Long press callback
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation!),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

/// Card with image header
class AppImageCard extends StatelessWidget {
  const AppImageCard({
    super.key,
    required this.imageUrl,
    required this.child,
    this.imageHeight = 150,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.placeholder,
    this.errorWidget,
  });

  /// Image URL
  final String imageUrl;

  /// Card content below image
  final Widget child;

  /// Image height
  final double imageHeight;

  /// Content padding
  final EdgeInsets? padding;

  /// Card margin
  final EdgeInsets? margin;

  /// Border radius
  final double? borderRadius;

  /// Tap callback
  final VoidCallback? onTap;

  /// Placeholder widget while loading
  final Widget? placeholder;

  /// Error widget if image fails to load
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppSpacing.radiusMd;

    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(effectiveBorderRadius),
            ),
            child: Image.network(
              imageUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder ??
                    Container(
                      height: imageHeight,
                      color: AppColors.grey200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
              },
              errorBuilder: (context, error, stackTrace) {
                return errorWidget ??
                    Container(
                      height: imageHeight,
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.grey400,
                          size: 48,
                        ),
                      ),
                    );
              },
            ),
          ),
          Padding(
            padding: padding ?? AppSpacing.paddingMd,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
