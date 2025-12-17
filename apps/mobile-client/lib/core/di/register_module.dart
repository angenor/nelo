import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../constants/app_constants.dart';

/// Module for registering third-party dependencies
@module
abstract class RegisterModule {
  /// Provides Dio HTTP client
  @lazySingleton
  Dio get dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: AppConstants.defaultTimeout),
        receiveTimeout: const Duration(seconds: AppConstants.defaultTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging in debug mode
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    return dio;
  }

  /// Provides secure storage for tokens
  @lazySingleton
  FlutterSecureStorage get secureStorage {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }
}
