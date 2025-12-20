import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Types of services available in the MVP
enum ServiceType {
  /// Restaurant - catalogue flow (list -> detail -> cart)
  restaurant,

  /// Gas delivery - simplified flow (map + bottom sheet)
  gas,

  /// Errands/Shopping - simplified flow (map + list/voice)
  errands,

  /// Parcel delivery - multi-point flow (map + destinations)
  parcel,
}

/// Service category for the home screen
class ServiceCategory extends Equatable {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.routePath,
    this.description,
  });

  final String id;
  final String name;
  final ServiceType type;
  final IconData icon;
  final Color color;
  final String routePath;
  final String? description;

  @override
  List<Object?> get props => [id, type];

  /// Check if this service uses a provider catalogue flow
  bool get hasCatalogue => type == ServiceType.restaurant;

  /// Check if this service uses a simplified map-based flow
  bool get isDirectService =>
      type == ServiceType.gas ||
      type == ServiceType.errands ||
      type == ServiceType.parcel;
}
