import 'package:dio/dio.dart';
import '../../../core/logging/app_logger.dart';

class EmployerRepository {
  static const _tag = 'EmployerRepository';
  final _log = AppLogger.instance;
  final Dio _dio;

  EmployerRepository({required Dio dio}) : _dio = dio {
    _log.info(_tag, 'EmployerRepository создан');
  }

  Future<List<Map<String, dynamic>>> fetchVerificationHistory() async {
    _log.info(_tag, 'fetchVerificationHistory() → GET /api/verify/history');
    try {
      final response = await _dio.get('/api/verify/history');
      final data = response.data;
      List<Map<String, dynamic>> result;
      if (data is Map<String, dynamic>) {
        result = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      } else if (data is List) {
        result = data.cast<Map<String, dynamic>>();
      } else {
        result = [];
      }
      _log.info(_tag, 'fetchVerificationHistory() ← ${result.length} записей');
      return result;
    } catch (e, st) {
      _log.error(_tag, 'fetchVerificationHistory() ОШИБКА', e, st);
      rethrow;
    }
  }
}
