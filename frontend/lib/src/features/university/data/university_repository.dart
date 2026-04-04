import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class UniversityRepository {
  final Dio _dio;

  UniversityRepository({required Dio dio}) : _dio = dio;

  Future<List<Map<String, dynamic>>> fetchDiplomas() async {
    final response = await _dio.get(AppConstants.universityDiplomasPath);
    final data = response.data as Map<String, dynamic>;
    final list = (data['diplomas'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchDiploma(String diplomaId) async {
    final response =
        await _dio.get('${AppConstants.universityDiplomasPath}/$diplomaId');
    return response.data as Map<String, dynamic>;
  }

  Future<String> uploadDiploma({
    required List<int> fileBytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'metadata': jsonEncode(metadata),
    });
    final response = await _dio.post(
      '${AppConstants.universityDiplomasPath}/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (response.data as Map<String, dynamic>)['diploma_id'] as String;
  }

  Future<void> verifyDiploma(String diplomaId) async {
    await _dio
        .post('${AppConstants.universityDiplomasPath}/$diplomaId/verify');
  }

  Future<void> revokeDiploma(String diplomaId) async {
    await _dio
        .post('${AppConstants.universityDiplomasPath}/$diplomaId/revoke');
  }

  Future<Map<String, dynamic>?> fetchCertificate(String diplomaId) async {
    try {
      final response =
          await _dio.get('${AppConstants.certificatesPath}/$diplomaId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
