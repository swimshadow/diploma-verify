import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository({required Dio dio}) : _dio = dio;

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await _dio.get(AppConstants.notificationsPath);
    final data = response.data as Map<String, dynamic>;
    final list = (data['notifications'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> markRead(String notificationId) async {
    await _dio.patch(
        '${AppConstants.notificationsPath}/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('${AppConstants.notificationsPath}/read-all');
  }
}
