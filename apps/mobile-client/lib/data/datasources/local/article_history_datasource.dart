import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Local data source for article history in errands service
/// Stores recent article entries for autocomplete suggestions
@lazySingleton
class ArticleHistoryDataSource {
  ArticleHistoryDataSource(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const String _key = 'article_history';
  static const int _maxItems = 20;

  /// Get article history list
  Future<List<String>> getHistory() async {
    try {
      final jsonStr = await _secureStorage.read(key: _key);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      // If decoding fails, return empty list
      return [];
    }
  }

  /// Add an article to history
  /// Moves to top if already exists, limits to max items
  Future<void> addToHistory(String article) async {
    if (article.trim().isEmpty) return;

    final history = await getHistory();

    // Remove if already exists (will be re-added at top)
    history.remove(article);

    // Add to top
    history.insert(0, article);

    // Limit size
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }

    await _secureStorage.write(key: _key, value: json.encode(history));
  }

  /// Remove a specific article from history
  Future<void> removeFromHistory(String article) async {
    final history = await getHistory();
    history.remove(article);
    await _secureStorage.write(key: _key, value: json.encode(history));
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _secureStorage.delete(key: _key);
  }
}
