import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class CertificateRepository {
  final Dio _dio;

  CertificateRepository({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> generate(String diplomaId) async {
    final response = await _dio.post(
      '${AppConstants.certificatesPath}/generate',
      data: {'diploma_id': diplomaId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getByDiplomaId(String diplomaId) async {
    final response =
        await _dio.get('${AppConstants.certificatesPath}/$diplomaId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getByToken(String qrToken) async {
    final response = await _dio
        .get('${AppConstants.certificatesPath}/by-token/$qrToken');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deactivate(String diplomaId) async {
    await _dio.post('${AppConstants.certificatesPath}/$diplomaId/deactivate');
  }
}
