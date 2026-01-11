import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/theme.dart';

/// Full screen map for picking a delivery location
/// User can pan/zoom the map and the center position is selected
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  /// Initial location to center the map on
  final LatLng? initialLocation;

  /// Called when user confirms the selected location
  final void Function(Map<String, dynamic> address) onLocationSelected;

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(5.8987, -4.8237); // Tiassalé center
  String _addressText = 'Chargement...';
  bool _isLoading = false;

  // Clean map style
  static const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"visibility": "on"}, {"color": "#e5f5e0"}]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#c9e4f5"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f5f5f5"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }
    _reverseGeocode(_selectedLocation);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _selectedLocation = position.target;
  }

  void _onCameraIdle() {
    _reverseGeocode(_selectedLocation);
  }

  /// Mock reverse geocoding - converts coordinates to address text
  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Mock address based on position (in real app, use geocoding API)
    String address;
    if (position.latitude > 5.90) {
      address = 'Route de Divo, Tiassalé';
    } else if (position.longitude < -4.825) {
      address = 'Quartier Commerce, Tiassalé';
    } else if (position.latitude < 5.895) {
      address = 'Gare Routière, Tiassalé';
    } else {
      address = 'Centre-ville, Tiassalé';
    }

    setState(() {
      _addressText = address;
      _isLoading = false;
    });
  }

  void _confirmLocation() {
    final addressData = {
      'id': 'map_${DateTime.now().millisecondsSinceEpoch}',
      'label': 'Position choisie',
      'address': _addressText,
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'isDefault': false,
      'isMapSelected': true,
    };

    widget.onLocationSelected(addressData);
    Navigator.of(context).pop();
  }

  void _centerOnCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate getting current location
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Mock current location (Tiassalé center)
    const currentLocation = LatLng(5.8983, -4.8228);

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(currentLocation),
    );

    setState(() {
      _selectedLocation = currentLocation;
      _isLoading = false;
    });

    _reverseGeocode(currentLocation);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Choisir sur la carte',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            style: _mapStyle,
          ),

          // Center marker (fixed position)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),

          // Center marker shadow
          Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.overlay,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // My location button
          Positioned(
            right: AppSpacing.md,
            bottom: 200,
            child: FloatingActionButton.small(
              onPressed: _centerOnCurrentLocation,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              elevation: 4,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Bottom panel with address and confirm button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                bottomPadding + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Address display
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Position sélectionnée',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _isLoading
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Recherche de l\'adresse...',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _addressText,
                                      style:
                                          AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        disabledBackgroundColor: AppColors.grey300,
                      ),
                      child: const Text(
                        'Confirmer cette position',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
