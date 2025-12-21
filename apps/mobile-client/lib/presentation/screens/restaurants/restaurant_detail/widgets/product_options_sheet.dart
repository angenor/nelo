import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../domain/entities/entities.dart';

/// Bottom sheet for selecting product options
class ProductOptionsSheet extends StatefulWidget {
  const ProductOptionsSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final Product product;
  final void Function(Product product, int quantity, Map<String, List<String>> selectedOptions) onAddToCart;

  @override
  State<ProductOptionsSheet> createState() => _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends State<ProductOptionsSheet> {
  int _quantity = 1;
  // Map of optionId -> List of selected itemIds
  final Map<String, List<String>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    // Pre-select first item for required single-selection options
    for (final option in widget.product.options) {
      if (option.isRequired && option.isSingleSelection && option.items.isNotEmpty) {
        _selectedOptions[option.id] = [option.items.first.id];
      }
    }
  }

  int get _totalPrice {
    int base = widget.product.price;
    int optionsTotal = 0;

    for (final option in widget.product.options) {
      final selectedIds = _selectedOptions[option.id] ?? [];
      for (final item in option.items) {
        if (selectedIds.contains(item.id)) {
          optionsTotal += item.priceAdjustment;
        }
      }
    }

    return (base + optionsTotal) * _quantity;
  }

  bool get _canAddToCart {
    // Check if all required options are selected
    for (final option in widget.product.options) {
      if (option.isRequired) {
        final selectedIds = _selectedOptions[option.id] ?? [];
        if (selectedIds.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _toggleSingleOption(MenuOption option, MenuOptionItem item) {
    setState(() {
      _selectedOptions[option.id] = [item.id];
    });
  }

  void _toggleMultipleOption(MenuOption option, MenuOptionItem item) {
    setState(() {
      final current = _selectedOptions[option.id] ?? [];
      if (current.contains(item.id)) {
        current.remove(item.id);
      } else {
        if (current.length < option.maxSelections) {
          current.add(item.id);
        }
      }
      _selectedOptions[option.id] = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product header
                  _buildProductHeader(),

                  const SizedBox(height: AppSpacing.lg),

                  // Options
                  ...widget.product.options.map((option) => _buildOptionSection(option)),

                  const SizedBox(height: AppSpacing.lg),

                  // Quantity selector
                  _buildQuantitySelector(),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),

          // Add to cart button
          _buildAddToCartButton(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: AppColors.grey100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: widget.product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.product.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.grey300,
                    size: 32,
                  ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.product.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.product.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                'À partir de ${widget.product.priceText}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionSection(MenuOption option) {
    final isRequired = option.isRequired;
    final selectedIds = _selectedOptions[option.id] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option header
          Row(
            children: [
              Text(
                option.name,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Obligatoire',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.error,
                      fontSize: 10,
                    ),
                  ),
                )
              else
                Text(
                  option.isMultipleSelection
                      ? '(max ${option.maxSelections})'
                      : '(optionnel)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Option items
          ...option.items.map((item) {
            final isSelected = selectedIds.contains(item.id);
            final isAvailable = item.isAvailable;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      if (option.isSingleSelection) {
                        _toggleSingleOption(option, item);
                      } else {
                        _toggleMultipleOption(option, item);
                      }
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: option.isSingleSelection
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: option.isMultipleSelection
                            ? BorderRadius.circular(4)
                            : null,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey400,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.white,
                            )
                          : null,
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // Item name
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          decoration: isAvailable
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),

                    // Price adjustment
                    if (item.priceAdjustment != 0)
                      Text(
                        item.priceAdjustmentText,
                        style: AppTypography.labelMedium.copyWith(
                          color: item.priceAdjustment > 0
                              ? AppColors.primary
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    if (!isAvailable)
                      Text(
                        'Indisponible',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Quantité',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        // Quantity controls
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            children: [
              // Minus button
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove),
                color: _quantity > 1 ? AppColors.primary : AppColors.grey400,
                iconSize: 20,
              ),

              // Quantity
              SizedBox(
                width: 40,
                child: Text(
                  '$_quantity',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Plus button
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
                color: AppColors.primary,
                iconSize: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canAddToCart
              ? () {
                  widget.onAddToCart(
                    widget.product,
                    _quantity,
                    _selectedOptions,
                  );
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.grey300,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ajouter au panier',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_totalPrice}F',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
