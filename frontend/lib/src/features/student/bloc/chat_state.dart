import 'package:equatable/equatable.dart';
import '../data/models/chat_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConversationsLoaded extends ChatState {
  final List<ChatConversation> conversations;
  const ChatConversationsLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class ChatMessagesLoaded extends ChatState {
  final String conversationId;
  final ChatConversation conversation;
  final List<ChatMessage> messages;
  const ChatMessagesLoaded({
    required this.conversationId,
    required this.conversation,
    required this.messages,
  });
  @override
  List<Object?> get props => [conversationId, messages.length];
}
