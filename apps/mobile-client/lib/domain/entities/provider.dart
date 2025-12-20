import 'package:equatable/equatable.dart';
import 'cuisine_type.dart';
import 'provider_category.dart';

/// Provider entity (restaurant, gas depot, etc.)
class Provider extends Equatable {
  const Provider({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.phone,
    required this.addressLine1,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    this.description,
    this.email,
    this.whatsapp,
    this.landmark,
    this.zoneId,
    this.logoUrl,
    this.coverImageUrl,
    this.minOrderAmount = 0,
    this.averagePrepTime = 30,
    this.deliveryRadiusKm = 5.0,
    this.averageRating,
    this.ratingCount = 0,
    this.totalOrders = 0,
    this.isOpen = false,
    this.isFeatured = false,
    this.distanceKm,
    this.cuisineType,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final ProviderType type;
  final String phone;
  final String? email;
  final String? whatsapp;
  final String addressLine1;
  final String? landmark;
  final String cityId;
  final String? zoneId;
  final double latitude;
  final double longitude;
  final String? logoUrl;
  final String? coverImageUrl;
  final int minOrderAmount;
  final int averagePrepTime;
  final double deliveryRadiusKm;
  final double? averageRating;
  final int ratingCount;
  final int totalOrders;
  final bool isOpen;
  final bool isFeatured;
  final double? distanceKm;
  final CuisineType? cuisineType;

  @override
  List<Object?> get props => [id, name, slug, type];

  /// Format rating as string
  String get ratingText => averageRating?.toStringAsFixed(1) ?? '-';

  /// Format delivery time
  String get deliveryTimeText => '$averagePrepTime-${averagePrepTime + 15} min';

  /// Format distance
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}
