import 'package:equatable/equatable.dart';
import 'provider_category.dart';

/// Search filter options for provider search
class SearchFilter extends Equatable {
  const SearchFilter({
    this.query,
    this.categoryType,
    this.maxDistance,
    this.minRating,
    this.minPrice,
    this.maxPrice,
    this.isOpenNow,
    this.sortBy = SearchSortBy.relevance,
  });

  /// Search query text
  final String? query;

  /// Filter by provider type
  final ProviderType? categoryType;

  /// Maximum distance in kilometers
  final double? maxDistance;

  /// Minimum rating (1-5)
  final double? minRating;

  /// Minimum price range
  final double? minPrice;

  /// Maximum price range
  final double? maxPrice;

  /// Only show providers that are currently open
  final bool? isOpenNow;

  /// Sort order
  final SearchSortBy sortBy;

  /// Check if any filter is active
  bool get hasActiveFilters =>
      categoryType != null ||
      maxDistance != null ||
      minRating != null ||
      minPrice != null ||
      maxPrice != null ||
      isOpenNow == true;

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (categoryType != null) count++;
    if (maxDistance != null) count++;
    if (minRating != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (isOpenNow == true) count++;
    return count;
  }

  /// Create a copy with updated values
  SearchFilter copyWith({
    String? query,
    ProviderType? categoryType,
    double? maxDistance,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    bool? isOpenNow,
    SearchSortBy? sortBy,
    bool clearCategory = false,
    bool clearDistance = false,
    bool clearRating = false,
    bool clearPrice = false,
    bool clearOpenNow = false,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      categoryType: clearCategory ? null : (categoryType ?? this.categoryType),
      maxDistance: clearDistance ? null : (maxDistance ?? this.maxDistance),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      isOpenNow: clearOpenNow ? null : (isOpenNow ?? this.isOpenNow),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Reset all filters
  SearchFilter clearAll() {
    return SearchFilter(
      query: query,
      sortBy: sortBy,
    );
  }

  @override
  List<Object?> get props => [
        query,
        categoryType,
        maxDistance,
        minRating,
        minPrice,
        maxPrice,
        isOpenNow,
        sortBy,
      ];
}

/// Sort options for search results
enum SearchSortBy {
  relevance,
  distance,
  rating,
  deliveryTime,
  priceAsc,
  priceDesc,
}

/// Extension for sort by labels
extension SearchSortByLabel on SearchSortBy {
  String get label {
    switch (this) {
      case SearchSortBy.relevance:
        return 'Pertinence';
      case SearchSortBy.distance:
        return 'Distance';
      case SearchSortBy.rating:
        return 'Note';
      case SearchSortBy.deliveryTime:
        return 'Temps de livraison';
      case SearchSortBy.priceAsc:
        return 'Prix croissant';
      case SearchSortBy.priceDesc:
        return 'Prix décroissant';
    }
  }

  String get icon {
    switch (this) {
      case SearchSortBy.relevance:
        return 'auto_awesome';
      case SearchSortBy.distance:
        return 'near_me';
      case SearchSortBy.rating:
        return 'star';
      case SearchSortBy.deliveryTime:
        return 'schedule';
      case SearchSortBy.priceAsc:
        return 'arrow_upward';
      case SearchSortBy.priceDesc:
        return 'arrow_downward';
    }
  }
}

/// Predefined distance options
class DistanceOptions {
  static const List<double> values = [0.5, 1.0, 2.0, 5.0, 10.0];

  static String label(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1)} km';
  }
}

/// Predefined rating options
class RatingOptions {
  static const List<double> values = [3.0, 3.5, 4.0, 4.5];

  static String label(double rating) => '$rating+';
}
