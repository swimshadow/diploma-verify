import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../storage/token_storage.dart';
import '../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final token = await _tokenStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
      await _tokenStorage.clearTokens();
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final keyB64 = AppConstants.payloadEncryptionKey;
      Map<String, dynamic> body = {'refresh_token': refreshToken};
      final headers = <String, String>{};

      if (keyB64.isNotEmpty) {
        final key = encrypt.Key.fromBase64(keyB64);
        final iv = encrypt.IV.fromSecureRandom(12);
        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.gcm),
        );
        final encrypted = encrypter.encrypt(jsonEncode(body), iv: iv);
        final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
        body = {'_enc': base64Encode(combined)};
        headers['X-Encrypted'] = '1';
      }

      final response = await Dio().post(
        '${AppConstants.apiBaseUrl}${AppConstants.refreshPath}',
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        dynamic data = response.data;

        // Decrypt response if encrypted
        if (data is Map && data.containsKey('_enc') && keyB64.isNotEmpty) {
          final key = encrypt.Key.fromBase64(keyB64);
          final raw = base64Decode(data['_enc'] as String);
          final iv = encrypt.IV(Uint8List.fromList(raw.sublist(0, 12)));
          final cipherBytes = raw.sublist(12);
          final encrypter = encrypt.Encrypter(
            encrypt.AES(key, mode: encrypt.AESMode.gcm),
          );
          final decrypted = encrypter.decrypt(
            encrypt.Encrypted(Uint8List.fromList(cipherBytes)),
            iv: iv,
          );
          data = jsonDecode(decrypted);
        }

        final newAccessToken = data['access_token'] as String;
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}
