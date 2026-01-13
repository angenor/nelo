import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Represents a delivery destination in a parcel order
class ParcelDestination extends Equatable {
  const ParcelDestination({
    required this.id,
    this.label,
    this.address,
    this.latitude,
    this.longitude,
    this.contactName,
    this.contactPhone,
  });

  /// Unique identifier
  final String id;

  /// Optional label (e.g., "Destination 1", "Bureau")
  final String? label;

  /// Full address text
  final String? address;

  /// Geographic coordinates
  final double? latitude;
  final double? longitude;

  /// Contact information at this destination
  final String? contactName;
  final String? contactPhone;

  @override
  List<Object?> get props => [
        id,
        label,
        address,
        latitude,
        longitude,
        contactName,
        contactPhone,
      ];

  /// Check if destination has valid address and coordinates
  bool get isValid =>
      address != null &&
      address!.isNotEmpty &&
      latitude != null &&
      longitude != null;

  /// Check if destination is empty (no data entered yet)
  bool get isEmpty => address == null && label == null;

  /// Check if destination has contact info
  bool get hasContact => contactName != null || contactPhone != null;

  /// Create an empty destination for new entries
  factory ParcelDestination.empty() {
    return ParcelDestination(id: const Uuid().v4());
  }

  /// Create a copy with modified fields
  ParcelDestination copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactPhone,
  }) {
    return ParcelDestination(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  /// Create from map
  factory ParcelDestination.fromMap(Map<String, dynamic> map) {
    return ParcelDestination(
      id: map['id'] as String? ?? const Uuid().v4(),
      label: map['label'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      contactName: map['contact_name'] as String?,
      contactPhone: map['contact_phone'] as String?,
    );
  }

  /// Convert to map for storage/API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contact_name': contactName,
      'contact_phone': contactPhone,
    };
  }
}
