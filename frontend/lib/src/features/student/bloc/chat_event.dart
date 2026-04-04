import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatLoadConversations extends ChatEvent {}

class ChatLoadMessages extends ChatEvent {
  final String conversationId;
  const ChatLoadMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class ChatSendMessage extends ChatEvent {
  final String conversationId;
  final String text;
  const ChatSendMessage({required this.conversationId, required this.text});
  @override
  List<Object?> get props => [conversationId, text];
}
