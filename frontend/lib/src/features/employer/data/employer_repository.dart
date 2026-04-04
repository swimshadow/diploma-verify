import 'package:dio/dio.dart';

class EmployerRepository {
  final Dio _dio;

  EmployerRepository({required Dio dio}) : _dio = dio;

  /// Fetch verification logs relevant to the current employer.
  Future<List<Map<String, dynamic>>> fetchVerificationHistory() async {
    final response = await _dio.get('/api/verify/history');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }
}
