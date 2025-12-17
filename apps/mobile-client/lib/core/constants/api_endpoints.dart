/// API endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User endpoints
  static const String profile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String addresses = '/users/me/addresses';

  // Providers endpoints
  static const String providers = '/providers';
  static String providerDetail(String id) => '/providers/$id';
  static String providerProducts(String id) => '/providers/$id/products';

  // Products endpoints
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';

  // Orders endpoints
  static const String orders = '/orders';
  static String orderDetail(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  // Wallet endpoints
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletRecharge = '/wallet/recharge';
}
