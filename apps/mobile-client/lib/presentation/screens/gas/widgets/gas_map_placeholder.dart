import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Placeholder for Google Maps - will be replaced with real map
class GasMapPlaceholder extends StatelessWidget {
  const GasMapPlaceholder({
    super.key,
    required this.depots,
    required this.selectedDepot,
    required this.deliveryAddress,
    required this.onDepotSelected,
  });

  final List<Provider> depots;
  final Provider? selectedDepot;
  final Map<String, dynamic>? deliveryAddress;
  final ValueChanged<Provider> onDepotSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      child: Stack(
        children: [
          // Map background placeholder
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridPainter(),
            ),
          ),

          // City label
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Tiassalé',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.grey300,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),

          // Depot markers
          ...depots.asMap().entries.map((entry) {
            final index = entry.key;
            final depot = entry.value;
            final isSelected = depot.id == selectedDepot?.id;

            // Position markers in a pattern
            final top = 150.0 + (index * 60);
            final left = 50.0 + (index % 2 == 0 ? 100 : 200);

            return Positioned(
              top: top,
              left: left,
              child: GestureDetector(
                onTap: () => onDepotSelected(depot),
                child: _DepotMarker(
                  depot: depot,
                  isSelected: isSelected,
                ),
              ),
            );
          }),

          // Delivery address marker
          if (deliveryAddress != null)
            Positioned(
              top: 280,
              right: 80,
              child: _AddressMarker(address: deliveryAddress!),
            ),

          // Legend
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.5 + 20,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Dépôt sélectionné',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.grey400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Autres dépôts',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Adresse de livraison',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepotMarker extends StatelessWidget {
  const _DepotMarker({
    required this.depot,
    required this.isSelected,
  });

  final Provider depot;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: isSelected
                ? null
                : Border.all(color: AppColors.grey300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                depot.name.length > 15
                    ? '${depot.name.substring(0, 15)}...'
                    : depot.name,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        // Pin
        Container(
          width: 2,
          height: 10,
          color: isSelected ? AppColors.primary : AppColors.grey400,
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.grey400,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _AddressMarker extends StatelessWidget {
  const _AddressMarker({required this.address});

  final Map<String, dynamic> address;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home,
                size: 16,
                color: AppColors.white,
              ),
              const SizedBox(width: 4),
              Text(
                address['label'] as String,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Pin
        Container(
          width: 2,
          height: 10,
          color: AppColors.success,
        ),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

/// Painter for map grid background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey200
      ..strokeWidth = 0.5;

    // Draw grid lines
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
