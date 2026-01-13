import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';

/// Real-time order tracking screen
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map placeholder (full screen)
          _buildMapPlaceholder(),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.order.serviceType.icon,
                        size: 18,
                        color: widget.order.serviceType.color,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.order.orderNumber,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 40), // Balance the back button
              ],
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.25, 0.45, 0.85],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Status header
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildStatusHeader(),
                    ),

                    const Divider(height: 1),

                    // ETA card
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildETACard(),
                    ),

                    // Driver info
                    if (widget.order.driver != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _buildDriverCard(),
                      ),

                    const SizedBox(height: AppSpacing.md),

                    // Timeline
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _buildStatusTimeline(),
                    ),

                    // Confirmation code
                    if (widget.order.confirmationCode != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _buildConfirmationCode(),
                      ),
                    ],

                    // Order summary
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildOrderSummary(),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: Center(
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
              'Carte de suivi',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Position du livreur en temps réel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 100), // Space for bottom sheet
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.order.status.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.order.status.icon,
            color: widget.order.status.color,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.order.status.label,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.order.status.color,
                ),
              ),
              Text(
                _getStatusDescription(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusDescription() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return 'Recherche d\'un livreur...';
      case OrderStatus.confirmed:
        return 'Votre commande est confirmée';
      case OrderStatus.preparing:
        return 'En cours de préparation';
      case OrderStatus.readyForPickup:
        return 'Prête à être récupérée';
      case OrderStatus.pickedUp:
        return 'Le livreur a récupéré votre commande';
      case OrderStatus.inTransit:
        return 'En route vers vous';
      case OrderStatus.delivered:
        return 'Commande livrée';
      case OrderStatus.cancelled:
        return 'Commande annulée';
      case OrderStatus.refunded:
        return 'Commande remboursée';
    }
  }

  Widget _buildETACard() {
    final eta = widget.order.estimatedDeliveryTime;
    final etaText = eta != null
        ? '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final remaining = eta?.difference(DateTime.now());
    final minutesRemaining = remaining?.inMinutes ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.order.serviceType.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: widget.order.serviceType.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: widget.order.serviceType.color,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrivée estimée',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  etaText,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.order.serviceType.color,
                  ),
                ),
              ],
            ),
          ),
          if (minutesRemaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: widget.order.serviceType.color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '~$minutesRemaining min',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    final driver = widget.order.driver!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Driver avatar
              CircleAvatar(
                radius: 28,
                backgroundImage: driver.photoUrl != null
                    ? NetworkImage(driver.photoUrl!)
                    : null,
                backgroundColor: AppColors.grey200,
                child: driver.photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 28,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),

              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (driver.rating != null) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.rating,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            driver.rating!.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (driver.vehicleType != null) ...[
                          Icon(
                            Icons.two_wheeler,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driver.vehicleType!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callDriver(driver.phone),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _messageDriver(driver.phone),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _callDriver(String phone) {
    // TODO: Implement url_launcher for phone calls
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appel vers $phone'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _messageDriver(String phone) {
    // TODO: Implement url_launcher for SMS
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message vers $phone'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.pickedUp,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ];

    final currentIndex = statuses.indexOf(widget.order.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == statuses.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? widget.order.serviceType.color
                            : AppColors.grey200,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: widget.order.serviceType.color,
                                width: 2,
                              )
                            : null,
                      ),
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex
                              ? widget.order.serviceType.color
                              : AppColors.grey200,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCode() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pin,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code de confirmation',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Donnez ce code au livreur',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              widget.order.confirmationCode!,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.order.serviceType.icon,
                size: 20,
                color: widget.order.serviceType.color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.order.providerName ?? widget.order.serviceType.label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                widget.order.formattedTotal,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (widget.order.itemsSummary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.order.itemsSummary!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (widget.order.deliveryAddress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.order.deliveryAddress!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
