import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../domain/entities/entities.dart';
import 'product_options_sheet.dart';

/// Menu category section with products
class MenuCategorySection extends StatelessWidget {
  const MenuCategorySection({
    super.key,
    required this.category,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onAddWithOptions,
  });

  final MenuCategory category;
  final Map<String, int> cartItems;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onRemoveFromCart;
  final void Function(Product product, int quantity, Map<String, List<String>> selectedOptions) onAddWithOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            category.name,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Products list
        ...category.products.map((product) => _ProductCard(
              product: product,
              quantity: cartItems[product.id] ?? 0,
              onAddToCart: () {
                if (product.hasOptions) {
                  _showOptionsSheet(context, product);
                } else {
                  onAddToCart(product);
                }
              },
              onRemoveFromCart: () => onRemoveFromCart(product),
            )),

        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  void _showOptionsSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ProductOptionsSheet(
          product: product,
          onAddToCart: onAddWithOptions,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product detail
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isFeatured) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rating,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'Populaire',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (product.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xs),

                    // Tags row
                    Row(
                      children: [
                        if (product.isVegetarian) ...[
                          _ProductTag(
                            icon: Icons.eco,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (product.isSpicy) ...[
                          _ProductTag(
                            icon: Icons.whatshot,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (product.hasOptions) ...[
                          _ProductTag(
                            icon: Icons.tune,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (product.prepTime != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.prepTime} min',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Price
                    Row(
                      children: [
                        Text(
                          product.hasOptions
                              ? 'À partir de ${product.priceText}'
                              : product.priceText,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            product.originalPriceText!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Product image and add button
              Column(
                children: [
                  // Image
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      color: AppColors.grey100,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: AppColors.grey300,
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: AppColors.grey300,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                color: AppColors.grey300,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Add/Quantity button
                  _QuantityButton(
                    quantity: quantity,
                    hasOptions: product.hasOptions,
                    onAdd: onAddToCart,
                    onRemove: onRemoveFromCart,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTag extends StatelessWidget {
  const _ProductTag({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.quantity,
    required this.hasOptions,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final bool hasOptions;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Show +/- controls when quantity > 0
    if (quantity > 0) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minus button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.remove,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),

            // Quantity
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              child: Text(
                '$quantity',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Plus button
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show "Ajouter" button when quantity is 0
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.white),
            const SizedBox(width: 2),
            Text(
              'Ajouter',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
