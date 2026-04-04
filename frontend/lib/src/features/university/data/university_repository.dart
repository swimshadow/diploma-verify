import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';

const _tag = 'UniversityRepository';

class UniversityRepository {
  final Dio _dio;
  final _log = AppLogger.instance;

  UniversityRepository({required Dio dio}) : _dio = dio;

  Future<List<Map<String, dynamic>>> fetchDiplomas() async {
    _log.info(_tag, 'fetchDiplomas: GET ${AppConstants.universityDiplomasPath}');
    final response = await _dio.get(AppConstants.universityDiplomasPath);
    _log.info(_tag, 'fetchDiplomas: status=${response.statusCode}');
    final data = response.data as Map<String, dynamic>;
    final list = (data['diplomas'] as List?) ?? [];
    _log.info(_tag, 'fetchDiplomas: получено ${list.length} дипломов');
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchDiploma(String diplomaId) async {
    _log.info(_tag, 'fetchDiploma: GET ${AppConstants.universityDiplomasPath}/$diplomaId');
    final response =
        await _dio.get('${AppConstants.universityDiplomasPath}/$diplomaId');
    _log.info(_tag, 'fetchDiploma: status=${response.statusCode}');
    return response.data as Map<String, dynamic>;
  }

  Future<String> uploadDiploma({
    required List<int> fileBytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    _log.info(_tag, 'uploadDiploma: файл=$fileName, ${fileBytes.length} bytes');
    _log.info(_tag, 'uploadDiploma: metadata=${jsonEncode(metadata)}');
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'metadata': jsonEncode(metadata),
    });
    _log.info(_tag, 'uploadDiploma: POST ${AppConstants.universityDiplomasPath}/upload');
    final response = await _dio.post(
      '${AppConstants.universityDiplomasPath}/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    _log.info(_tag, 'uploadDiploma: status=${response.statusCode}, data=${response.data}');
    return (response.data as Map<String, dynamic>)['diploma_id'] as String;
  }

  Future<void> verifyDiploma(String diplomaId) async {
    _log.info(_tag, 'verifyDiploma: POST ${AppConstants.universityDiplomasPath}/$diplomaId/verify');
    await _dio
        .post('${AppConstants.universityDiplomasPath}/$diplomaId/verify');
    _log.info(_tag, 'verifyDiploma: done');
  }

  Future<void> revokeDiploma(String diplomaId) async {
    _log.info(_tag, 'revokeDiploma: POST ${AppConstants.universityDiplomasPath}/$diplomaId/revoke');
    await _dio
        .post('${AppConstants.universityDiplomasPath}/$diplomaId/revoke');
    _log.info(_tag, 'revokeDiploma: done');
  }

  Future<Map<String, dynamic>?> fetchCertificate(String diplomaId) async {
    _log.info(_tag, 'fetchCertificate: GET ${AppConstants.certificatesPath}/$diplomaId');
    try {
      final response =
          await _dio.get('${AppConstants.certificatesPath}/$diplomaId');
      _log.info(_tag, 'fetchCertificate: status=${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _log.info(_tag, 'fetchCertificate: 404 — сертификат не найден');
        return null;
      }
      _log.error(_tag, 'fetchCertificate: ошибка ${e.response?.statusCode}', e);
      rethrow;
    }
  }
}
