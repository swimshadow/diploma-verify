import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../logging/app_logger.dart';

/// AES-256-GCM interceptor.
class CryptoInterceptor extends Interceptor {
  static const _tag = 'CryptoInterceptor';
  final _log = AppLogger.instance;
  final encrypt.Key _key;

  CryptoInterceptor({required String keyBase64})
      : _key = encrypt.Key.fromBase64(keyBase64) {
    AppLogger.instance.info(_tag, 'CryptoInterceptor создан');
  }

  // ─── helpers ───────────────────────────────────────────────

  String _encrypt(String plaintext) {
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Pack: IV (12) + ciphertext + tag (16)
    final combined = Uint8List.fromList([
      ...iv.bytes,
      ...encrypted.bytes,
    ]);
    return base64Encode(combined);
  }

  String _decrypt(String payload) {
    final raw = base64Decode(payload);
    final iv = encrypt.IV(Uint8List.fromList(raw.sublist(0, 12)));
    final cipherBytes = raw.sublist(12);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );
    return encrypter.decrypt(
      encrypt.Encrypted(Uint8List.fromList(cipherBytes)),
      iv: iv,
    );
  }

  // Skip encryption for multipart/form-data (file uploads)
  bool _isMultipart(RequestOptions options) {
    return options.data is FormData;
  }

  // ─── request ───────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data != null && !_isMultipart(options)) {
      _log.debug(_tag, 'onRequest: шифрование тела → ${options.method} ${options.uri}');
      final jsonStr = jsonEncode(options.data);
      final encrypted = _encrypt(jsonStr);
      options.data = {'_enc': encrypted};
      options.headers['X-Encrypted'] = '1';
    } else if (_isMultipart(options)) {
      _log.debug(_tag, 'onRequest: пропуск шифрования (multipart) → ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  // ─── response ──────────────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map && data.containsKey('_enc')) {
      _log.debug(_tag, 'onResponse: дешифрование ответа ← ${response.requestOptions.uri}');
      final decrypted = _decrypt(data['_enc'] as String);
      response.data = jsonDecode(decrypted);
    }
    handler.next(response);
  }
}
