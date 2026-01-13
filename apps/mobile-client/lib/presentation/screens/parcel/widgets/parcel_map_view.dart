import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/parcel_destination.dart';

/// Map view showing pickup and delivery points with route polyline
/// For MVP, this is a placeholder that will be replaced with Google Maps
class ParcelMapView extends StatelessWidget {
  const ParcelMapView({
    super.key,
    required this.pickupAddress,
    required this.destinations,
    this.onPickupTap,
    this.onDestinationTap,
  });

  /// Pickup location data
  final Map<String, dynamic>? pickupAddress;

  /// List of delivery destinations
  final List<ParcelDestination> destinations;

  /// Called when pickup marker is tapped
  final VoidCallback? onPickupTap;

  /// Called when a destination marker is tapped
  final void Function(int index)? onDestinationTap;

  @override
  Widget build(BuildContext context) {
    final hasPickup = pickupAddress != null &&
        pickupAddress!['latitude'] != null &&
        pickupAddress!['longitude'] != null;

    final validDestinations =
        destinations.where((d) => d.isValid).toList();

    return Container(
      color: AppColors.grey100,
      child: Stack(
        children: [
          // Map placeholder background with grid pattern
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),

          // Map placeholder content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Carte du trajet',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (hasPickup || validDestinations.isNotEmpty)
                  Text(
                    '${hasPickup ? 1 : 0} point de départ, ${validDestinations.length} destination(s)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  )
                else
                  Text(
                    'Ajoutez des points pour voir le trajet',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),

          // Route visualization overlay (when points exist)
          if (hasPickup || validDestinations.isNotEmpty)
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _RouteVisualization(
                hasPickup: hasPickup,
                pickupAddress: hasPickup ? pickupAddress!['address'] as String? : null,
                destinations: validDestinations,
              ),
            ),

          // Legend
          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(
                    color: AppColors.primary,
                    label: 'A = Récupération',
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _LegendItem(
                    color: AppColors.info,
                    label: 'B = Livraison',
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

/// Simplified route visualization showing the journey points
class _RouteVisualization extends StatelessWidget {
  const _RouteVisualization({
    required this.hasPickup,
    this.pickupAddress,
    required this.destinations,
  });

  final bool hasPickup;
  final String? pickupAddress;
  final List<ParcelDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pickup point
          if (hasPickup)
            _RoutePoint(
              marker: 'A',
              markerColor: AppColors.primary,
              label: pickupAddress ?? 'Point de récupération',
              isFirst: true,
              isLast: destinations.isEmpty,
            ),

          // Destinations
          ...destinations.asMap().entries.map((entry) {
            final index = entry.key;
            final dest = entry.value;
            return _RoutePoint(
              marker: 'B${index + 1}',
              markerColor: AppColors.info,
              label: dest.address ?? 'Destination ${index + 1}',
              isFirst: !hasPickup && index == 0,
              isLast: index == destinations.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

/// Single point in the route visualization
class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.marker,
    required this.markerColor,
    required this.label,
    this.isFirst = false,
    this.isLast = false,
  });

  final String marker;
  final Color markerColor;
  final String label;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Marker column with connecting line
        SizedBox(
          width: 32,
          child: Column(
            children: [
              // Line above (if not first)
              if (!isFirst)
                Container(
                  width: 2,
                  height: 8,
                  color: AppColors.grey300,
                ),

              // Marker badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: markerColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Center(
                  child: Text(
                    marker,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Line below (if not last)
              if (!isLast)
                Container(
                  width: 2,
                  height: 8,
                  color: AppColors.grey300,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Address label
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: isFirst ? 0 : AppSpacing.xxs,
              bottom: isLast ? 0 : AppSpacing.xxs,
            ),
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for map grid background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey200
      ..strokeWidth = 0.5;

    const gridSize = 30.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
