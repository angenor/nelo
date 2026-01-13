import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'widgets/widgets.dart';

/// Orders history screen with filtering capabilities
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderFilter _selectedFilter = OrderFilter.all;
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    // Convert mock data to Order entities
    _allOrders = MockData.orders.map((data) => _mapToOrder(data)).toList();
    _applyFilter();
  }

  Order _mapToOrder(Map<String, dynamic> data) {
    // Map status string to enum
    final statusStr = data['status'] as String;
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => OrderStatus.pending,
    );

    // Map service type string to enum
    final serviceTypeStr = data['serviceType'] as String;
    final serviceType = OrderServiceType.values.firstWhere(
      (s) => s.name == serviceTypeStr,
      orElse: () => OrderServiceType.restaurant,
    );

    // Map driver data if present
    DeliveryDriver? driver;
    if (data['driver'] != null) {
      final driverData = data['driver'] as Map<String, dynamic>;
      driver = DeliveryDriver(
        id: driverData['id'] as String,
        name: driverData['name'] as String,
        phone: driverData['phone'] as String,
        photoUrl: driverData['photoUrl'] as String?,
        vehicleType: driverData['vehicleType'] as String?,
        vehiclePlate: driverData['vehiclePlate'] as String?,
        rating: driverData['rating'] as double?,
        currentLatitude: driverData['currentLatitude'] as double?,
        currentLongitude: driverData['currentLongitude'] as double?,
      );
    }

    // Map status history
    final statusHistoryData = data['statusHistory'] as List<dynamic>? ?? [];
    final statusHistory = statusHistoryData.map((entry) {
      final entryMap = entry as Map<String, dynamic>;
      final entryStatus = OrderStatus.values.firstWhere(
        (s) => s.name == entryMap['status'],
        orElse: () => OrderStatus.pending,
      );
      return OrderStatusEntry(
        status: entryStatus,
        timestamp: entryMap['timestamp'] as DateTime,
        note: entryMap['note'] as String?,
      );
    }).toList();

    return Order(
      id: data['id'] as String,
      orderNumber: data['orderNumber'] as String,
      serviceType: serviceType,
      status: status,
      totalAmount: data['totalAmount'] as int,
      deliveryFee: data['deliveryFee'] as int? ?? 0,
      createdAt: data['createdAt'] as DateTime,
      providerName: data['providerName'] as String?,
      providerLogoUrl: data['providerLogoUrl'] as String?,
      deliveryAddress: data['deliveryAddress'] as String?,
      pickupAddress: data['pickupAddress'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      statusHistory: statusHistory,
      driver: driver,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] as DateTime?,
      confirmationCode: data['confirmationCode'] as String?,
      itemsSummary: data['itemsSummary'] as String?,
      itemsCount: data['itemsCount'] as int? ?? 1,
    );
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case OrderFilter.all:
          _filteredOrders = List.from(_allOrders);
          break;
        case OrderFilter.active:
          _filteredOrders = _allOrders.where((o) => o.status.isActive).toList();
          break;
        case OrderFilter.restaurant:
          _filteredOrders = _allOrders
              .where((o) => o.serviceType == OrderServiceType.restaurant)
              .toList();
          break;
        case OrderFilter.gas:
          _filteredOrders = _allOrders
              .where((o) => o.serviceType == OrderServiceType.gas)
              .toList();
          break;
        case OrderFilter.errands:
          _filteredOrders = _allOrders
              .where((o) => o.serviceType == OrderServiceType.errands)
              .toList();
          break;
        case OrderFilter.parcel:
          _filteredOrders = _allOrders
              .where((o) => o.serviceType == OrderServiceType.parcel)
              .toList();
          break;
      }
    });
  }

  void _onFilterChanged(OrderFilter filter) {
    _selectedFilter = filter;
    _applyFilter();
  }

  void _onOrderTap(Order order) {
    if (order.status.isActive) {
      context.push('/order/${order.id}/tracking', extra: order);
    } else {
      context.push('/order/${order.id}', extra: order);
    }
  }

  int get _activeOrdersCount =>
      _allOrders.where((o) => o.status.isActive).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Mes commandes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: OrderFilterTabs(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
              activeOrdersCount: _activeOrdersCount,
            ),
          ),

          // Orders list
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return OrderCard(
                        order: order,
                        onTap: () => _onOrderTap(order),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case OrderFilter.active:
        message = 'Aucune commande en cours';
        icon = Icons.local_shipping_outlined;
        break;
      case OrderFilter.restaurant:
        message = 'Aucune commande de restaurant';
        icon = Icons.restaurant_outlined;
        break;
      case OrderFilter.gas:
        message = 'Aucune commande de gaz';
        icon = Icons.local_fire_department_outlined;
        break;
      case OrderFilter.errands:
        message = 'Aucune commande de courses';
        icon = Icons.shopping_basket_outlined;
        break;
      case OrderFilter.parcel:
        message = 'Aucune livraison de colis';
        icon = Icons.inventory_2_outlined;
        break;
      default:
        message = 'Aucune commande';
        icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vos commandes apparaîtront ici',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.add),
            label: const Text('Passer une commande'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
