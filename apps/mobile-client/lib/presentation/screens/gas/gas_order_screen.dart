import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'widgets/gas_order_sheet.dart';
import 'widgets/gas_map_placeholder.dart';

/// Gas ordering screen with map and bottom sheet
class GasOrderScreen extends StatefulWidget {
  const GasOrderScreen({super.key});

  @override
  State<GasOrderScreen> createState() => _GasOrderScreenState();
}

class _GasOrderScreenState extends State<GasOrderScreen> {
  // Gas depots
  late List<Provider> _gasDepots;
  Provider? _selectedDepot;

  // Order configuration - all null by default (no pre-selection)
  Map<String, dynamic>? _selectedAddress;
  GasBottleSize? _selectedSize;
  GasBrand? _selectedBrand;
  GasOrderType? _selectedOrderType;

  // Sheet controller for progressive expansion
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Sheet sizes for each step
  // Initial size shows address + bottle size sections together
  static const double _initialSize = 0.42;
  static const double _stepBrandSize = 0.52;
  static const double _stepOrderTypeSize = 0.65;
  static const double _stepSummarySize = 0.85;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _gasDepots = MockData.gasDepots;

    // Select closest depot by default
    if (_gasDepots.isNotEmpty) {
      _gasDepots.sort(
          (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      _selectedDepot = _gasDepots.first;
    }

    // Select default address
    final defaultAddr = MockData.userAddresses.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => MockData.userAddresses.first,
    );
    _selectedAddress = defaultAddr;
  }

  void _animateSheetTo(double size) {
    _sheetController.animateTo(
      size,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDepotSelected(Provider depot) {
    setState(() {
      _selectedDepot = depot;
      // Reset selections when depot changes
      _selectedSize = null;
      _selectedBrand = null;
      _selectedOrderType = null;
    });
    _animateSheetTo(_initialSize);
  }

  void _onAddressChanged(Map<String, dynamic> address) {
    setState(() {
      _selectedAddress = address;
    });
  }

  void _onSizeChanged(GasBottleSize size) {
    setState(() {
      _selectedSize = size;
      // Reset brand when size changes (available brands may differ)
      _selectedBrand = null;
      _selectedOrderType = null;
    });
    // Animate to show brand section
    _animateSheetTo(_stepBrandSize);
  }

  void _onBrandChanged(GasBrand brand) {
    setState(() {
      _selectedBrand = brand;
      // Reset order type when brand changes
      _selectedOrderType = null;
    });
    // Animate to show order type section
    _animateSheetTo(_stepOrderTypeSize);
  }

  void _onOrderTypeChanged(GasOrderType type) {
    setState(() {
      _selectedOrderType = type;
    });
    // Animate to show summary
    _animateSheetTo(_stepSummarySize);
  }

  GasProduct? get _selectedProduct {
    if (_selectedDepot == null ||
        _selectedSize == null ||
        _selectedBrand == null) {
      return null;
    }
    return MockData.getGasProduct(
        _selectedDepot!.id, _selectedSize!, _selectedBrand!);
  }

  /// Calculate current step (0-4)
  int get _currentStep {
    if (_selectedOrderType != null) return 4;
    if (_selectedBrand != null) return 3;
    if (_selectedSize != null) return 2;
    if (_selectedAddress != null) return 1;
    return 0;
  }

  void _onOrder() {
    if (_selectedProduct == null ||
        _selectedAddress == null ||
        _selectedOrderType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez compléter votre commande'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to confirmation
    context.push('/gas/confirm', extra: {
      'depot': _selectedDepot,
      'product': _selectedProduct,
      'orderType': _selectedOrderType,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (full screen)
          GasMapPlaceholder(
            depots: _gasDepots,
            selectedDepot: _selectedDepot,
            deliveryAddress: _selectedAddress,
            onDepotSelected: _onDepotSelected,
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
                child: Text(
                  'Commander du Gaz',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _initialSize,
            minChildSize: 0.25,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: [
              0.25,
              _initialSize,
              _stepBrandSize,
              _stepOrderTypeSize,
              _stepSummarySize,
            ],
            builder: (context, scrollController) {
              return GasOrderSheet(
                scrollController: scrollController,
                currentStep: _currentStep,
                addresses: MockData.userAddresses,
                selectedAddress: _selectedAddress,
                onAddressChanged: _onAddressChanged,
                depot: _selectedDepot,
                availableSizes: _selectedDepot != null
                    ? MockData.getAvailableSizesForProvider(_selectedDepot!.id)
                    : [],
                selectedSize: _selectedSize,
                onSizeChanged: _onSizeChanged,
                availableBrands: _selectedDepot != null && _selectedSize != null
                    ? MockData.getAvailableBrandsForSize(
                        _selectedDepot!.id, _selectedSize!)
                    : [],
                selectedBrand: _selectedBrand,
                onBrandChanged: _onBrandChanged,
                selectedOrderType: _selectedOrderType,
                onOrderTypeChanged: _onOrderTypeChanged,
                selectedProduct: _selectedProduct,
                onOrder: _onOrder,
              );
            },
          ),
        ],
      ),
    );
  }
}
