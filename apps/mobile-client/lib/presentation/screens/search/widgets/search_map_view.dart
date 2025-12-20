import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Map view for search results with Google Maps
class SearchMapView extends StatefulWidget {
  const SearchMapView({
    super.key,
    required this.providers,
    this.onProviderTap,
  });

  final List<Provider> providers;
  final ValueChanged<Provider>? onProviderTap;

  @override
  State<SearchMapView> createState() => _SearchMapViewState();
}

class _SearchMapViewState extends State<SearchMapView> {
  GoogleMapController? _mapController;
  Provider? _selectedProvider;

  // Tiassale center coordinates
  static const LatLng _tiassaleCenter = LatLng(5.8987, -4.8237);

  Set<Marker> get _markers {
    return widget.providers.map((provider) {
      return Marker(
        markerId: MarkerId(provider.id),
        position: LatLng(provider.latitude, provider.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(provider.type),
        ),
        infoWindow: InfoWindow(
          title: provider.name,
          snippet: '${provider.ratingText} - ${provider.distanceText}',
        ),
        onTap: () {
          setState(() {
            _selectedProvider = provider;
          });
        },
      );
    }).toSet();
  }

  double _getMarkerHue(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return BitmapDescriptor.hueOrange;
      case ProviderType.gasDepot:
        return BitmapDescriptor.hueRed;
      case ProviderType.grocery:
        return BitmapDescriptor.hueGreen;
      case ProviderType.pharmacy:
        return BitmapDescriptor.hueCyan;
      case ProviderType.pressing:
        return BitmapDescriptor.hueViolet;
      case ProviderType.artisan:
        return BitmapDescriptor.hueYellow;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (widget.providers.isEmpty || _mapController == null) return;

    if (widget.providers.length == 1) {
      final provider = widget.providers.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(provider.latitude, provider.longitude),
          15,
        ),
      );
      return;
    }

    // Calculate bounds to fit all markers
    double minLat = widget.providers.first.latitude;
    double maxLat = widget.providers.first.latitude;
    double minLng = widget.providers.first.longitude;
    double maxLng = widget.providers.first.longitude;

    for (final provider in widget.providers) {
      if (provider.latitude < minLat) minLat = provider.latitude;
      if (provider.latitude > maxLat) maxLat = provider.latitude;
      if (provider.longitude < minLng) minLng = provider.longitude;
      if (provider.longitude > maxLng) maxLng = provider.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  void didUpdateWidget(SearchMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers != widget.providers) {
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
          initialCameraPosition: CameraPosition(
            target: _tiassaleCenter,
            zoom: 14,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onTap: (_) {
            setState(() {
              _selectedProvider = null;
            });
          },
        ),

        // My location button
        Positioned(
          right: AppSpacing.md,
          top: AppSpacing.md,
          child: FloatingActionButton.small(
            heroTag: 'location',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_tiassaleCenter, 14),
              );
            },
            backgroundColor: AppColors.surface,
            child: const Icon(
              Icons.my_location,
              color: AppColors.primary,
            ),
          ),
        ),

        // Bottom sheet with provider list or selected provider
        _selectedProvider != null
            ? _SelectedProviderCard(
                provider: _selectedProvider!,
                onTap: () => widget.onProviderTap?.call(_selectedProvider!),
                onClose: () {
                  setState(() {
                    _selectedProvider = null;
                  });
                },
              )
            : _ProvidersBottomSheet(
                providers: widget.providers,
                onProviderTap: (provider) {
                  setState(() {
                    _selectedProvider = provider;
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(provider.latitude, provider.longitude),
                      16,
                    ),
                  );
                },
              ),
      ],
    );
  }
}

class _SelectedProviderCard extends StatelessWidget {
  const _SelectedProviderCard({
    required this.provider,
    required this.onTap,
    required this.onClose,
  });

  final Provider provider;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Provider image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  color: AppColors.grey100,
                  image: provider.coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(provider.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: provider.coverImageUrl == null
                    ? Icon(
                        _getProviderIcon(provider.type),
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.rating, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          provider.ratingText,
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          provider.distanceText,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: provider.isOpen ? AppColors.success : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.isOpen ? 'Ouvert' : 'Ferme',
                          style: AppTypography.labelSmall.copyWith(
                            color: provider.isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close button
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProviderIcon(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return Icons.restaurant;
      case ProviderType.gasDepot:
        return Icons.local_fire_department;
      case ProviderType.grocery:
        return Icons.local_grocery_store;
      case ProviderType.pharmacy:
        return Icons.local_pharmacy;
      case ProviderType.pressing:
        return Icons.dry_cleaning;
      case ProviderType.artisan:
        return Icons.handyman;
    }
  }
}

class _ProvidersBottomSheet extends StatelessWidget {
  const _ProvidersBottomSheet({
    required this.providers,
    required this.onProviderTap,
  });

  final List<Provider> providers;
  final ValueChanged<Provider> onProviderTap;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: AppSpacing.borderRadiusXxs,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  '${providers.length} resultats a proximite',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Provider list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _MapProviderTile(
                      provider: provider,
                      onTap: () => onProviderTap(provider),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapProviderTile extends StatelessWidget {
  const _MapProviderTile({
    required this.provider,
    this.onTap,
  });

  final Provider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            // Icon based on type
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                _getProviderIcon(provider.type),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.rating, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        provider.ratingText,
                        style: AppTypography.labelSmall,
                      ),
                      if (provider.distanceKm != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          provider.distanceText,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: provider.isOpen ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(ProviderType type) {
    switch (type) {
      case ProviderType.restaurant:
        return Icons.restaurant;
      case ProviderType.gasDepot:
        return Icons.local_fire_department;
      case ProviderType.grocery:
        return Icons.local_grocery_store;
      case ProviderType.pharmacy:
        return Icons.local_pharmacy;
      case ProviderType.pressing:
        return Icons.dry_cleaning;
      case ProviderType.artisan:
        return Icons.handyman;
    }
  }
}
