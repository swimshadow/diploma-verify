class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://localhost:8000';
  static const String appName = 'DiplomaVerify';

  // API paths
  static const String authPath = '/api/auth';
  static const String loginPath = '$authPath/login';
  static const String registerPath = '$authPath/register';
  static const String refreshPath = '$authPath/refresh';
  static const String logoutPath = '$authPath/logout';
  static const String mePath = '$authPath/me';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
