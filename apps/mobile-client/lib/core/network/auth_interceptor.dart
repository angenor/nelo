import 'package:dio/dio.dart';
import '../di/injection.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

/// Interceptor for handling authentication tokens
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authLocalDataSource = getIt<AuthLocalDataSource>();
    final token = await authLocalDataSource.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final success = await _refreshToken();
        if (success) {
          // Retry the original request
          final response = await _retryRequest(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Refresh failed, logout user
        await _logout();
      } finally {
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final authLocalDataSource = getIt<AuthLocalDataSource>();
    final refreshToken = await authLocalDataSource.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      // TODO: Implement actual refresh token API call when backend is ready
      // final response = await _dio.post(
      //   ApiEndpoints.refreshToken,
      //   data: {'refresh_token': refreshToken},
      // );
      //
      // if (response.statusCode == 200) {
      //   await authLocalDataSource.saveTokens(
      //     accessToken: response.data['access_token'],
      //     refreshToken: response.data['refresh_token'],
      //   );
      //   return true;
      // }

      // For now, return false to trigger logout
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final authLocalDataSource = getIt<AuthLocalDataSource>();
    final token = await authLocalDataSource.getAccessToken();

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _logout() async {
    final authLocalDataSource = getIt<AuthLocalDataSource>();
    await authLocalDataSource.clearAuthData();
    // TODO: Navigate to login screen
    // This should be handled by a global auth state listener
  }
}
