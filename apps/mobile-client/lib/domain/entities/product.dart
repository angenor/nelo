import 'package:equatable/equatable.dart';
import 'menu_option.dart';

/// Product entity
class Product extends Equatable {
  const Product({
    required this.id,
    required this.providerId,
    required this.name,
    required this.price,
    this.categoryId,
    this.description,
    this.imageUrl,
    this.compareAtPrice,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.prepTime,
    this.displayOrder = 0,
    this.options = const [],
  });

  final String id;
  final String providerId;
  final String? categoryId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int price;
  final int? compareAtPrice;
  final bool isAvailable;
  final bool isFeatured;
  final bool isVegetarian;
  final bool isSpicy;
  final int? prepTime;
  final int displayOrder;
  final List<MenuOption> options;

  @override
  List<Object?> get props => [id, providerId, name, price];

  /// Format price in FCFA
  String get priceText => '${price}F';

  /// Check if product has discount
  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  /// Format original price
  String? get originalPriceText =>
      hasDiscount ? '${compareAtPrice}F' : null;

  /// Discount percentage
  int? get discountPercentage {
    if (!hasDiscount) return null;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Check if product has options
  bool get hasOptions => options.isNotEmpty;

  /// Check if product has required options
  bool get hasRequiredOptions => options.any((o) => o.isRequired);
}
