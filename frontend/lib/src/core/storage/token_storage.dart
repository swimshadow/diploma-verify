import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

class TokenStorage {
  static const _tag = 'TokenStorage';
  final _log = AppLogger.instance;
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _log.info(_tag, 'TokenStorage создан');
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _log.info(_tag, 'saveTokens() → сохранение access + refresh токенов');
    await _storage.write(
        key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: AppConstants.refreshTokenKey, value: refreshToken);
    _log.info(_tag, 'saveTokens() ← OK');
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    _log.debug(_tag, 'getAccessToken() → ${token != null ? "есть" : "null"}');
    return token;
  }

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: AppConstants.refreshTokenKey);
    _log.debug(_tag, 'getRefreshToken() → ${token != null ? "есть" : "null"}');
    return token;
  }

  Future<void> clearTokens() async {
    _log.info(_tag, 'clearTokens() → удаление всех токенов');
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    _log.info(_tag, 'clearTokens() ← OK');
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    final has = token != null && token.isNotEmpty;
    _log.debug(_tag, 'hasTokens() → $has');
    return has;
  }
}
