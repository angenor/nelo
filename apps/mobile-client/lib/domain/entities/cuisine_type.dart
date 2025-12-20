/// Cuisine types for restaurant filtering
enum CuisineType {
  african,
  ivorian,
  fastFood,
  grilled,
  seafood,
  european,
  asian,
  other,
}

/// Extension for cuisine type labels
extension CuisineTypeLabel on CuisineType {
  String get label {
    switch (this) {
      case CuisineType.african:
        return 'Africain';
      case CuisineType.ivorian:
        return 'Ivoirien';
      case CuisineType.fastFood:
        return 'Fast Food';
      case CuisineType.grilled:
        return 'Grillades';
      case CuisineType.seafood:
        return 'Fruits de mer';
      case CuisineType.european:
        return 'Europeen';
      case CuisineType.asian:
        return 'Asiatique';
      case CuisineType.other:
        return 'Autre';
    }
  }

  String get icon {
    switch (this) {
      case CuisineType.african:
        return '🍲';
      case CuisineType.ivorian:
        return '🇨🇮';
      case CuisineType.fastFood:
        return '🍔';
      case CuisineType.grilled:
        return '🍖';
      case CuisineType.seafood:
        return '🐟';
      case CuisineType.european:
        return '🍝';
      case CuisineType.asian:
        return '🍜';
      case CuisineType.other:
        return '🍽️';
    }
  }

  /// Placeholder image URL for visual filter
  String get imageUrl {
    return 'https://picsum.photos/seed/cuisine-$name/100/100';
  }
}
