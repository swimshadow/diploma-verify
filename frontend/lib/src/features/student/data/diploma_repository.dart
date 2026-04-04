import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class DiplomaRepository {
  final Dio _dio;

  DiplomaRepository({required Dio dio}) : _dio = dio;

  Future<List<Map<String, dynamic>>> fetchMyDiplomas() async {
    final response = await _dio.get(AppConstants.studentDiplomasPath);
    final data = response.data as Map<String, dynamic>;
    final list = (data['diplomas'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchDiplomaDetail(String diplomaId) async {
    final response =
        await _dio.get('${AppConstants.studentDiplomasPath}/$diplomaId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCertificate(String diplomaId) async {
    final response = await _dio
        .get('${AppConstants.studentDiplomasPath}/$diplomaId/certificate');
    return response.data as Map<String, dynamic>;
  }

  Future<void> uploadDiploma({
    required List<int> fileBytes,
    required String fileName,
    required Map<String, dynamic> metadata,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'metadata': metadata.toString(),
    });
    await _dio.post(
      '${AppConstants.universityDiplomasPath}/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
