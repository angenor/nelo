import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import 'widgets/widgets.dart';

/// Search screen with filters and results
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryType,
  });

  final String? initialQuery;
  final String? initialCategoryType;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  SearchFilter _filter = const SearchFilter();
  List<Provider> _results = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();

    // Initialize with query params if provided
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategoryType != null) {
      _filter = _filter.copyWith(
        categoryType: _getCategoryTypeFromSlug(widget.initialCategoryType!),
      );
    }

    // Perform initial search
    _performSearch();

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  ProviderType? _getCategoryTypeFromSlug(String slug) {
    switch (slug) {
      case 'restaurants':
        return ProviderType.restaurant;
      case 'gaz':
        return ProviderType.gasDepot;
      case 'epiceries':
        return ProviderType.grocery;
      case 'pharmacies':
        return ProviderType.pharmacy;
      case 'pressing':
        return ProviderType.pressing;
      case 'artisans':
        return ProviderType.artisan;
      default:
        return null;
    }
  }

  void _performSearch() {
    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      var results = MockData.allProviders;

      // Filter by query
      if (query.isNotEmpty) {
        results = results.where((provider) {
          return provider.name.toLowerCase().contains(query) ||
              (provider.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Filter by category type
      if (_filter.categoryType != null) {
        results =
            results.where((p) => p.type == _filter.categoryType).toList();
      }

      // Filter by distance
      if (_filter.maxDistance != null) {
        results = results
            .where((p) =>
                p.distanceKm != null && p.distanceKm! <= _filter.maxDistance!)
            .toList();
      }

      // Filter by rating
      if (_filter.minRating != null) {
        results = results
            .where((p) =>
                p.averageRating != null &&
                p.averageRating! >= _filter.minRating!)
            .toList();
      }

      // Filter by open status
      if (_filter.isOpenNow == true) {
        results = results.where((p) => p.isOpen).toList();
      }

      // Sort results
      results = _sortResults(results);

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    });
  }

  List<Provider> _sortResults(List<Provider> results) {
    switch (_filter.sortBy) {
      case SearchSortBy.distance:
        return [...results]..sort((a, b) {
            final distA = a.distanceKm ?? double.infinity;
            final distB = b.distanceKm ?? double.infinity;
            return distA.compareTo(distB);
          });
      case SearchSortBy.rating:
        return [...results]..sort((a, b) {
            final ratingA = a.averageRating ?? 0;
            final ratingB = b.averageRating ?? 0;
            return ratingB.compareTo(ratingA);
          });
      case SearchSortBy.deliveryTime:
        return [...results]..sort((a, b) {
            final timeA = a.averagePrepTime.toDouble();
            final timeB = b.averagePrepTime.toDouble();
            return timeA.compareTo(timeB);
          });
      case SearchSortBy.priceAsc:
        return [...results]..sort((a, b) {
            final priceA = a.minOrderAmount;
            final priceB = b.minOrderAmount;
            return priceA.compareTo(priceB);
          });
      case SearchSortBy.priceDesc:
        return [...results]..sort((a, b) {
            final priceA = a.minOrderAmount;
            final priceB = b.minOrderAmount;
            return priceB.compareTo(priceA);
          });
      case SearchSortBy.relevance:
        // Featured first, then by rating
        return [...results]..sort((a, b) {
            if (a.isFeatured && !b.isFeatured) return -1;
            if (!a.isFeatured && b.isFeatured) return 1;
            final ratingA = a.averageRating ?? 0;
            final ratingB = b.averageRating ?? 0;
            return ratingB.compareTo(ratingA);
          });
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    _performSearch();
  }

  void _onFilterChanged(SearchFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
    _performSearch();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFiltersSheet(
        currentFilter: _filter,
        onApply: (newFilter) {
          Navigator.pop(context);
          _onFilterChanged(newFilter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search input with back button
            SearchInput(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (_) => _performSearch(),
              onSubmitted: (_) {
                _searchFocusNode.unfocus();
                _performSearch();
              },
              onClear: () {
                _searchController.clear();
                _performSearch();
              },
            ),

            // Filter chips
            SearchFilterChips(
              filter: _filter,
              onFilterTap: _openFilters,
              onCategoryRemove: () {
                _onFilterChanged(_filter.copyWith(clearCategory: true));
              },
              onOpenNowToggle: () {
                _onFilterChanged(
                    _filter.copyWith(isOpenNow: !(_filter.isOpenNow ?? false)));
              },
            ),

            // Content area
            Expanded(
              child: Stack(
                children: [
                  // Results or suggestions
                  _showSuggestions && _searchController.text.isEmpty
                      ? SearchSuggestions(
                          suggestions: MockData.searchSuggestions,
                          recentSearches: MockData.recentSearches,
                          onSuggestionTap: _onSuggestionTap,
                          onRecentTap: _onSuggestionTap,
                        )
                      : _isMapView
                          ? SearchMapView(
                              providers: _results,
                              onProviderTap: (provider) {
                                // TODO: Navigate to provider detail
                              },
                            )
                          : SearchResults(
                              results: _results,
                              isLoading: _isSearching,
                              onProviderTap: (provider) {
                                // TODO: Navigate to provider detail
                              },
                            ),

                  // View toggle button
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        setState(() {
                          _isMapView = !_isMapView;
                        });
                      },
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        _isMapView ? Icons.list : Icons.map,
                        color: Colors.white,
                      ),
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
