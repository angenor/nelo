import 'package:equatable/equatable.dart';
import 'product.dart';

/// Menu category within a provider (e.g., "Entrées", "Plats", "Boissons")
class MenuCategory extends Equatable {
  const MenuCategory({
    required this.id,
    required this.providerId,
    required this.name,
    this.displayOrder = 0,
    this.isActive = true,
    this.products = const [],
  });

  final String id;
  final String providerId;
  final String name;
  final int displayOrder;
  final bool isActive;
  final List<Product> products;

  @override
  List<Object?> get props => [id, providerId, name];

  /// Create a copy with updated products
  MenuCategory copyWith({
    String? id,
    String? providerId,
    String? name,
    int? displayOrder,
    bool? isActive,
    List<Product>? products,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      products: products ?? this.products,
    );
  }
}
