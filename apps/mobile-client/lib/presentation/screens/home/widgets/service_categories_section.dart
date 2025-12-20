import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// MVP Services section - 4 main services displayed as large tappable cards
class ServiceCategoriesSection extends StatelessWidget {
  const ServiceCategoriesSection({
    super.key,
    required this.services,
    this.onServiceTap,
  });

  final List<ServiceCategory> services;
  final void Function(ServiceCategory service)? onServiceTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.85,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _ServiceItem(
            service: service,
            onTap: () => onServiceTap?.call(service),
          );
        },
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
    required this.service,
    this.onTap,
  });

  final ServiceCategory service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container - large and tappable
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: service.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: service.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              service.icon,
              color: service.color,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Service name
          Text(
            service.name,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
