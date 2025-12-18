import 'package:equatable/equatable.dart';

/// Provider types matching database enum
enum ProviderType {
  restaurant,
  gasDepot,
  grocery,
  pharmacy,
  pressing,
  artisan,
}

/// Provider category entity
class ProviderCategory extends Equatable {
  const ProviderCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.providerType,
    this.parentId,
    this.iconUrl,
    this.displayOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String? iconUrl;
  final ProviderType providerType;
  final int displayOrder;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, slug, providerType];
}
