class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://localhost:8000';
  static const String publicBaseUrl = 'http://localhost:8000';
  static const String appName = 'DiplomaVerify';

  // Auth API
  static const String authPath = '/api/auth';
  static const String loginPath = '$authPath/login';
  static const String registerPath = '$authPath/register';
  static const String refreshPath = '$authPath/refresh';
  static const String logoutPath = '$authPath/logout';
  static const String mePath = '$authPath/me';
  static const String profilePath = '$authPath/profile';

  // Student API (diploma-service)
  static const String studentDiplomasPath = '/api/student/diplomas';

  // Employer API (verify-service)
  static const String verifyQrPath = '/api/verify/qr';
  static const String verifyManualPath = '/api/verify/manual';
  static const String employerHintPath = '/api/employer/verification-hint';

  // University API
  static const String universityDiplomasPath = '/api/university/diplomas';

  // Notifications API
  static const String notificationsPath = '/api/notifications';

  // Files API
  static const String filesPath = '/api/files';

  // Certificates API
  static const String certificatesPath = '/api/certificates';

  // AI API
  static const String aiExtractPath = '/api/ai/extract';

  // Blockchain API
  static const String blockchainPath = '/api/blockchain';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Payload encryption (AES-256-GCM). Base64-encoded 32-byte key.
  // Must match PAYLOAD_ENCRYPTION_KEY on backend.
  static const String payloadEncryptionKey =
      String.fromEnvironment('PAYLOAD_ENCRYPTION_KEY',
          defaultValue: 'RGlwbG9tYVZlcmlmeUFFUzI1NlNlY3JldEtleTB4T0s=');
}
