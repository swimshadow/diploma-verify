import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

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
  }
}
