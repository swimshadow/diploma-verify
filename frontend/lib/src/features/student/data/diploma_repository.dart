import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';

class DiplomaRepository {
  static const _tag = 'DiplomaRepository';
  final _log = AppLogger.instance;
  final Dio _dio;

  DiplomaRepository({required Dio dio}) : _dio = dio {
    _log.info(_tag, 'DiplomaRepository создан');
  }

  Future<List<Map<String, dynamic>>> fetchMyDiplomas() async {
    _log.info(_tag, 'fetchMyDiplomas() → GET ${AppConstants.studentDiplomasPath}');
    try {
      final response = await _dio.get(AppConstants.studentDiplomasPath);
      final data = response.data as Map<String, dynamic>;
      final list = (data['diplomas'] as List?) ?? [];
      _log.info(_tag, 'fetchMyDiplomas() ← ${list.length} дипломов');
      return list.cast<Map<String, dynamic>>();
    } catch (e, st) {
      _log.error(_tag, 'fetchMyDiplomas() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCertificate(String diplomaId) async {
    _log.info(_tag, 'fetchCertificate($diplomaId)');
    try {
      final response = await _dio
          .get('${AppConstants.studentDiplomasPath}/$diplomaId/certificate');
      _log.info(_tag, 'fetchCertificate() ← OK');
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      _log.error(_tag, 'fetchCertificate() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> uploadDiploma({
    required List<int> fileBytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    _log.info(_tag, 'uploadDiploma() → POST ${AppConstants.universityDiplomasPath}/upload, файл=$fileName, ${fileBytes.length} байт');
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'metadata': jsonEncode(metadata),
      });
      await _dio.post(
        '${AppConstants.universityDiplomasPath}/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      _log.info(_tag, 'uploadDiploma() ← OK');
    } catch (e, st) {
      _log.error(_tag, 'uploadDiploma() ОШИБКА', e, st);
      rethrow;
    }
  }
}
