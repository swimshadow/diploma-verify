import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';

class VerifyRepository {
  static const _tag = 'VerifyRepository';
  final _log = AppLogger.instance;
  final Dio _dio;

  VerifyRepository({required Dio dio}) : _dio = dio {
    _log.info(_tag, 'VerifyRepository создан');
  }

  Future<Map<String, dynamic>> verifyByQr(String qrToken) async {
    _log.info(_tag, 'verifyByQr() → GET ${AppConstants.verifyQrPath}/$qrToken');
    try {
      final response =
          await _dio.get('${AppConstants.verifyQrPath}/$qrToken');
      _log.info(_tag, 'verifyByQr() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'verifyByQr() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyManually({
    required String diplomaNumber,
    required String series,
    required String fullName,
    required String issueDate,
  }) async {
    _log.info(_tag, 'verifyManually() → POST ${AppConstants.verifyManualPath} diploma=$diplomaNumber');
    try {
      final response = await _dio.post(
        AppConstants.verifyManualPath,
        data: {
          'diploma_number': diplomaNumber,
          'series': series,
          'full_name': fullName,
          'issue_date': issueDate,
        },
      );
      _log.info(_tag, 'verifyManually() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'verifyManually() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyByCertificateId(String certId) async {
    _log.info(_tag, 'verifyByCertificateId($certId)');
    return verifyByQr(certId);
  }
}
