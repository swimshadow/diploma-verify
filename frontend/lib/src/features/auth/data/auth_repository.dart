import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/token_storage.dart';

class AuthUser {
  final String accountId;
  final String email;
  final String role;
  final Map<String, dynamic> profile;

  const AuthUser({
    required this.accountId,
    required this.email,
    required this.role,
    required this.profile,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        accountId: json['account_id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        profile: (json['profile'] as Map<String, dynamic>?) ?? {},
      );
}

class AuthRepository {
  static const _tag = 'AuthRepository';
  final _log = AppLogger.instance;
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage {
    _log.info(_tag, 'AuthRepository создан');
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    _log.info(_tag, 'login() → POST ${AppConstants.loginPath} email=$email');
    try {
      final response = await _dio.post(
        AppConstants.loginPath,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      _log.info(_tag, 'login() ← OK: role=${data['role']}');
      await _tokenStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return AuthUser(
        accountId: '',
        email: email,
        role: data['role'] as String,
        profile: (data['profile'] as Map<String, dynamic>?) ?? {},
      );
    } catch (e, st) {
      _log.error(_tag, 'login() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> profile,
  }) async {
    _log.info(_tag, 'register() → POST ${AppConstants.registerPath} email=$email role=$role');
    try {
      await _dio.post(
        AppConstants.registerPath,
        data: {
          'email': email,
          'password': password,
          'role': role,
          'profile': profile,
        },
      );
      _log.info(_tag, 'register() ← OK');
    } catch (e, st) {
      _log.error(_tag, 'register() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<AuthUser> me() async {
    _log.info(_tag, 'me() → GET ${AppConstants.mePath}');
    try {
      final response = await _dio.get(AppConstants.mePath);
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);
      _log.info(_tag, 'me() ← OK: role=${user.role}, email=${user.email}');
      return user;
    } catch (e, st) {
      _log.error(_tag, 'me() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    _log.info(_tag, 'logout() → POST ${AppConstants.logoutPath}');
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(
          AppConstants.logoutPath,
          data: {'refresh_token': refreshToken},
        );
        _log.info(_tag, 'logout() ← OK');
      } else {
        _log.warning(_tag, 'logout() нет refresh токена — пропускаем запрос');
      }
    } catch (e) {
      _log.warning(_tag, 'logout() ошибка при запросе: $e', e);
    } finally {
      await _tokenStorage.clearTokens();
      _log.info(_tag, 'logout() → токены очищены');
    }
  }

  Future<bool> hasSession() async {
    final has = await _tokenStorage.hasTokens();
    _log.debug(_tag, 'hasSession() → $has');
    return has;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profile) async {
    _log.info(_tag, 'updateProfile() → PATCH ${AppConstants.profilePath}');
    try {
      final response = await _dio.patch(
        AppConstants.profilePath,
        data: {'profile': profile},
      );
      _log.info(_tag, 'updateProfile() ← OK');
      return (response.data as Map<String, dynamic>)['profile'] as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'updateProfile() ОШИБКА', e, st);
      rethrow;
    }
  }
}
