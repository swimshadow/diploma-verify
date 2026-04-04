import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// AES-256-GCM interceptor.
///
/// Encrypts request payloads before sending and decrypts response payloads
/// after receiving. The encrypted format is:
///   base64( 12-byte IV ‖ ciphertext ‖ 16-byte GCM tag )
///
/// Requests with encryption carry header `X-Encrypted: 1` and body
/// `{"_enc": "<base64>"}`.
/// Responses with the same header are automatically decrypted.
class CryptoInterceptor extends Interceptor {
  final encrypt.Key _key;

  /// [keyBase64] — 256-bit (32-byte) key encoded as base64.
  CryptoInterceptor({required String keyBase64})
      : _key = encrypt.Key.fromBase64(keyBase64);

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
      final jsonStr = jsonEncode(options.data);
      final encrypted = _encrypt(jsonStr);
      options.data = {'_enc': encrypted};
      options.headers['X-Encrypted'] = '1';
    }
    handler.next(options);
  }

  // ─── response ──────────────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map && data.containsKey('_enc')) {
      final decrypted = _decrypt(data['_enc'] as String);
      response.data = jsonDecode(decrypted);
    }
    handler.next(response);
  }
}
