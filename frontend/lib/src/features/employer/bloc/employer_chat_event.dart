import 'package:equatable/equatable.dart';

abstract class EmployerChatEvent extends Equatable {
  const EmployerChatEvent();
  @override
  List<Object?> get props => [];
}

class EmployerChatLoadConversations extends EmployerChatEvent {}

class EmployerChatLoadMessages extends EmployerChatEvent {
  final String conversationId;
  const EmployerChatLoadMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class EmployerChatSendMessage extends EmployerChatEvent {
  final String conversationId;
  final String text;
  const EmployerChatSendMessage({
    required this.conversationId,
    required this.text,
  });
  @override
  List<Object?> get props => [conversationId, text];
}
