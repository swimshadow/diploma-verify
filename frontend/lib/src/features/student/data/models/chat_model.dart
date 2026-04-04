import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  final String id;
  final String participantName;
  final String participantRole;
  final String? diplomaId;
  final String? diplomaTitle;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantRole,
    this.diplomaId,
    this.diplomaTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [id, lastMessageAt, unreadCount];
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMe,
  });

  @override
  List<Object?> get props => [id, sentAt];
}
