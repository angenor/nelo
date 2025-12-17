import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';

/// Local data source for authentication
@lazySingleton
class AuthLocalDataSource {
  AuthLocalDataSource(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final value = await _secureStorage.read(key: AppConstants.onboardingKey);
    return value == 'true';
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await _secureStorage.write(
      key: AppConstants.onboardingKey,
      value: 'true',
    );
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  /// Save tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: accessToken);
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Clear all auth data (logout)
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userKey);
  }
}
