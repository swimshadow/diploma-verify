import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/employer_chat_bloc.dart';
import '../../bloc/employer_chat_event.dart';
import '../../bloc/employer_chat_state.dart';

class EmployerChatConversationScreen extends StatefulWidget {
  final String conversationId;
  const EmployerChatConversationScreen(
      {super.key, required this.conversationId});

  @override
  State<EmployerChatConversationScreen> createState() =>
      _EmployerChatConversationScreenState();
}

class _EmployerChatConversationScreenState
    extends State<EmployerChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context
        .read<EmployerChatBloc>()
        .add(EmployerChatLoadMessages(widget.conversationId));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<EmployerChatBloc>().add(EmployerChatSendMessage(
          conversationId: widget.conversationId,
          text: text,
        ));
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<EmployerChatBloc, EmployerChatState>(
      builder: (context, state) {
        String title = 'Чат';
        String? diplomaTitle;
        List messages = [];

        if (state is EmployerChatMessagesLoaded &&
            state.conversationId == widget.conversationId) {
          title = state.conversation.participantName;
          diplomaTitle = state.conversation.diplomaTitle;
          messages = state.messages;
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                if (diplomaTitle != null)
                  Text(diplomaTitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('Нет сообщений'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _MessageBubble(
                            text: msg.text,
                            time: DateFormat('HH:mm').format(msg.sentAt),
                            isMe: msg.isMe,
                          );
                        },
                      ),
              ),

              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Написать сообщение...',
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send,
                            color: theme.colorScheme.primary),
                        onPressed: _send,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text,
                style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
