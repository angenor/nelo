import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import 'address_picker_sheet.dart';

/// Bottom sheet for gas order configuration
class GasOrderSheet extends StatelessWidget {
  const GasOrderSheet({
    super.key,
    required this.scrollController,
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
    required this.orderType,
    required this.onOrderTypeChanged,
    required this.selectedProduct,
    required this.onOrder,
  });

  final ScrollController scrollController;
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
  final GasOrderType orderType;
  final ValueChanged<GasOrderType> onOrderTypeChanged;
  final GasProduct? selectedProduct;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
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
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
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

          const SizedBox(height: AppSpacing.md),

          // Delivery address
          _buildSectionTitle('Livrer à'),
          _AddressSelector(
            addresses: addresses,
            selectedAddress: selectedAddress,
            onChanged: onAddressChanged,
          ),

          const Divider(height: AppSpacing.xl),

          // Bottle size
          _buildSectionTitle('Taille de bouteille'),
          _BottleSizeSelector(
            sizes: availableSizes,
            selectedSize: selectedSize,
            onChanged: onSizeChanged,
          ),

          const Divider(height: AppSpacing.xl),

          // Brand
          if (availableBrands.isNotEmpty) ...[
            _buildSectionTitle('Marque'),
            _BrandSelector(
              brands: availableBrands,
              selectedBrand: selectedBrand,
              onChanged: onBrandChanged,
            ),
            const Divider(height: AppSpacing.xl),
          ],

          // Order type (refill/exchange)
          _buildSectionTitle('Type de commande'),
          _OrderTypeSelector(
            orderType: orderType,
            onChanged: onOrderTypeChanged,
          ),

          const Divider(height: AppSpacing.xl),

          // Order summary
          _OrderSummary(
            depot: depot,
            product: selectedProduct,
            orderType: orderType,
          ),

          const SizedBox(height: AppSpacing.md),

          // Order button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ElevatedButton(
              onPressed: selectedProduct != null ? onOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                disabledBackgroundColor: AppColors.grey300,
              ),
              child: Text(
                'Commander maintenant',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
        // Permet au bottom sheet de remonter au-dessus du clavier
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
                child: Container(
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.grey400,
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
  });

  final List<GasBrand> brands;
  final GasBrand? selectedBrand;
  final ValueChanged<GasBrand> onChanged;

  @override
  Widget build(BuildContext context) {
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
            onTap: () => onChanged(brand),
            child: Container(
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
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
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
    required this.orderType,
    required this.onChanged,
  });

  final GasOrderType orderType;
  final ValueChanged<GasOrderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: GasOrderType.values.map((type) {
          final isSelected = type == orderType;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: type != GasOrderType.values.last ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: Container(
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.grey400,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        type.label,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.description,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
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

/// Order summary section
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.depot,
    required this.product,
    required this.orderType,
  });

  final Provider? depot;
  final GasProduct? product;
  final GasOrderType orderType;

  @override
  Widget build(BuildContext context) {
    if (product == null || depot == null) {
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
              'Sélectionnez une taille et une marque',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final formattedPrice = product!.formatPrice(orderType);

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
        child: Column(
          children: [
            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  formattedPrice,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Depot info
            Row(
              children: [
                Icon(
                  Icons.store,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    depot!.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  depot!.distanceText,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Stock info
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: product!.quantityAvailable > 5
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${product!.quantityAvailable} en stock',
                  style: AppTypography.bodySmall.copyWith(
                    color: product!.quantityAvailable > 5
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Delivery info
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Livreur auto-assigné',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
