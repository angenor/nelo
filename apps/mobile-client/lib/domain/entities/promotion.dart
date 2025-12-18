import 'package:equatable/equatable.dart';

/// Promotion type
enum PromotionType {
  percentage,
  fixed,
  freeDelivery,
}

/// Promotion entity
class Promotion extends Equatable {
  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.discountValue,
    this.code,
    this.maxDiscount,
    this.minOrderAmount = 0,
    this.imageUrl,
    this.description,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
  });

  final String id;
  final String? code;
  final String name;
  final String? description;
  final String? imageUrl;
  final PromotionType type;
  final int discountValue;
  final int? maxDiscount;
  final int minOrderAmount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  @override
  List<Object?> get props => [id, code, name, type];

  /// Format discount text
  String get discountText {
    switch (type) {
      case PromotionType.percentage:
        return '-$discountValue%';
      case PromotionType.fixed:
        return '-${discountValue}F';
      case PromotionType.freeDelivery:
        return 'Livraison gratuite';
    }
  }
}
