import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class VerifyRepository {
  final Dio _dio;

  VerifyRepository({required Dio dio}) : _dio = dio;

  /// Verify diploma by QR token
  Future<Map<String, dynamic>> verifyByQr(String qrToken) async {
    final response =
        await _dio.get('${AppConstants.verifyQrPath}/$qrToken');
    return response.data as Map<String, dynamic>;
  }

  /// Verify diploma manually by data fields
  Future<Map<String, dynamic>> verifyManually({
    required String diplomaNumber,
    required String series,
    required String fullName,
    required String issueDate,
  }) async {
    final response = await _dio.post(
      AppConstants.verifyManualPath,
      data: {
        'diploma_number': diplomaNumber,
        'series': series,
        'full_name': fullName,
        'issue_date': issueDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Verify by certificate ID (same as QR token)
  Future<Map<String, dynamic>> verifyByCertificateId(String certId) async {
    return verifyByQr(certId);
  }
}
