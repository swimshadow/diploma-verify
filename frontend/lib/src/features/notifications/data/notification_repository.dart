import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';

class NotificationRepository {
  static const _tag = 'NotificationRepo';
  final _log = AppLogger.instance;
  final Dio _dio;

  NotificationRepository({required Dio dio}) : _dio = dio {
    _log.info(_tag, 'NotificationRepository создан');
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    _log.info(_tag, 'fetchNotifications() → GET ${AppConstants.notificationsPath}');
    try {
      final response = await _dio.get(AppConstants.notificationsPath);
      final data = response.data as Map<String, dynamic>;
      final list = (data['notifications'] as List?) ?? [];
      _log.info(_tag, 'fetchNotifications() ← ${list.length} уведомлений');
      return list.cast<Map<String, dynamic>>();
    } catch (e, st) {
      _log.error(_tag, 'fetchNotifications() ОШИБКА', e, st);
      rethrow;
    }
  }

  Future<void> markRead(String notificationId) async {
    _log.info(_tag, 'markRead($notificationId)');
    await _dio.patch(
        '${AppConstants.notificationsPath}/$notificationId/read');
    _log.info(_tag, 'markRead() ← OK');
  }

  Future<void> markAllRead() async {
    _log.info(_tag, 'markAllRead()');
    await _dio.patch('${AppConstants.notificationsPath}/read-all');
    _log.info(_tag, 'markAllRead() ← OK');
  }
}
