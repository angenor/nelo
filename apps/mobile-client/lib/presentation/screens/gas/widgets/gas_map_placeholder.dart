import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Google Maps view for gas ordering - shows depots and delivery address
class GasMapPlaceholder extends StatefulWidget {
  const GasMapPlaceholder({
    super.key,
    required this.depots,
    required this.selectedDepot,
    required this.deliveryAddress,
    required this.onDepotSelected,
  });

  final List<Provider> depots;
  final Provider? selectedDepot;
  final Map<String, dynamic>? deliveryAddress;
  final ValueChanged<Provider> onDepotSelected;

  @override
  State<GasMapPlaceholder> createState() => _GasMapPlaceholderState();
}

class _GasMapPlaceholderState extends State<GasMapPlaceholder> {
  GoogleMapController? _mapController;

  // Tiassale center coordinates
  static const LatLng _tiassaleCenter = LatLng(5.8987, -4.8237);

  // Clean map style - hides POIs, transit, and unnecessary elements
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

  Set<Marker> get _markers {
    final markers = <Marker>{};

    // Add depot markers
    for (final depot in widget.depots) {
      final isSelected = depot.id == widget.selectedDepot?.id;
      markers.add(
        Marker(
          markerId: MarkerId(depot.id),
          position: LatLng(depot.latitude, depot.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: depot.name,
            snippet: depot.distanceText,
          ),
          onTap: () => widget.onDepotSelected(depot),
        ),
      );
    }

    // Add delivery address marker
    if (widget.deliveryAddress != null) {
      final lat = widget.deliveryAddress!['latitude'] as double?;
      final lng = widget.deliveryAddress!['longitude'] as double?;
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('delivery_address'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: widget.deliveryAddress!['label'] as String? ?? 'Livraison',
              snippet: widget.deliveryAddress!['address'] as String?,
            ),
          ),
        );
      }
    }

    return markers;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_mapController == null) return;

    // If we have a selected depot and delivery address, show both
    if (widget.selectedDepot != null && widget.deliveryAddress != null) {
      final depotLat = widget.selectedDepot!.latitude;
      final depotLng = widget.selectedDepot!.longitude;
      final addrLat = widget.deliveryAddress!['latitude'] as double?;
      final addrLng = widget.deliveryAddress!['longitude'] as double?;

      if (addrLat != null && addrLng != null) {
        final minLat = depotLat < addrLat ? depotLat : addrLat;
        final maxLat = depotLat > addrLat ? depotLat : addrLat;
        final minLng = depotLng < addrLng ? depotLng : addrLng;
        final maxLng = depotLng > addrLng ? depotLng : addrLng;

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - 0.005, minLng - 0.005),
              northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
            ),
            60,
          ),
        );
        return;
      }
    }

    // If only selected depot, zoom to it
    if (widget.selectedDepot != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.selectedDepot!.latitude, widget.selectedDepot!.longitude),
          15,
        ),
      );
      return;
    }

    // Default: fit all depots
    if (widget.depots.isEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_tiassaleCenter, 14),
      );
      return;
    }

    if (widget.depots.length == 1) {
      final depot = widget.depots.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(depot.latitude, depot.longitude),
          15,
        ),
      );
      return;
    }

    double minLat = widget.depots.first.latitude;
    double maxLat = widget.depots.first.latitude;
    double minLng = widget.depots.first.longitude;
    double maxLng = widget.depots.first.longitude;

    for (final depot in widget.depots) {
      if (depot.latitude < minLat) minLat = depot.latitude;
      if (depot.latitude > maxLat) maxLat = depot.latitude;
      if (depot.longitude < minLng) minLng = depot.longitude;
      if (depot.longitude > maxLng) maxLng = depot.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        50,
      ),
    );
  }

  @override
  void didUpdateWidget(GasMapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDepot != widget.selectedDepot ||
        oldWidget.deliveryAddress != widget.deliveryAddress) {
      _fitBounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: const CameraPosition(
            target: _tiassaleCenter,
            zoom: 14,
          ),
          style: _mapStyle,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Legend
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.45 + 20,
          left: AppSpacing.md,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(
                  color: const Color(0xFFFF9800), // Orange
                  label: 'Depot selectionne',
                ),
                const SizedBox(height: 4),
                _LegendItem(
                  color: const Color(0xFFF44336), // Red
                  label: 'Autres depots',
                ),
                const SizedBox(height: 4),
                _LegendItem(
                  color: const Color(0xFF4CAF50), // Green
                  label: 'Adresse de livraison',
                ),
              ],
            ),
          ),
        ),

        // Center on location button
        Positioned(
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).size.height * 0.45 + 20,
          child: FloatingActionButton.small(
            heroTag: 'gas_location',
            onPressed: _fitBounds,
            backgroundColor: AppColors.surface,
            child: Icon(
              Icons.my_location,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }
}
