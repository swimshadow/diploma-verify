import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import 'notification_event_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoad);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
  }

  void _onLoad(
      NotificationLoadRequested event, Emitter<NotificationState> emit) {
    emit(NotificationLoaded(List.of(mockNotifications)));
  }

  void _onMarkRead(
      NotificationMarkRead event, Emitter<NotificationState> emit) {
    final loaded = state;
    if (loaded is! NotificationLoaded) return;
    final updated = loaded.notifications
        .map((n) => n.id == event.notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    emit(NotificationLoaded(updated));
  }

  void _onMarkAllRead(
      NotificationMarkAllRead event, Emitter<NotificationState> emit) {
    final loaded = state;
    if (loaded is! NotificationLoaded) return;
    final updated =
        loaded.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(NotificationLoaded(updated));
  }
}
