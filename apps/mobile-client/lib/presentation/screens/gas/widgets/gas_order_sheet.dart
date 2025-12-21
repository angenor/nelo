import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import 'address_picker_sheet.dart';

/// Bottom sheet for gas order configuration with progressive scroll
class GasOrderSheet extends StatefulWidget {
  const GasOrderSheet({
    super.key,
    required this.scrollController,
    required this.currentStep,
    required this.addresses,
    required this.selectedAddress,
    required this.onAddressChanged,
    required this.depot,
    required this.availableSizes,
    required this.selectedSize,
    required this.onSizeChanged,
    required this.availableBrands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.selectedOrderType,
    required this.onOrderTypeChanged,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.selectedProduct,
    required this.onOrder,
    required this.isProcessing,
  });

  final ScrollController scrollController;
  final int currentStep;
  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final ValueChanged<Map<String, dynamic>> onAddressChanged;
  final Provider? depot;
  final List<GasBottleSize> availableSizes;
  final GasBottleSize? selectedSize;
  final ValueChanged<GasBottleSize> onSizeChanged;
  final List<GasBrand> availableBrands;
  final GasBrand? selectedBrand;
  final ValueChanged<GasBrand> onBrandChanged;
  final GasOrderType? selectedOrderType;
  final ValueChanged<GasOrderType> onOrderTypeChanged;
  final String? selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final GasProduct? selectedProduct;
  final VoidCallback onOrder;
  final bool isProcessing;

  @override
  State<GasOrderSheet> createState() => _GasOrderSheetState();
}

class _GasOrderSheetState extends State<GasOrderSheet> {
  // Keys for scrolling to sections
  final GlobalKey _brandSectionKey = GlobalKey();
  final GlobalKey _orderTypeSectionKey = GlobalKey();
  final GlobalKey _paymentSectionKey = GlobalKey();
  final GlobalKey _summarySectionKey = GlobalKey();

  // Steps: 0=nothing, 1=address, 2=size, 3=brand, 4=orderType, 5=payment (complete)
  static const int _totalSteps = 5;

  int? _previousStep;

  @override
  void didUpdateWidget(GasOrderSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll when step changes
    if (_previousStep != widget.currentStep && widget.currentStep > 1) {
      _previousStep = widget.currentStep;
      // Wait for sheet expansion animation (300ms) before scrolling
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _scrollToCurrentStep();
        }
      });
    } else if (_previousStep != widget.currentStep) {
      _previousStep = widget.currentStep;
    }
  }

  void _scrollToCurrentStep() {
    GlobalKey? targetKey;

    switch (widget.currentStep) {
      case 2: // Size selected -> scroll to brand
        targetKey = _brandSectionKey;
        break;
      case 3: // Brand selected -> scroll to order type
        targetKey = _orderTypeSectionKey;
        break;
      case 4: // Order type selected -> scroll to payment
        targetKey = _paymentSectionKey;
        break;
      case 5: // Payment selected -> scroll to summary
        targetKey = _summarySectionKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        alignment: 0.0, // Align to top of viewport
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
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
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          _ProgressBar(currentStep: widget.currentStep, totalSteps: _totalSteps),

          const SizedBox(height: AppSpacing.md),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.zero,
              children: [
                // Step 1: Delivery address
                _buildSectionTitle(
                    'Livrer à', isCompleted: widget.selectedAddress != null),
                _AddressSelector(
                  addresses: widget.addresses,
                  selectedAddress: widget.selectedAddress,
                  onChanged: widget.onAddressChanged,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Step 2: Bottle size
                _buildSectionTitle(
                  'Taille de bouteille',
                  isCompleted: widget.selectedSize != null,
                  stepNumber: 1,
                ),
                _BottleSizeSelector(
                  sizes: widget.availableSizes,
                  selectedSize: widget.selectedSize,
                  onChanged: widget.onSizeChanged,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Step 3: Brand
                Container(
                  key: _brandSectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Marque',
                        isCompleted: widget.selectedBrand != null,
                        stepNumber: 2,
                        isEnabled: widget.selectedSize != null,
                      ),
                      _BrandSelector(
                        brands: widget.availableBrands,
                        selectedBrand: widget.selectedBrand,
                        onChanged: widget.onBrandChanged,
                        isEnabled: widget.selectedSize != null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Step 4: Order type
                Container(
                  key: _orderTypeSectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Type de commande',
                        isCompleted: widget.selectedOrderType != null,
                        stepNumber: 3,
                        isEnabled: widget.selectedBrand != null,
                      ),
                      _OrderTypeSelector(
                        selectedOrderType: widget.selectedOrderType,
                        onChanged: widget.onOrderTypeChanged,
                        isEnabled: widget.selectedBrand != null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Step 5: Payment method
                Container(
                  key: _paymentSectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Mode de paiement',
                        isCompleted: widget.selectedPaymentMethod != null,
                        stepNumber: 4,
                        isEnabled: widget.selectedOrderType != null,
                      ),
                      _PaymentMethodSelector(
                        selectedMethod: widget.selectedPaymentMethod,
                        onChanged: widget.onPaymentMethodChanged,
                        isEnabled: widget.selectedOrderType != null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Delivery time estimation (show when payment selected)
                if (widget.selectedPaymentMethod != null) ...[
                  _DeliveryTimeInfo(depot: widget.depot),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Extra space at bottom for scrolling
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),

          // Fixed bottom section - Summary + Order button
          Container(
            key: _summarySectionKey,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              bottomPadding + AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary info (show when payment method is selected)
                if (widget.selectedProduct != null &&
                    widget.selectedOrderType != null &&
                    widget.selectedPaymentMethod != null) ...[
                  _FloatingSummary(
                    depot: widget.depot!,
                    product: widget.selectedProduct!,
                    orderType: widget.selectedOrderType!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Order button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.selectedProduct != null &&
                            widget.selectedOrderType != null &&
                            widget.selectedPaymentMethod != null &&
                            !widget.isProcessing
                        ? widget.onOrder
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      disabledBackgroundColor: AppColors.grey300,
                    ),
                    child: widget.isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.selectedProduct != null &&
                                    widget.selectedOrderType != null &&
                                    widget.selectedPaymentMethod != null
                                ? 'Commander - ${widget.selectedProduct!.formatPrice(widget.selectedOrderType!)}'
                                : 'Sélectionnez vos options',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool isCompleted = false,
    int? stepNumber,
    bool isEnabled = true,
  }) {
    final textColor = isEnabled ? null : AppColors.grey400;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (stepNumber != null) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : (isEnabled ? AppColors.grey200 : AppColors.grey100),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.white,
                      )
                    : Text(
                        '$stepNumber',
                        style: AppTypography.labelSmall.copyWith(
                          color: isEnabled
                              ? AppColors.textSecondary
                              : AppColors.grey400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          if (isCompleted && stepNumber == null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.check_circle,
              size: 16,
              color: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress bar showing current step
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepLabel(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$currentStep / $totalSteps',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0, end: progress),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getStepLabel() {
    switch (currentStep) {
      case 0:
        return 'Choisissez une taille';
      case 1:
        return 'Choisissez une taille';
      case 2:
        return 'Choisissez une marque';
      case 3:
        return 'Choisissez le type';
      case 4:
        return 'Choisissez le paiement';
      case 5:
        return 'Prêt à commander';
      default:
        return '';
    }
  }
}

/// Address selector that opens a bottom sheet picker
class _AddressSelector extends StatelessWidget {
  const _AddressSelector({
    required this.addresses,
    required this.selectedAddress,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final ValueChanged<Map<String, dynamic>> onChanged;

  void _openAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => AddressPickerSheet(
            savedAddresses: addresses,
            onAddressSelected: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = selectedAddress;
    final isCurrent = address?['isCurrent'] == true;

    IconData icon;
    switch (address?['label']) {
      case 'Maison':
        icon = Icons.home;
        break;
      case 'Bureau':
        icon = Icons.work;
        break;
      case 'Position actuelle':
        icon = Icons.my_location;
        break;
      default:
        icon = Icons.location_on;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: InkWell(
        onTap: () => _openAddressPicker(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isCurrent ? AppColors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: address != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address['label'] as String,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            address['address'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Text(
                        'Sélectionner une adresse',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottle size selector
class _BottleSizeSelector extends StatelessWidget {
  const _BottleSizeSelector({
    required this.sizes,
    required this.selectedSize,
    required this.onChanged,
  });

  final List<GasBottleSize> sizes;
  final GasBottleSize? selectedSize;
  final ValueChanged<GasBottleSize> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: sizes.map((size) {
          final isSelected = size == selectedSize;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: size != sizes.last ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: () => onChanged(size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.propane_tank,
                        size: 32,
                        color: isSelected ? AppColors.primary : AppColors.grey400,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${size.kg} kg',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        size.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Brand selector
class _BrandSelector extends StatelessWidget {
  const _BrandSelector({
    required this.brands,
    required this.selectedBrand,
    required this.onChanged,
    required this.isEnabled,
  });

  final List<GasBrand> brands;
  final GasBrand? selectedBrand;
  final ValueChanged<GasBrand> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Center(
            child: Text(
              isEnabled
                  ? 'Aucune marque disponible'
                  : 'Sélectionnez d\'abord une taille',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey400,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final brand = brands[index];
          final isSelected = brand == selectedBrand;

          return GestureDetector(
            onTap: isEnabled ? () => onChanged(brand) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  brand.name,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isEnabled
                        ? (isSelected ? AppColors.primary : AppColors.textPrimary)
                        : AppColors.grey400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Order type selector (refill/exchange)
class _OrderTypeSelector extends StatelessWidget {
  const _OrderTypeSelector({
    required this.selectedOrderType,
    required this.onChanged,
    required this.isEnabled,
  });

  final GasOrderType? selectedOrderType;
  final ValueChanged<GasOrderType> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: GasOrderType.values.map((type) {
          final isSelected = type == selectedOrderType;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: type != GasOrderType.values.last ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: isEnabled ? () => onChanged(type) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type == GasOrderType.refill
                            ? Icons.local_gas_station
                            : Icons.swap_horiz,
                        size: 28,
                        color: isEnabled
                            ? (isSelected ? AppColors.primary : AppColors.grey400)
                            : AppColors.grey300,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        type.label,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? (isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary)
                              : AppColors.grey400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.description,
                        style: AppTypography.labelSmall.copyWith(
                          color: isEnabled
                              ? AppColors.textSecondary
                              : AppColors.grey400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Floating summary section (fixed at bottom)
class _FloatingSummary extends StatelessWidget {
  const _FloatingSummary({
    required this.depot,
    required this.product,
    required this.orderType,
  });

  final Provider depot;
  final GasProduct product;
  final GasOrderType orderType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          // Gas icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.propane_tank,
              color: Color(0xFFFF9500),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.brand.name} ${product.bottleSize.kg}kg - ${orderType.label}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${depot.name} • ${depot.distanceText}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stock badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: product.quantityAvailable > 5
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${product.quantityAvailable} dispo',
              style: AppTypography.labelSmall.copyWith(
                color: product.quantityAvailable > 5
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment method selector
class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selectedMethod,
    required this.onChanged,
    required this.isEnabled,
  });

  final String? selectedMethod;
  final ValueChanged<String> onChanged;
  final bool isEnabled;

  static const List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'name': 'Espèces',
      'description': 'Payer à la livraison',
      'icon': Icons.payments_outlined,
    },
    {
      'id': 'wave',
      'name': 'Wave',
      'description': 'Paiement mobile',
      'icon': Icons.phone_android,
    },
    {
      'id': 'wallet',
      'name': 'Portefeuille',
      'description': 'Solde NELO',
      'icon': Icons.account_balance_wallet,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Center(
            child: Text(
              'Sélectionnez d\'abord le type de commande',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey400,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: _paymentMethods.map((method) {
          final isSelected = method['id'] == selectedMethod;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: method != _paymentMethods.last ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: () => onChanged(method['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        size: 24,
                        color: isSelected ? AppColors.primary : AppColors.grey400,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        method['name'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        method['description'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Delivery time info widget
class _DeliveryTimeInfo extends StatelessWidget {
  const _DeliveryTimeInfo({required this.depot});

  final Provider? depot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Livraison estimée',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '30-45 minutes',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Frais de livraison',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '500 FCFA',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
