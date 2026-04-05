import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';

class CertificateRepository {
  static const _tag = 'CertificateRepo';
  final _log = AppLogger.instance;
  final Dio _dio;

  CertificateRepository({required Dio dio}) : _dio = dio {
    _log.info(_tag, 'CertificateRepository создан');
  }

  Future<Map<String, dynamic>> generate(
    String diplomaId, {
    required Map<String, dynamic> diplomaData,
  }) async {
    _log.info(_tag, 'generate($diplomaId)');
    try {
      final response = await _dio.post(
        '${AppConstants.certificatesPath}/generate',
        data: {
          'diploma_id': diplomaId,
          'diploma_data': diplomaData,
        },
      );
      _log.info(_tag, 'generate() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'generate() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getByDiplomaId(String diplomaId) async {
    _log.info(_tag, 'getByDiplomaId($diplomaId)');
    try {
      final response =
          await _dio.get('${AppConstants.certificatesPath}/$diplomaId');
      _log.info(_tag, 'getByDiplomaId() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'getByDiplomaId() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getByToken(String qrToken) async {
    _log.info(_tag, 'getByToken($qrToken)');
    try {
      final response = await _dio
          .get('${AppConstants.certificatesPath}/by-token/$qrToken');
      _log.info(_tag, 'getByToken() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'getByToken() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> deactivate(String diplomaId) async {
    _log.info(_tag, 'deactivate($diplomaId)');
    try {
      await _dio.post('${AppConstants.certificatesPath}/$diplomaId/deactivate');
      _log.info(_tag, 'deactivate() ← OK');
    } catch (e, st) {
      _log.error(_tag, 'deactivate() ОШИБКА', e, st);
      rethrow;
    }
  }
}
