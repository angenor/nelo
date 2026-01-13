import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Order status enum matching database schema
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  readyForPickup,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  refunded;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.readyForPickup:
        return 'Prêt à récupérer';
      case OrderStatus.pickedUp:
        return 'Récupérée';
      case OrderStatus.inTransit:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.refunded:
        return 'Remboursée';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFFA000);
      case OrderStatus.confirmed:
        return const Color(0xFF2196F3);
      case OrderStatus.preparing:
        return const Color(0xFF9C27B0);
      case OrderStatus.readyForPickup:
        return const Color(0xFF00BCD4);
      case OrderStatus.pickedUp:
        return const Color(0xFF4CAF50);
      case OrderStatus.inTransit:
        return const Color(0xFF4CAF50);
      case OrderStatus.delivered:
        return const Color(0xFF4CAF50);
      case OrderStatus.cancelled:
        return const Color(0xFFF44336);
      case OrderStatus.refunded:
        return const Color(0xFF607D8B);
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.readyForPickup:
        return Icons.inventory_2;
      case OrderStatus.pickedUp:
        return Icons.directions_bike;
      case OrderStatus.inTransit:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.refunded:
        return Icons.replay;
    }
  }

  bool get isActive => this != OrderStatus.delivered &&
                       this != OrderStatus.cancelled &&
                       this != OrderStatus.refunded;

  bool get isCompleted => this == OrderStatus.delivered;
}

/// Order service type
enum OrderServiceType {
  restaurant,
  gas,
  errands,
  parcel;

  String get label {
    switch (this) {
      case OrderServiceType.restaurant:
        return 'Restaurant';
      case OrderServiceType.gas:
        return 'Gaz';
      case OrderServiceType.errands:
        return 'Courses';
      case OrderServiceType.parcel:
        return 'Colis';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderServiceType.restaurant:
        return Icons.restaurant;
      case OrderServiceType.gas:
        return Icons.local_fire_department;
      case OrderServiceType.errands:
        return Icons.shopping_basket;
      case OrderServiceType.parcel:
        return Icons.local_shipping;
    }
  }

  Color get color {
    switch (this) {
      case OrderServiceType.restaurant:
        return const Color(0xFFFF6B35);
      case OrderServiceType.gas:
        return const Color(0xFFFF9500);
      case OrderServiceType.errands:
        return const Color(0xFF34C759);
      case OrderServiceType.parcel:
        return const Color(0xFF007AFF);
    }
  }
}

/// Order status history entry
class OrderStatusEntry extends Equatable {
  const OrderStatusEntry({
    required this.status,
    required this.timestamp,
    this.note,
  });

  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  @override
  List<Object?> get props => [status, timestamp, note];
}

/// Driver information for delivery
class DeliveryDriver extends Equatable {
  const DeliveryDriver({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.rating,
    this.currentLatitude,
    this.currentLongitude,
  });

  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? rating;
  final double? currentLatitude;
  final double? currentLongitude;

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        photoUrl,
        vehicleType,
        vehiclePlate,
        rating,
        currentLatitude,
        currentLongitude,
      ];
}

/// Order entity
class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.serviceType,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.deliveryFee = 0,
    this.discount = 0,
    this.providerName,
    this.providerLogoUrl,
    this.deliveryAddress,
    this.pickupAddress,
    this.paymentMethod,
    this.statusHistory = const [],
    this.driver,
    this.estimatedDeliveryTime,
    this.confirmationCode,
    this.itemsSummary,
    this.itemsCount = 1,
  });

  final String id;
  final String orderNumber;
  final OrderServiceType serviceType;
  final OrderStatus status;
  final int totalAmount;
  final int deliveryFee;
  final int discount;
  final DateTime createdAt;
  final String? providerName;
  final String? providerLogoUrl;
  final String? deliveryAddress;
  final String? pickupAddress;
  final String? paymentMethod;
  final List<OrderStatusEntry> statusHistory;
  final DeliveryDriver? driver;
  final DateTime? estimatedDeliveryTime;
  final String? confirmationCode;
  final String? itemsSummary;
  final int itemsCount;

  /// Formatted total amount
  String get formattedTotal {
    return '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  /// Formatted date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
      return '${days[createdAt.weekday % 7]} ${createdAt.day}/${createdAt.month}';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        serviceType,
        status,
        totalAmount,
        deliveryFee,
        discount,
        createdAt,
        providerName,
        providerLogoUrl,
        deliveryAddress,
        pickupAddress,
        paymentMethod,
        statusHistory,
        driver,
        estimatedDeliveryTime,
        confirmationCode,
        itemsSummary,
        itemsCount,
      ];
}
