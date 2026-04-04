import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../logging/app_logger.dart';
import '../storage/token_storage.dart';
import '../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  static const _tag = 'AuthInterceptor';
  final _log = AppLogger.instance;
  final TokenStorage _tokenStorage;
  final Dio _dio;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio {
    _log.info(_tag, 'AuthInterceptor создан');
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      _log.debug(_tag, 'onRequest: Bearer токен добавлен → ${options.method} ${options.uri}');
    } else {
      _log.debug(_tag, 'onRequest: нет токена → ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _log.warning(_tag, 'onError: 401 → попытка refresh токена');
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        _log.info(_tag, 'onError: refresh OK → повтор запроса');
        final token = await _tokenStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          _log.error(_tag, 'onError: повторный запрос ОШИБКА', e);
          return handler.next(e);
        }
      }
      _log.warning(_tag, 'onError: refresh НЕУДАЧА → очистка токенов');
      await _tokenStorage.clearTokens();
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    _log.info(_tag, '_tryRefreshToken → начало');
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _log.warning(_tag, '_tryRefreshToken: нет refresh токена');
        return false;
      }

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
        _log.info(_tag, '_tryRefreshToken: ответ 200, декодирование…');
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
        _log.info(_tag, '_tryRefreshToken ← OK');
        return true;
      }
      _log.warning(_tag, '_tryRefreshToken: статус ${response.statusCode}');
    } catch (e, st) {
      _log.error(_tag, '_tryRefreshToken ОШИБКА', e, st);
    }
    return false;
  }
}
