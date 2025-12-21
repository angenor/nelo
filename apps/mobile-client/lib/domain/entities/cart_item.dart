import 'package:equatable/equatable.dart';
import 'product.dart';

/// Cart item with product and selected options
class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedOptions = const {},
    this.specialInstructions,
  });

  /// Unique identifier for this cart item
  final String id;

  /// The product
  final Product product;

  /// Quantity
  final int quantity;

  /// Selected options (optionId -> List of selected itemIds)
  final Map<String, List<String>> selectedOptions;

  /// Special instructions for this item
  final String? specialInstructions;

  @override
  List<Object?> get props => [id, product.id, quantity, selectedOptions];

  /// Calculate unit price with options
  int get unitPrice {
    int base = product.price;
    int optionsTotal = 0;

    for (final option in product.options) {
      final selectedIds = selectedOptions[option.id] ?? [];
      for (final item in option.items) {
        if (selectedIds.contains(item.id)) {
          optionsTotal += item.priceAdjustment;
        }
      }
    }

    return base + optionsTotal;
  }

  /// Calculate total price for this item
  int get totalPrice => unitPrice * quantity;

  /// Format unit price
  String get unitPriceText => '${unitPrice}F';

  /// Format total price
  String get totalPriceText => '${totalPrice}F';

  /// Get selected option items as a list of names
  List<String> get selectedOptionNames {
    final names = <String>[];
    for (final option in product.options) {
      final selectedIds = selectedOptions[option.id] ?? [];
      for (final item in option.items) {
        if (selectedIds.contains(item.id)) {
          names.add(item.name);
        }
      }
    }
    return names;
  }

  /// Get formatted options summary
  String get optionsSummary {
    final names = selectedOptionNames;
    if (names.isEmpty) return '';
    return names.join(', ');
  }

  /// Create a copy with updated quantity
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    Map<String, List<String>>? selectedOptions,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
