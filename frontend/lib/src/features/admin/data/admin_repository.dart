import 'package:dio/dio.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository({required Dio dio}) : _dio = dio;

  Future<List<Map<String, dynamic>>> fetchAccounts({
    String? role,
    bool? isBlocked,
    int page = 1,
  }) async {
    final response = await _dio.get('/api/admin/accounts', queryParameters: {
      'role': ?role,
      'is_blocked': ?isBlocked,
      'page': page,
    });
    final data = response.data as Map<String, dynamic>;
    return (data['accounts'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> blockUser(String accountId) async {
    await _dio.post('/api/admin/accounts/$accountId/block');
  }

  Future<void> unblockUser(String accountId) async {
    await _dio.post('/api/admin/accounts/$accountId/unblock');
  }

  Future<List<Map<String, dynamic>>> fetchDiplomas({
    String? status,
    int page = 1,
  }) async {
    final response = await _dio.get('/api/admin/diplomas', queryParameters: {
      'status': ?status,
      'page': page,
    });
    final data = response.data as Map<String, dynamic>;
    return (data['diplomas'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> forceVerifyDiploma(String diplomaId, String reason) async {
    await _dio.post('/api/admin/diplomas/$diplomaId/force-verify',
        data: {'reason': reason});
  }

  Future<void> forceRevokeDiploma(String diplomaId, String reason) async {
    await _dio.post('/api/admin/diplomas/$diplomaId/force-revoke',
        data: {'reason': reason});
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs({int page = 1}) async {
    final response = await _dio
        .get('/api/admin/audit', queryParameters: {'page': page});
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchVerificationLogs({
    int page = 1,
  }) async {
    final response = await _dio
        .get('/api/admin/logs/verifications', queryParameters: {'page': page});
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchDiplomaStats() async {
    final response = await _dio.get('/api/admin/diplomas/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<void> createAdmin({
    required String email,
    required String password,
    required String secretKey,
  }) async {
    await _dio.post('/api/admin/setup', data: {
      'email': email,
      'password': password,
      'secret_key': secretKey,
    });
  }
}
