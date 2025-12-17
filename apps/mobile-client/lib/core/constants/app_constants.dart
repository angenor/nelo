/// Application constants
class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'NELO';

  /// API base URL
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';

  /// Default timeout for API requests (in seconds)
  static const int defaultTimeout = 30;

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Shared preferences keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';
  static const String languageKey = 'language';
}
