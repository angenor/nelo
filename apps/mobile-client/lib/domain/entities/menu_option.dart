import 'package:equatable/equatable.dart';

/// Menu option entity for restaurant products (e.g., "Taille", "Accompagnement", "Sauce")
class MenuOption extends Equatable {
  const MenuOption({
    required this.id,
    required this.productId,
    required this.name,
    this.type = MenuOptionType.single,
    this.isRequired = false,
    this.maxSelections = 1,
    this.items = const [],
  });

  final String id;
  final String productId;
  final String name;
  final MenuOptionType type;
  final bool isRequired;
  final int maxSelections;
  final List<MenuOptionItem> items;

  @override
  List<Object?> get props => [id, productId, name];

  /// Check if this is a single selection option
  bool get isSingleSelection => type == MenuOptionType.single;

  /// Check if this is a multiple selection option
  bool get isMultipleSelection => type == MenuOptionType.multiple;
}

/// Menu option item entity (e.g., "Petit", "Moyen", "Grand")
class MenuOptionItem extends Equatable {
  const MenuOptionItem({
    required this.id,
    required this.optionId,
    required this.name,
    this.priceAdjustment = 0,
    this.isAvailable = true,
  });

  final String id;
  final String optionId;
  final String name;
  final int priceAdjustment;
  final bool isAvailable;

  @override
  List<Object?> get props => [id, optionId, name];

  /// Format price adjustment as string
  String get priceAdjustmentText {
    if (priceAdjustment == 0) return '';
    if (priceAdjustment > 0) return '+${priceAdjustment}F';
    return '${priceAdjustment}F';
  }
}

/// Option selection type
enum MenuOptionType {
  /// Only one item can be selected
  single,

  /// Multiple items can be selected (up to maxSelections)
  multiple,
}
