import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Full-screen product detail view
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final Product product;
  final void Function(Product product, int quantity, Map<String, List<String>> selectedOptions) onAddToCart;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image header
          _buildSliverAppBar(),

          // Product info
          SliverToBoxAdapter(
            child: _buildProductInfo(),
          ),

          // Options
          if (widget.product.hasOptions)
            SliverToBoxAdapter(
              child: _buildOptionsSection(),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),

      // Bottom bar with quantity and add button
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: CircleAvatar(
          backgroundColor: AppColors.surface,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            color: AppColors.textPrimary,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: CircleAvatar(
            backgroundColor: AppColors.surface,
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share product
              },
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product image
            if (widget.product.imageUrl != null)
              Hero(
                tag: 'product_${widget.product.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.product.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.grey100,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: AppColors.grey300,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.grey100,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: AppColors.grey300,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                color: AppColors.grey100,
                child: const Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: AppColors.grey300,
                  ),
                ),
              ),

            // Badges
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Row(
                children: [
                  if (widget.product.isFeatured)
                    _Badge(
                      icon: Icons.star,
                      label: 'Populaire',
                      color: AppColors.rating,
                    ),
                  if (widget.product.isVegetarian) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _Badge(
                      icon: Icons.eco,
                      label: 'Végétarien',
                      color: AppColors.success,
                    ),
                  ],
                  if (widget.product.isSpicy) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _Badge(
                      icon: Icons.whatshot,
                      label: 'Épicé',
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            widget.product.name,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Price
          Row(
            children: [
              Text(
                widget.product.hasOptions
                    ? 'À partir de ${widget.product.priceText}'
                    : widget.product.priceText,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.product.hasDiscount) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.product.originalPriceText!,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${widget.product.discountPercentage}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Info chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (widget.product.prepTime != null)
                _InfoChip(
                  icon: Icons.access_time,
                  label: '${widget.product.prepTime} min',
                ),
              if (widget.product.hasOptions)
                _InfoChip(
                  icon: Icons.tune,
                  label: 'Options disponibles',
                ),
            ],
          ),

          // Description
          if (widget.product.description != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Description',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.product.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'Personnalisez votre commande',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          ...widget.product.options.map((option) => _buildOptionGroup(option)),
        ],
      ),
    );
  }

  Widget _buildOptionGroup(MenuOption option) {
    final selectedIds = _selectedOptions[option.id] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
              if (option.isRequired)
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
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: option.isSingleSelection
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: option.isMultipleSelection
                            ? BorderRadius.circular(4)
                            : null,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.grey400,
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

                    const SizedBox(width: AppSpacing.md),

                    // Item name
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          decoration: isAvailable ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),

                    // Price adjustment
                    if (item.priceAdjustment != 0)
                      Text(
                        item.priceAdjustmentText,
                        style: AppTypography.titleSmall.copyWith(
                          color: item.priceAdjustment > 0
                              ? AppColors.primary
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    if (!isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Indisponible',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
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

  Widget _buildBottomBar() {
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
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                  color: _quantity > 1 ? AppColors.primary : AppColors.grey400,
                  iconSize: 20,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$_quantity',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                  color: AppColors.primary,
                  iconSize: 20,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: _canAddToCart
                  ? () {
                      widget.onAddToCart(
                        widget.product,
                        _quantity,
                        _selectedOptions,
                      );
                      context.pop();
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
                  const Icon(Icons.shopping_cart_outlined, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ajouter',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${_totalPrice}F',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
