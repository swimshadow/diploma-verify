import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
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
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      AppConstants.loginPath,
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
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
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> profile,
  }) async {
    await _dio.post(
      AppConstants.registerPath,
      data: {
        'email': email,
        'password': password,
        'role': role,
        'profile': profile,
      },
    );
  }

  Future<AuthUser> me() async {
    final response = await _dio.get(AppConstants.mePath);
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post(AppConstants.logoutPath);
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  Future<bool> hasSession() => _tokenStorage.hasTokens();
}
