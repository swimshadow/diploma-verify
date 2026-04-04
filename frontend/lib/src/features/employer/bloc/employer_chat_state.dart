import 'package:equatable/equatable.dart';
import '../../student/data/models/chat_model.dart';

abstract class EmployerChatState extends Equatable {
  const EmployerChatState();
  @override
  List<Object?> get props => [];
}

class EmployerChatInitial extends EmployerChatState {}

class EmployerChatLoading extends EmployerChatState {}

class EmployerChatConversationsLoaded extends EmployerChatState {
  final List<ChatConversation> conversations;
  const EmployerChatConversationsLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class EmployerChatMessagesLoaded extends EmployerChatState {
  final String conversationId;
  final ChatConversation conversation;
  final List<ChatMessage> messages;
  const EmployerChatMessagesLoaded({
    required this.conversationId,
    required this.conversation,
    required this.messages,
  });
  @override
  List<Object?> get props => [conversationId, messages.length];
}
