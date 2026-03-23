import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';
import '../../data/models/chat_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/adaptive_chat_layout.dart';

/// Student chat — responsive:
/// Wide (>=720px): two-column master-detail
/// Narrow (<720px): list; tap navigates to conversation screen
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return DashboardScaffold(
      title: 'Сообщения',
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          List<ChatConversation> conversations = [];
          String? selectedId;
          List<ChatMessage> messages = [];
          String? title;
          String? subtitle;

          if (state is ChatConversationsLoaded) {
            conversations = state.conversations;
          } else if (state is ChatMessagesLoaded) {
            selectedId = state.conversationId;
            messages = state.messages;
            title = state.conversation.participantName;
            subtitle = state.conversation.diplomaTitle;
          }

          if (!isWide) {
            if (conversations.isEmpty && state is! ChatConversationsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return _NarrowList(conversations: conversations);
          }

          // Wide layout — two columns
          return AdaptiveChatLayout(
            conversations: conversations,
            selectedConversationId: selectedId,
            messages: messages,
            currentConversationTitle: title,
            currentConversationSubtitle: subtitle,
            onSelectConversation: (id) {
              context.read<ChatBloc>().add(ChatLoadMessages(id));
            },
            onSendMessage: (id, text) {
              context
                  .read<ChatBloc>()
                  .add(ChatSendMessage(conversationId: id, text: text));
            },
          );
        },
      ),
    );
  }
}

class _NarrowList extends StatelessWidget {
  final List<ChatConversation> conversations;
  const _NarrowList({required this.conversations});

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
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              c.participantRole == 'employer' ? Icons.business : Icons.person,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(c.participantName,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.diplomaTitle != null)
                Text('📄 ${c.diplomaTitle}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary, fontSize: 11)),
              Text(c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          trailing: c.unreadCount > 0
              ? CircleAvatar(
                  radius: 11,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text('${c.unreadCount}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                )
              : null,
          onTap: () => context.push('/student/chat/${c.id}'),
        );
      },
    );
  }
}
