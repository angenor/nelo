import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Home screen header with location and notifications
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.location = 'Tiassalé',
    this.onLocationTap,
    this.onNotificationTap,
  });

  final String location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Location selector
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Livrer à',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                location,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification button
          IconButton(
            onPressed: onNotificationTap,
            icon: Badge(
              smallSize: 8,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
