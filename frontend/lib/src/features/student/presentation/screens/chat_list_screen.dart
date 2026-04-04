import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_state.dart';
import '../../data/models/chat_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Сообщения',
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatConversationsLoaded) {
            return _Body(conversations: state.conversations);
          }
          if (state is ChatMessagesLoaded) {
            // If we're coming back from messages, we still have conversations
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<ChatConversation> conversations;
  const _Body({required this.conversations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Нет сообщений',
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final c = conversations[index];
        return _ConversationTile(conversation: c);
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('dd.MM HH:mm');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          conversation.participantRole == 'employer'
              ? Icons.business
              : Icons.person,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(conversation.participantName,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(timeFormat.format(conversation.lastMessageAt),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.diplomaTitle != null)
            Text('📄 ${conversation.diplomaTitle}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary, fontSize: 11)),
          Text(conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? CircleAvatar(
              radius: 11,
              backgroundColor: theme.colorScheme.primary,
              child: Text('${conversation.unreadCount}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            )
          : null,
      onTap: () =>
          context.push('/student/chat/${conversation.id}'),
    );
  }
}
