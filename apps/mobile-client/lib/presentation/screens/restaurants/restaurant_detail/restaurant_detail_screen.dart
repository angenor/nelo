import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../domain/entities/entities.dart';
import '../../cart/cart_screen.dart';
import 'widgets/restaurant_info_section.dart';
import 'widgets/menu_category_section.dart';
import 'widgets/floating_cart_button.dart';

/// Restaurant detail screen showing menu and info
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late Provider _restaurant;
  late List<MenuCategory> _menuCategories;
  late List<ProviderSchedule> _schedules;

  // Cart state with full CartItem objects
  final List<CartItem> _cartItems = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  void _loadRestaurant() {
    // Find restaurant from mock data
    _restaurant = MockData.allProviders.firstWhere(
      (p) => p.id == widget.restaurantId,
      orElse: () => MockData.popularProviders.first,
    );
    _menuCategories = MockData.getMenuForProvider(widget.restaurantId);
    _schedules = MockData.getSchedulesForProvider(widget.restaurantId);
  }

  /// Get quantity map for display in menu (product.id -> total quantity)
  Map<String, int> get _cartQuantityMap {
    final map = <String, int>{};
    for (final item in _cartItems) {
      map[item.product.id] = (map[item.product.id] ?? 0) + item.quantity;
    }
    return map;
  }

  void _addToCart(Product product) {
    setState(() {
      // Check if same product without options already exists
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id && item.selectedOptions.isEmpty,
      );

      if (existingIndex >= 0) {
        // Update quantity of existing item
        final existing = _cartItems[existingIndex];
        _cartItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      } else {
        // Add new item
        _cartItems.add(CartItem(
          id: _uuid.v4(),
          product: product,
          quantity: 1,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ajouté au panier'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _removeFromCart(Product product) {
    setState(() {
      // Find item for this product (prefer items without options first)
      final index = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (index >= 0) {
        final item = _cartItems[index];
        if (item.quantity > 1) {
          _cartItems[index] = item.copyWith(quantity: item.quantity - 1);
        } else {
          _cartItems.removeAt(index);
        }
      }
    });
  }

  void _addWithOptions(Product product, int quantity, Map<String, List<String>> selectedOptions) {
    setState(() {
      // Always add as new item when options are selected (each combination is unique)
      _cartItems.add(CartItem(
        id: _uuid.v4(),
        product: product,
        quantity: quantity,
        selectedOptions: selectedOptions,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} x$quantity ajouté au panier'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _updateCartItemQuantity(CartItem item, int newQuantity) {
    setState(() {
      final index = _cartItems.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        if (newQuantity > 0) {
          _cartItems[index] = item.copyWith(quantity: newQuantity);
        } else {
          _cartItems.removeAt(index);
        }
      }
    });
  }

  void _removeCartItem(CartItem item) {
    setState(() {
      _cartItems.removeWhere((i) => i.id == item.id);
    });
  }

  int get _cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  int get _cartTotal => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CartScreen(
          restaurantName: _restaurant.name,
          items: List.from(_cartItems),
          onUpdateQuantity: _updateCartItemQuantity,
          onRemoveItem: _removeCartItem,
          onCheckout: (instructions) {
            // TODO: Navigate to checkout
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Redirection vers le paiement...'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with cover image
          _buildSliverAppBar(),

          // Restaurant info section
          SliverToBoxAdapter(
            child: RestaurantInfoSection(
              restaurant: _restaurant,
              schedules: _schedules,
            ),
          ),

          // Menu categories
          ..._menuCategories.map((category) => SliverToBoxAdapter(
            child: MenuCategorySection(
              category: category,
              cartItems: _cartQuantityMap,
              onAddToCart: _addToCart,
              onRemoveFromCart: _removeFromCart,
              onAddWithOptions: _addWithOptions,
            ),
          )),

          // Bottom spacing for floating button
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Floating cart button
      floatingActionButton: _cartItemCount > 0
          ? FloatingCartButton(
              itemCount: _cartItemCount,
              total: _cartTotal,
              onPressed: _openCart,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
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
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                // Toggle favorite
              },
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: CircleAvatar(
            backgroundColor: AppColors.surface,
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share restaurant
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
            // Cover image
            if (_restaurant.coverImageUrl != null)
              CachedNetworkImage(
                imageUrl: _restaurant.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.grey100,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.restaurant,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.restaurant,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.overlay,
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Restaurant info overlay
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: _restaurant.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _restaurant.logoUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.restaurant,
                              color: AppColors.primary,
                              size: 36,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Name and rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _restaurant.name,
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.rating,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _restaurant.ratingText,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '(${_restaurant.ratingCount} avis)',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _restaurant.isOpen
                                    ? AppColors.success
                                    : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _restaurant.isOpen ? 'Ouvert' : 'Fermé',
                              style: AppTypography.labelSmall.copyWith(
                                color: _restaurant.isOpen
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
