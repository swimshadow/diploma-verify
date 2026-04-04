import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../logging/logging_interceptor.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'crypto_interceptor.dart';

class DioClient {
  late final Dio dio;

  DioClient({required TokenStorage tokenStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(tokenStorage: tokenStorage, dio: dio),
    );

    // HTTP logging — before crypto so we see plaintext bodies
    dio.interceptors.add(LoggingInterceptor());

    // AES-256-GCM payload encryption — hides request/response data in DevTools
    if (AppConstants.payloadEncryptionKey.isNotEmpty) {
      dio.interceptors.add(
        CryptoInterceptor(keyBase64: AppConstants.payloadEncryptionKey),
      );
    }
  }
}
