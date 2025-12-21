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
  String? _selectedPaymentMethod = 'cash'; // Default to cash payment
  bool _isProcessing = false;

  // Sheet controller for progressive expansion
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Sheet sizes for each step
  // Initial size shows address + bottle size sections together
  static const double _initialSize = 0.60;
  static const double _stepBrandSize = 0.68;
  static const double _stepOrderTypeSize = 0.76;
  static const double _stepPaymentSize = 0.84;
  static const double _stepSummarySize = 0.92;

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
      _selectedPaymentMethod = 'cash';
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
      _selectedPaymentMethod = 'cash';
    });
    // Animate to show brand section
    _animateSheetTo(_stepBrandSize);
  }

  void _onBrandChanged(GasBrand brand) {
    setState(() {
      _selectedBrand = brand;
      // Reset order type when brand changes
      _selectedOrderType = null;
      _selectedPaymentMethod = 'cash';
    });
    // Animate to show order type section
    _animateSheetTo(_stepOrderTypeSize);
  }

  void _onOrderTypeChanged(GasOrderType type) {
    setState(() {
      _selectedOrderType = type;
      // Payment method keeps its value (default is 'cash')
    });
    // Animate to show summary (payment already has default value)
    _animateSheetTo(_stepSummarySize);
  }

  void _onPaymentMethodChanged(String method) {
    setState(() {
      _selectedPaymentMethod = method;
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

  /// Calculate current step (0-5)
  /// Payment method has a default value ('cash'), so step 5 is reached when orderType is selected
  int get _currentStep {
    // When orderType is selected, payment already has default value so we're at step 5
    if (_selectedOrderType != null && _selectedPaymentMethod != null) return 5;
    if (_selectedOrderType != null) return 4;
    if (_selectedBrand != null) return 3;
    if (_selectedSize != null) return 2;
    if (_selectedAddress != null) return 1;
    return 0;
  }

  void _onOrder() async {
    if (_selectedProduct == null ||
        _selectedAddress == null ||
        _selectedOrderType == null ||
        _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez compléter votre commande'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate order processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OrderSuccessDialog(
        onDone: () {
          Navigator.of(context).pop();
          context.go('/home');
        },
      ),
    );
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
            minChildSize: _initialSize,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: [
              _initialSize,
              _stepBrandSize,
              _stepOrderTypeSize,
              _stepPaymentSize,
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
                selectedPaymentMethod: _selectedPaymentMethod,
                onPaymentMethodChanged: _onPaymentMethodChanged,
                selectedProduct: _selectedProduct,
                onOrder: _onOrder,
                isProcessing: _isProcessing,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Success dialog after order confirmation
class _OrderSuccessDialog extends StatelessWidget {
  const _OrderSuccessDialog({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Commande confirmée !',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Votre commande de gaz a été envoyée. Un livreur sera bientôt assigné.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: const Text('Retour à l\'accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
