import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/student/data/models/chat_model.dart';

/// Responsive chat layout:
/// - Wide (>=720px): two-column master-detail
/// - Narrow (<720px): single screen (list or conversation)
class AdaptiveChatLayout extends StatefulWidget {
  final List<ChatConversation> conversations;
  final String? selectedConversationId;
  final List<ChatMessage> messages;
  final ValueChanged<String> onSelectConversation;
  final void Function(String conversationId, String text) onSendMessage;
  final String? currentConversationTitle;
  final String? currentConversationSubtitle;

  const AdaptiveChatLayout({
    super.key,
    required this.conversations,
    this.selectedConversationId,
    required this.messages,
    required this.onSelectConversation,
    required this.onSendMessage,
    this.currentConversationTitle,
    this.currentConversationSubtitle,
  });

  @override
  State<AdaptiveChatLayout> createState() => _AdaptiveChatLayoutState();
}

class _AdaptiveChatLayoutState extends State<AdaptiveChatLayout> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty || widget.selectedConversationId == null) return;
    widget.onSendMessage(widget.selectedConversationId!, text);
    _inputController.clear();
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
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Row(
        children: [
          SizedBox(
            width: 320,
            child: _ConversationList(
              conversations: widget.conversations,
              selectedId: widget.selectedConversationId,
              onSelect: widget.onSelectConversation,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: widget.selectedConversationId == null
                ? _EmptyPane()
                : _MessagePane(
                    title: widget.currentConversationTitle ?? 'Чат',
                    subtitle: widget.currentConversationSubtitle,
                    messages: widget.messages,
                    inputController: _inputController,
                    scrollController: _scrollController,
                    onSend: _send,
                    showAppBar: false,
                  ),
          ),
        ],
      );
    }

    // Narrow: show list or conversation
    if (widget.selectedConversationId == null) {
      return _ConversationList(
        conversations: widget.conversations,
        selectedId: null,
        onSelect: widget.onSelectConversation,
      );
    }

    return _MessagePane(
      title: widget.currentConversationTitle ?? 'Чат',
      subtitle: widget.currentConversationSubtitle,
      messages: widget.messages,
      inputController: _inputController,
      scrollController: _scrollController,
      onSend: _send,
      showAppBar: false,
    );
  }
}

// ─── Conversation list ───
class _ConversationList extends StatelessWidget {
  final List<ChatConversation> conversations;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ConversationList({
    required this.conversations,
    this.selectedId,
    required this.onSelect,
  });

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
      itemBuilder: (context, i) {
        final c = conversations[i];
        final isSelected = c.id == selectedId;
        final timeFormat = DateFormat('dd.MM HH:mm');

        return ListTile(
          selected: isSelected,
          selectedTileColor:
              theme.colorScheme.primary.withValues(alpha: 0.08),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              c.participantName.isNotEmpty ? c.participantName[0] : '?',
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(c.participantName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(timeFormat.format(c.lastMessageAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.diplomaTitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Text('📄 ${c.diplomaTitle}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary, fontSize: 11)),
                ),
              Text(c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
          onTap: () => onSelect(c.id),
        );
      },
    );
  }
}

// ─── Message pane ───
class _MessagePane extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ChatMessage> messages;
  final TextEditingController inputController;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final bool showAppBar;

  const _MessagePane({
    required this.title,
    this.subtitle,
    required this.messages,
    required this.inputController,
    required this.scrollController,
    required this.onSend,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text('📄 $subtitle',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text('Нет сообщений',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: messages[index]),
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border:
                Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Написать сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty pane ───
class _EmptyPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_outlined,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Выберите беседу',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Message bubble ───
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Align(
      alignment:
          message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.65),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: message.isMe
                        ? Colors.white
                        : theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(timeFormat.format(message.sentAt),
                style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: message.isMe
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
