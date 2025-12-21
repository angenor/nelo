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

  // Order configuration
  Map<String, dynamic>? _selectedAddress;
  GasBottleSize? _selectedSize;
  GasBrand? _selectedBrand;
  GasOrderType _orderType = GasOrderType.refill;

  // Sheet controller
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _gasDepots = MockData.gasDepots;

    // Select closest depot by default
    if (_gasDepots.isNotEmpty) {
      _gasDepots.sort((a, b) =>
          (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      _selectedDepot = _gasDepots.first;
      _loadDepotProducts();
    }

    // Select default address
    final defaultAddr = MockData.userAddresses.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => MockData.userAddresses.first,
    );
    _selectedAddress = defaultAddr;
  }

  void _loadDepotProducts() {
    if (_selectedDepot == null) return;

    final sizes = MockData.getAvailableSizesForProvider(_selectedDepot!.id);
    if (sizes.isNotEmpty) {
      // Default to medium (12kg) if available, otherwise first
      _selectedSize = sizes.contains(GasBottleSize.medium)
          ? GasBottleSize.medium
          : sizes.first;
      _updateAvailableBrands();
    }
  }

  void _updateAvailableBrands() {
    if (_selectedDepot == null || _selectedSize == null) return;

    final brands = MockData.getAvailableBrandsForSize(
        _selectedDepot!.id, _selectedSize!);
    if (brands.isNotEmpty && !brands.contains(_selectedBrand)) {
      _selectedBrand = brands.first;
    }
  }

  void _onDepotSelected(Provider depot) {
    setState(() {
      _selectedDepot = depot;
      _selectedSize = null;
      _selectedBrand = null;
      _loadDepotProducts();
    });
  }

  void _onAddressChanged(Map<String, dynamic> address) {
    setState(() {
      _selectedAddress = address;
    });
  }

  void _onSizeChanged(GasBottleSize size) {
    setState(() {
      _selectedSize = size;
      _updateAvailableBrands();
    });
  }

  void _onBrandChanged(GasBrand brand) {
    setState(() {
      _selectedBrand = brand;
    });
  }

  void _onOrderTypeChanged(GasOrderType type) {
    setState(() {
      _orderType = type;
    });
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

  void _onOrder() {
    if (_selectedProduct == null || _selectedAddress == null) {
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
      'orderType': _orderType,
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
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.25, 0.45, 0.85],
            builder: (context, scrollController) {
              return GasOrderSheet(
                scrollController: scrollController,
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
                orderType: _orderType,
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
