import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import '../data/models/notification_model.dart';
import '../data/notification_repository.dart';
import 'notification_event_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoad);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
  }

  Future<void> _onLoad(
      NotificationLoadRequested event, Emitter<NotificationState> emit) async {
    try {
      final raw = await _repository.fetchNotifications();
      final items = raw.map(_mapNotification).toList();
      emit(NotificationLoaded(items));
    } catch (_) {
      emit(NotificationLoaded(List.of(mockNotifications)));
    }
  }

  Future<void> _onMarkRead(
      NotificationMarkRead event, Emitter<NotificationState> emit) async {
    final loaded = state;
    if (loaded is! NotificationLoaded) return;
    final updated = loaded.notifications
        .map(
            (n) => n.id == event.notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    emit(NotificationLoaded(updated));
    try {
      await _repository.markRead(event.notificationId);
    } catch (_) {
      // already updated locally
    }
  }

  Future<void> _onMarkAllRead(
      NotificationMarkAllRead event, Emitter<NotificationState> emit) async {
    final loaded = state;
    if (loaded is! NotificationLoaded) return;
    final updated =
        loaded.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(NotificationLoaded(updated));
    try {
      await _repository.markAllRead();
    } catch (_) {
      // already updated locally
    }
  }

  static NotificationType _parseType(String? t) {
    switch (t) {
      case 'diploma_status':
        return NotificationType.diplomaStatusChange;
      case 'new_message':
        return NotificationType.newMessage;
      case 'verification':
        return NotificationType.verificationComplete;
      case 'moderation':
        return NotificationType.moderationDecision;
      default:
        return NotificationType.systemAlert;
    }
  }

  static AppNotification _mapNotification(Map<String, dynamic> j) {
    return AppNotification(
      id: j['id']?.toString() ?? '',
      type: _parseType(j['type']?.toString()),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? j['message'] ?? '').toString(),
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      isRead: j['is_read'] == true,
      route: j['route']?.toString(),
    );
  }
}
