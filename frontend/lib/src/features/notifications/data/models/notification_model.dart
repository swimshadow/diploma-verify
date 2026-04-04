import 'package:equatable/equatable.dart';

enum NotificationType {
  diplomaStatusChange,
  newMessage,
  verificationComplete,
  moderationDecision,
  systemAlert,
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? route; // deep-link route to navigate on tap

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.route,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        route: route,
      );

  @override
  List<Object?> get props => [id, isRead];
}
