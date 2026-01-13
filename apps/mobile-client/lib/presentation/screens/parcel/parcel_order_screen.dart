import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/parcel_destination.dart';
import 'widgets/widgets.dart';

/// Parcel ordering screen with map and bottom sheet
class ParcelOrderScreen extends StatefulWidget {
  const ParcelOrderScreen({super.key});

  @override
  State<ParcelOrderScreen> createState() => _ParcelOrderScreenState();
}

class _ParcelOrderScreenState extends State<ParcelOrderScreen> {
  // Pickup address
  Map<String, dynamic>? _pickupAddress;
  bool _isLoadingLocation = false;

  // Destinations (start with one empty)
  List<ParcelDestination> _destinations = [ParcelDestination.empty()];

  // Package description
  String _description = '';

  // Voice recording
  bool _isRecording = false;
  bool _hasRecording = false;
  Duration _recordingDuration = Duration.zero;
  bool _isPlaying = false;

  // Calculated values
  double _totalDistanceKm = 0;
  int _estimatedPrice = 0;

  // Form state
  bool _isProcessing = false;

  // Sheet controller
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  void _loadDefaultAddress() {
    // Load user's default address as pickup
    final defaultAddr = MockData.userAddresses.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => MockData.userAddresses.first,
    );
    setState(() {
      _pickupAddress = defaultAddr;
    });
    _calculateRoute();
  }

  void _onPickupAddressChanged(Map<String, dynamic> address) {
    setState(() {
      _pickupAddress = address;
    });
    _calculateRoute();
  }

  void _onUseMyLocation() async {
    setState(() => _isLoadingLocation = true);

    // Simulate getting current location
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoadingLocation = false;
      _pickupAddress = {
        'id': 'current_location',
        'label': 'Ma position',
        'address': 'Position actuelle',
        'latitude': 5.8980,
        'longitude': -4.8225,
      };
    });
    _calculateRoute();
  }

  void _onDestinationChanged(int index, Map<String, dynamic> address) {
    setState(() {
      _destinations[index] = _destinations[index].copyWith(
        address: address['address'] as String?,
        latitude: address['latitude'] as double?,
        longitude: address['longitude'] as double?,
        label: address['label'] as String?,
      );
    });
    _calculateRoute();
  }

  void _onDestinationDelete(int index) {
    if (_destinations.length > 1) {
      setState(() {
        _destinations.removeAt(index);
      });
      _calculateRoute();
    }
  }

  void _onAddDestination() {
    if (_destinations.length < 5) {
      setState(() {
        _destinations.add(ParcelDestination.empty());
      });
    }
  }

  void _onDescriptionChanged(String value) {
    setState(() {
      _description = value;
    });
  }

  void _onVoiceRecordTap() {
    if (_isRecording) {
      // Stop recording
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordingDuration = const Duration(seconds: 15); // Mock duration
      });
    } else {
      // Start recording
      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _recordingDuration = Duration.zero;
      });

      // Simulate recording timer
      _simulateRecording();
    }
  }

  void _simulateRecording() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });

        // Auto-stop at 2 minutes
        if (_recordingDuration.inSeconds >= 120) {
          _onVoiceRecordTap();
        }
      }
    }
  }

  void _onVoiceRecordDelete() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = Duration.zero;
      _isPlaying = false;
    });
  }

  void _onVoicePlayTap() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      // Simulate playback ending
      Future.delayed(_recordingDuration, () {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  void _calculateRoute() {
    if (_pickupAddress == null) {
      setState(() {
        _totalDistanceKm = 0;
        _estimatedPrice = 0;
      });
      return;
    }

    final validDestinations = _destinations
        .where((d) => d.isValid)
        .map((d) => d.toMap())
        .toList();

    if (validDestinations.isEmpty) {
      setState(() {
        _totalDistanceKm = 0;
        _estimatedPrice = 0;
      });
      return;
    }

    // Calculate using mock data methods
    final distance = MockData.calculateTotalRouteDistance(
      _pickupAddress!,
      validDestinations,
    );

    final price = MockData.calculateParcelPrice(
      distance,
      validDestinations.length,
    );

    setState(() {
      _totalDistanceKm = distance;
      _estimatedPrice = price;
    });
  }

  bool get _canSubmit {
    // Pickup address required
    if (_pickupAddress == null) return false;

    // At least one valid destination required
    final hasValidDestination = _destinations.any((d) => d.isValid);
    if (!hasValidDestination) return false;

    // Either description OR voice note required
    final hasDescription = _description.trim().isNotEmpty;
    if (!hasDescription && !_hasRecording) return false;

    return true;
  }

  void _onSubmit() async {
    if (!_canSubmit) {
      String message = 'Veuillez compléter votre commande';
      if (_pickupAddress == null) {
        message = 'Veuillez sélectionner un point de récupération';
      } else if (!_destinations.any((d) => d.isValid)) {
        message = 'Veuillez ajouter au moins une destination';
      } else if (_description.trim().isEmpty && !_hasRecording) {
        message = 'Veuillez décrire le colis ou enregistrer une note vocale';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    // Navigate to confirmation screen
    context.push('/parcel/confirm', extra: {
      'pickupAddress': _pickupAddress,
      'destinations': _destinations.where((d) => d.isValid).toList(),
      'description': _description,
      'hasVoiceNote': _hasRecording,
      'recordingDuration': _recordingDuration,
      'totalDistanceKm': _totalDistanceKm,
      'estimatedPrice': _estimatedPrice,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map view (full screen)
          ParcelMapView(
            pickupAddress: _pickupAddress,
            destinations: _destinations,
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.sm,
            child: CircleAvatar(
              backgroundColor: AppColors.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Title
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      size: 18,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Colis Express',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.35, 0.55, 0.75, 0.92],
            builder: (context, scrollController) {
              return ParcelOrderSheet(
                scrollController: scrollController,
                savedAddresses: MockData.userAddresses,
                pickupAddress: _pickupAddress,
                onPickupAddressChanged: _onPickupAddressChanged,
                onUseMyLocation: _onUseMyLocation,
                isLoadingLocation: _isLoadingLocation,
                destinations: _destinations,
                onDestinationChanged: _onDestinationChanged,
                onDestinationDelete: _onDestinationDelete,
                onAddDestination: _onAddDestination,
                description: _description,
                onDescriptionChanged: _onDescriptionChanged,
                isRecording: _isRecording,
                hasRecording: _hasRecording,
                recordingDuration: _recordingDuration,
                onVoiceRecordTap: _onVoiceRecordTap,
                onVoiceRecordDelete: _onVoiceRecordDelete,
                onVoicePlayTap: _onVoicePlayTap,
                isPlaying: _isPlaying,
                totalDistanceKm: _totalDistanceKm,
                estimatedPrice: _estimatedPrice,
                onSubmit: _onSubmit,
                isProcessing: _isProcessing,
                canSubmit: _canSubmit,
              );
            },
          ),
        ],
      ),
    );
  }
}
