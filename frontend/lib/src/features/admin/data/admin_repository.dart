import 'package:dio/dio.dart';
import '../../../core/logging/app_logger.dart';

class AdminRepository {
  static const _tag = 'AdminRepository';
  final _log = AppLogger.instance;
  final Dio _dio;

  AdminRepository({required Dio dio}) : _dio = dio {
    _log.info(_tag, 'AdminRepository создан');
  }

  Future<List<Map<String, dynamic>>> fetchAccounts({
    String? role,
    bool? isBlocked,
    int page = 1,
  }) async {
    _log.info(_tag, 'fetchAccounts(role=$role, isBlocked=$isBlocked, page=$page)');
    try {
      final response = await _dio.get('/api/admin/accounts', queryParameters: {
        'role': ?role,
        'is_blocked': ?isBlocked,
        'page': page,
      });
      final data = response.data as Map<String, dynamic>;
      final result = (data['accounts'] as List? ?? []).cast<Map<String, dynamic>>();
      _log.info(_tag, 'fetchAccounts() ← ${result.length} аккаунтов');
      return result;
    } catch (e, st) {
      _log.error(_tag, 'fetchAccounts() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> blockUser(String accountId) async {
    _log.info(_tag, 'blockUser($accountId)');
    await _dio.post('/api/admin/accounts/$accountId/block');
    _log.info(_tag, 'blockUser() ← OK');
  }

  Future<void> unblockUser(String accountId) async {
    _log.info(_tag, 'unblockUser($accountId)');
    await _dio.post('/api/admin/accounts/$accountId/unblock');
    _log.info(_tag, 'unblockUser() ← OK');
  }

  Future<List<Map<String, dynamic>>> fetchDiplomas({
    String? status,
    int page = 1,
  }) async {
    _log.info(_tag, 'fetchDiplomas(status=$status, page=$page)');
    try {
      final response = await _dio.get('/api/admin/diplomas', queryParameters: {
        'status': ?status,
        'page': page,
      });
      final data = response.data as Map<String, dynamic>;
      final result = (data['diplomas'] as List? ?? []).cast<Map<String, dynamic>>();
      _log.info(_tag, 'fetchDiplomas() ← ${result.length} дипломов');
      return result;
    } catch (e, st) {
      _log.error(_tag, 'fetchDiplomas() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> forceVerifyDiploma(String diplomaId, String reason) async {
    _log.info(_tag, 'forceVerifyDiploma($diplomaId, reason=$reason)');
    await _dio.post('/api/admin/diplomas/$diplomaId/force-verify',
        data: {'reason': reason});
    _log.info(_tag, 'forceVerifyDiploma() ← OK');
  }

  Future<void> forceRevokeDiploma(String diplomaId, String reason) async {
    _log.info(_tag, 'forceRevokeDiploma($diplomaId, reason=$reason)');
    await _dio.post('/api/admin/diplomas/$diplomaId/force-revoke',
        data: {'reason': reason});
    _log.info(_tag, 'forceRevokeDiploma() ← OK');
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs({int page = 1}) async {
    _log.info(_tag, 'fetchAuditLogs(page=$page)');
    try {
      final response = await _dio
          .get('/api/admin/audit', queryParameters: {'page': page});
      final data = response.data as Map<String, dynamic>;
      final result = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      _log.info(_tag, 'fetchAuditLogs() ← ${result.length} записей');
      return result;
    } catch (e, st) {
      _log.error(_tag, 'fetchAuditLogs() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchVerificationLogs({
    int page = 1,
  }) async {
    _log.info(_tag, 'fetchVerificationLogs(page=$page)');
    try {
      final response = await _dio
          .get('/api/admin/logs/verifications', queryParameters: {'page': page});
      final data = response.data as Map<String, dynamic>;
      final result = (data['logs'] as List? ?? []).cast<Map<String, dynamic>>();
      _log.info(_tag, 'fetchVerificationLogs() ← ${result.length} записей');
      return result;
    } catch (e, st) {
      _log.error(_tag, 'fetchVerificationLogs() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchDiplomaStats() async {
    _log.info(_tag, 'fetchDiplomaStats()');
    try {
      final response = await _dio.get('/api/admin/diplomas/stats');
      _log.info(_tag, 'fetchDiplomaStats() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'fetchDiplomaStats() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> createAdmin({
    required String email,
    required String password,
    required String secretKey,
  }) async {
    _log.info(_tag, 'createAdmin(email=$email)');
    await _dio.post('/api/admin/setup', data: {
      'email': email,
      'password': password,
      'secret_key': secretKey,
    });
    _log.info(_tag, 'createAdmin() ← OK');
  }

  Future<void> verifyUniversity(String accountId) async {
    _log.info(_tag, 'verifyUniversity($accountId)');
    await _dio.post('/api/admin/accounts/$accountId/verify');
    _log.info(_tag, 'verifyUniversity() ← OK');
  }

  Future<void> verifyUniversityWithEcp({
    required String accountId,
    required String payload,
    required String signature,
    required String publicKeyPem,
  }) async {
    _log.info(_tag, 'verifyUniversityWithEcp($accountId)');
    await _dio.post('/api/admin/accounts/$accountId/verify-ecp', data: {
      'payload': payload,
      'signature': signature,
      'public_key_pem': publicKeyPem,
    });
    _log.info(_tag, 'verifyUniversityWithEcp() ← OK');
  }

  Future<void> unverifyUniversity(String accountId) async {
    _log.info(_tag, 'unverifyUniversity($accountId)');
    await _dio.post('/api/admin/accounts/$accountId/unverify');
    _log.info(_tag, 'unverifyUniversity() ← OK');
  }
}
