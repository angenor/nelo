import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'widgets/widgets.dart';

/// Home screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // TODO: Refresh data from API
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with location
                HomeHeader(
                  location: 'Tiassalé, Centre-ville',
                  onLocationTap: () {
                    // TODO: Open location picker
                  },
                  onNotificationTap: () {
                    // TODO: Navigate to notifications
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // Search bar
                HomeSearchBar(
                  onTap: () => context.push(AppRoutes.search),
                ),

                const SizedBox(height: AppSpacing.md),

                // Categories
                CategoriesSection(
                  categories: MockData.categories,
                  onCategoryTap: (category) {
                    // TODO: Navigate to category screen
                    context.push('${AppRoutes.search}?type=${category.slug}');
                  },
                ),

                // Promotions carousel
                PromotionsCarousel(
                  promotions: MockData.promotions,
                  onPromotionTap: (promotion) {
                    // TODO: Navigate to promotion detail or apply code
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Popular restaurants section
                SectionHeader(
                  title: 'Restaurants populaires',
                  subtitle: 'Les mieux notés',
                  onActionTap: () =>
                      context.push('${AppRoutes.search}?type=restaurants'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PopularProvidersSection(
                  providers: MockData.popularProviders
                      .where((p) => p.type == ProviderType.restaurant)
                      .toList(),
                  onProviderTap: (provider) {
                    context.push('/provider/${provider.id}');
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Nearby section
                SectionHeader(
                  title: 'Près de chez vous',
                  subtitle: 'À moins de 2 km',
                  onActionTap: () => context.push(AppRoutes.search),
                ),
                const SizedBox(height: AppSpacing.sm),
                _NearbyProvidersSection(
                  providers: MockData.nearbyProviders,
                  onProviderTap: (provider) {
                    context.push('/provider/${provider.id}');
                  },
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal list of popular providers
class _PopularProvidersSection extends StatelessWidget {
  const _PopularProvidersSection({
    required this.providers,
    this.onProviderTap,
  });

  final List<Provider> providers;
  final void Function(Provider provider)? onProviderTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final provider = providers[index];
          return ProviderCard(
            provider: provider,
            onTap: () => onProviderTap?.call(provider),
          );
        },
      ),
    );
  }
}

/// Vertical list of nearby providers
class _NearbyProvidersSection extends StatelessWidget {
  const _NearbyProvidersSection({
    required this.providers,
    this.onProviderTap,
  });

  final List<Provider> providers;
  final void Function(Provider provider)? onProviderTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: providers.map((provider) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ProviderListTile(
              provider: provider,
              onTap: () => onProviderTap?.call(provider),
            ),
          );
        }).toList(),
      ),
    );
  }
}
