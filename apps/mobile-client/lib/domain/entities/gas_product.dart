import 'package:equatable/equatable.dart';

/// Gas bottle size enum
enum GasBottleSize {
  small(6, 'Petite'),
  medium(12, 'Moyenne'),
  large(38, 'Grande');

  const GasBottleSize(this.kg, this.label);

  final int kg;
  final String label;

  String get displayText => '$kg kg - $label';
}

/// Gas brand enum
enum GasBrand {
  total('Total', 'https://picsum.photos/seed/total/100/100'),
  shell('Shell', 'https://picsum.photos/seed/shell/100/100'),
  oryx('Oryx', 'https://picsum.photos/seed/oryx/100/100'),
  other('Autre', null);

  const GasBrand(this.name, this.logoUrl);

  final String name;
  final String? logoUrl;
}

/// Gas order type
enum GasOrderType {
  refill('Recharge', 'Ma bouteille sera rechargée'),
  exchange('Échange', 'Je reçois une bouteille pleine');

  const GasOrderType(this.label, this.description);

  final String label;
  final String description;
}

/// Gas product entity with pricing
class GasProduct extends Equatable {
  const GasProduct({
    required this.id,
    required this.providerId,
    required this.brand,
    required this.bottleSize,
    required this.refillPrice,
    required this.exchangePrice,
    this.quantityAvailable = 0,
    this.isAvailable = true,
  });

  final String id;
  final String providerId;
  final GasBrand brand;
  final GasBottleSize bottleSize;
  final int refillPrice;
  final int exchangePrice;
  final int quantityAvailable;
  final bool isAvailable;

  @override
  List<Object?> get props => [id, providerId, brand, bottleSize];

  /// Get price based on order type
  int getPrice(GasOrderType orderType) {
    return orderType == GasOrderType.refill ? refillPrice : exchangePrice;
  }

  /// Format price
  String formatPrice(GasOrderType orderType) {
    final price = getPrice(orderType);
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }
}
