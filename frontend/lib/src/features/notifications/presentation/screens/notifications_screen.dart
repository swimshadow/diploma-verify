import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../bloc/notification_bloc.dart';
import '../../bloc/notification_event_state.dart';
import '../../data/models/notification_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Уведомления',
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is! NotificationLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = state.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Нет уведомлений',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (state.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text('${state.unreadCount} непрочитанных',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context
                            .read<NotificationBloc>()
                            .add(NotificationMarkAllRead()),
                        child: const Text('Прочитать все'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) =>
                      _NotificationTile(notification: notifications[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _iconForType(notification.type);
    final timeStr =
        DateFormat('dd.MM HH:mm').format(notification.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight:
              notification.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () {
        if (!notification.isRead) {
          context
              .read<NotificationBloc>()
              .add(NotificationMarkRead(notification.id));
        }
        if (notification.route != null) {
          context.push(notification.route!);
        }
      },
    );
  }

  (IconData, Color) _iconForType(NotificationType t) => switch (t) {
        NotificationType.diplomaStatusChange =>
          (Icons.description, Colors.blue),
        NotificationType.newMessage =>
          (Icons.chat_bubble, Colors.teal),
        NotificationType.verificationComplete =>
          (Icons.verified, Colors.green),
        NotificationType.moderationDecision =>
          (Icons.gavel, Colors.orange),
        NotificationType.systemAlert =>
          (Icons.info_outline, Colors.grey),
      };
}
