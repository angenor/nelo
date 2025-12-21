import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../domain/entities/entities.dart';

/// Restaurant info section with hours, address, phone
class RestaurantInfoSection extends StatelessWidget {
  const RestaurantInfoSection({
    super.key,
    required this.restaurant,
    required this.schedules,
  });

  final Provider restaurant;
  final List<ProviderSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.grey200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (restaurant.description != null) ...[
            Text(
              restaurant.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Info chips row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _InfoChip(
                icon: Icons.access_time,
                label: restaurant.deliveryTimeText,
              ),
              if (restaurant.distanceKm != null)
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: restaurant.distanceText,
                ),
              _InfoChip(
                icon: Icons.shopping_bag_outlined,
                label: 'Min. ${restaurant.minOrderAmount}F',
              ),
              if (restaurant.cuisineType != null)
                _InfoChip(
                  icon: Icons.restaurant_menu,
                  label: restaurant.cuisineType!.label,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Contact and address section
          _buildContactSection(),

          const SizedBox(height: AppSpacing.md),

          // Opening hours
          _buildScheduleSection(context),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        // Address
        _InfoRow(
          icon: Icons.location_on,
          iconColor: AppColors.primary,
          title: 'Adresse',
          value: restaurant.addressLine1,
          onTap: () {
            // Open maps
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Phone
        _InfoRow(
          icon: Icons.phone,
          iconColor: AppColors.success,
          title: 'Téléphone',
          value: restaurant.phone,
          onTap: () {
            // Call
          },
        ),

        if (restaurant.whatsapp != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.chat,
            iconColor: const Color(0xFF25D366),
            title: 'WhatsApp',
            value: restaurant.whatsapp!,
            onTap: () {
              // Open WhatsApp
            },
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    final today = DateTime.now().weekday - 1; // 0 = Monday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Horaires',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAllSchedules(context),
              child: Text(
                'Voir tout',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Today's schedule
        if (schedules.isNotEmpty) ...[
          Builder(builder: (context) {
            final todaySchedule = schedules.firstWhere(
              (s) => s.dayOfWeek == today,
              orElse: () => schedules.first,
            );
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Aujourd'hui: ",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    todaySchedule.hoursText,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showAllSchedules(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        final today = DateTime.now().weekday - 1;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: AppSpacing.borderRadiusXxs,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Horaires d\'ouverture',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              ...schedules.map((schedule) {
                final isToday = schedule.dayOfWeek == today;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schedule.dayName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          schedule.hoursText,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: schedule.isClosed
                                ? AppColors.error
                                : isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
