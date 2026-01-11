import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Available units for article quantities
class ArticleUnit {
  static const String fcfa = 'FCFA';
  static const String kg = 'kg';
  static const String unit = 'unité(s)';
  static const String liter = 'L';
  static const String bottle = 'bouteille(s)';
  static const String packet = 'paquet(s)';

  static const List<String> all = [fcfa, kg, unit, liter, bottle, packet];
}

/// A single item in the shopping list for errands service
class ErrandsItem extends Equatable {
  const ErrandsItem({
    required this.id,
    required this.name,
    this.quantity = 0,
    this.unit = ArticleUnit.fcfa,
  });

  /// Unique identifier
  final String id;

  /// Article name (e.g., "Riz", "Huile Dinor", "Tomates")
  final String name;

  /// Quantity value (price if unit is FCFA, otherwise amount)
  final double quantity;

  /// Unit type (FCFA, kg, L, unité(s), etc.)
  final String unit;

  @override
  List<Object?> get props => [id, name, quantity, unit];

  /// Estimated price in FCFA (only valid when unit is FCFA)
  int get estimatedPrice {
    if (unit == ArticleUnit.fcfa) {
      return quantity.toInt();
    }
    // For other units, no price estimation
    return 0;
  }

  /// Format quantity for display (e.g., "3 500 F" or "2 kg")
  String get formattedQuantity {
    if (quantity <= 0) return '';

    if (unit == ArticleUnit.fcfa) {
      final formatted = quantity.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]} ',
          );
      return '$formatted F';
    }

    // For other units, format nicely
    final q = quantity == quantity.toInt()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return '$q $unit';
  }

  /// Check if item is valid (has name - quantity is optional)
  bool get isValid => name.trim().isNotEmpty;

  /// Check if item has quantity specified
  bool get hasQuantity => quantity > 0;

  /// Create a copy with modified fields
  ErrandsItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
  }) {
    return ErrandsItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  /// Create an empty item for new entries
  factory ErrandsItem.empty() {
    return ErrandsItem(
      id: const Uuid().v4(),
      name: '',
      quantity: 0,
      unit: ArticleUnit.fcfa,
    );
  }

  /// Create from map
  factory ErrandsItem.fromMap(Map<String, dynamic> map) {
    return ErrandsItem(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? ArticleUnit.fcfa,
    );
  }

  /// Convert to map for storage/API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
