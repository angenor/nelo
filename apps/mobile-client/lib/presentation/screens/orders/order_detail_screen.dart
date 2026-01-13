import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';

/// Order detail screen showing complete order information
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('Commande ${order.orderNumber}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header card
            _buildStatusCard(),

            const SizedBox(height: AppSpacing.lg),

            // Order summary
            _buildSection(
              title: 'Résumé de la commande',
              icon: Icons.receipt_long,
              child: _buildOrderSummary(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Delivery address
            if (order.deliveryAddress != null)
              _buildSection(
                title: 'Adresse de livraison',
                icon: Icons.location_on,
                child: _buildAddressCard(
                  icon: Icons.home,
                  label: 'Destination',
                  address: order.deliveryAddress!,
                ),
              ),

            if (order.pickupAddress != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildSection(
                title: 'Adresse de récupération',
                icon: Icons.my_location,
                child: _buildAddressCard(
                  icon: Icons.storefront,
                  label: 'Point de départ',
                  address: order.pickupAddress!,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Status timeline
            _buildSection(
              title: 'Historique',
              icon: Icons.history,
              child: _buildTimeline(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Payment info
            _buildSection(
              title: 'Paiement',
              icon: Icons.payment,
              child: _buildPaymentInfo(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Actions
            if (order.status.isCompleted) _buildReorderButton(context),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: order.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: order.status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: order.status.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              order.status.icon,
              color: order.status.color,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: order.status.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.formattedDate,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: order.serviceType.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  order.serviceType.icon,
                  size: 16,
                  color: order.serviceType.color,
                ),
                const SizedBox(width: 4),
                Text(
                  order.serviceType.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: order.serviceType.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
        children: [
          // Provider/service info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: order.serviceType.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: order.providerLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Image.network(
                          order.providerLogoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            order.serviceType.icon,
                            color: order.serviceType.color,
                          ),
                        ),
                      )
                    : Icon(
                        order.serviceType.icon,
                        color: order.serviceType.color,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.providerName ?? order.serviceType.label,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.itemsSummary != null)
                      Text(
                        order.itemsSummary!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: AppSpacing.xl),

          // Price breakdown
          _buildPriceRow('Sous-total', order.totalAmount - order.deliveryFee + order.discount),
          if (order.deliveryFee > 0)
            _buildPriceRow('Frais de livraison', order.deliveryFee),
          if (order.discount > 0)
            _buildPriceRow('Réduction', -order.discount, isDiscount: true),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                order.formattedTotal,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    final formattedAmount = amount.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            isDiscount ? '-$formattedAmount FCFA' : '$formattedAmount FCFA',
            style: AppTypography.bodyMedium.copyWith(
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required IconData icon,
    required String label,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  address,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (order.statusHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Text(
          'Aucun historique disponible',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: order.statusHistory.reversed.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final statusEntry = entry.value;
          final isFirst = index == 0;
          final isLast = index == order.statusHistory.length - 1;

          return _buildTimelineItem(
            status: statusEntry.status,
            timestamp: statusEntry.timestamp,
            note: statusEntry.note,
            isFirst: isFirst,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineItem({
    required OrderStatus status,
    required DateTime timestamp,
    String? note,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isFirst ? status.color : AppColors.grey300,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.grey200,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Status info
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        status.label,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                          color: isFirst ? status.color : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final methodLabel = _getPaymentMethodLabel(order.paymentMethod);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPaymentMethodIcon(order.paymentMethod),
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  methodLabel,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Paiement effectué',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String? method) {
    switch (method) {
      case 'wallet':
        return 'Portefeuille NELO';
      case 'wave':
        return 'Wave';
      case 'orangeMoney':
        return 'Orange Money';
      case 'mtnMoney':
        return 'MTN Money';
      case 'cash':
        return 'Espèces';
      default:
        return 'Paiement';
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'wave':
      case 'orangeMoney':
      case 'mtnMoney':
        return Icons.phone_android;
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.payment;
    }
  }

  Widget _buildReorderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Navigate to the appropriate service
          String route;
          switch (order.serviceType) {
            case OrderServiceType.restaurant:
              route = '/restaurants';
              break;
            case OrderServiceType.gas:
              route = '/gas';
              break;
            case OrderServiceType.errands:
              route = '/errands';
              break;
            case OrderServiceType.parcel:
              route = '/parcel';
              break;
          }
          context.push(route);
        },
        icon: const Icon(Icons.replay),
        label: const Text('Commander à nouveau'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}
