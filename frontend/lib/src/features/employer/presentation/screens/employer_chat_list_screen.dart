import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/employer_chat_bloc.dart';
import '../../bloc/employer_chat_event.dart';
import '../../bloc/employer_chat_state.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/adaptive_chat_layout.dart';

/// Employer chat — responsive:
/// Wide (>=720px): two-column master-detail
/// Narrow (<720px): list; tap navigates to conversation screen
class EmployerChatListScreen extends StatelessWidget {
  const EmployerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return DashboardScaffold(
      title: 'Сообщения',
      body: BlocBuilder<EmployerChatBloc, EmployerChatState>(
        builder: (context, state) {
          List conversations = [];
          String? selectedId;
          List messages = [];
          String? title;
          String? subtitle;

          if (state is EmployerChatConversationsLoaded) {
            conversations = state.conversations;
          } else if (state is EmployerChatMessagesLoaded) {
            selectedId = state.conversationId;
            messages = state.messages;
            title = state.conversation.participantName;
            subtitle = state.conversation.diplomaTitle;
          }

          if (!isWide) {
            if (conversations.isEmpty &&
                state is! EmployerChatConversationsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return _NarrowList(conversations: conversations);
          }

          return AdaptiveChatLayout(
            conversations: conversations.cast(),
            selectedConversationId: selectedId,
            messages: messages.cast(),
            currentConversationTitle: title,
            currentConversationSubtitle: subtitle,
            onSelectConversation: (id) {
              context
                  .read<EmployerChatBloc>()
                  .add(EmployerChatLoadMessages(id));
            },
            onSendMessage: (id, text) {
              context.read<EmployerChatBloc>().add(
                    EmployerChatSendMessage(conversationId: id, text: text),
                  );
            },
          );
        },
      ),
    );
  }
}

class _NarrowList extends StatelessWidget {
  final List conversations;
  const _NarrowList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Нет сообщений',
                style: theme.textTheme.titleMedium?.copyWith(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: CircleAvatar(
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              c.participantName.isNotEmpty ? c.participantName[0] : '?',
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(c.participantName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.diplomaTitle != null)
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(c.diplomaTitle!,
                      style: TextStyle(
                          fontSize: 11, color: theme.colorScheme.primary)),
                ),
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
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                )
              : null,
          onTap: () => context.push('/employer/chat/${c.id}'),
        );
      },
    );
  }
}
