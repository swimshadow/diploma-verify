import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../student/data/models/chat_model.dart';
import 'employer_chat_event.dart';
import 'employer_chat_state.dart';

class EmployerChatBloc extends Bloc<EmployerChatEvent, EmployerChatState> {
  EmployerChatBloc() : super(EmployerChatInitial()) {
    on<EmployerChatLoadConversations>(_onLoadConversations);
    on<EmployerChatLoadMessages>(_onLoadMessages);
    on<EmployerChatSendMessage>(_onSendMessage);
  }

  final List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};

  void _onLoadConversations(
      EmployerChatLoadConversations event, Emitter<EmployerChatState> emit) {
    emit(EmployerChatConversationsLoaded(_conversations));
  }

  void _onLoadMessages(
      EmployerChatLoadMessages event, Emitter<EmployerChatState> emit) {
    final conversation = _conversations.firstWhere(
      (c) => c.id == event.conversationId,
      orElse: () => _conversations.first,
    );
    final messages = _messages[event.conversationId] ?? [];
    emit(EmployerChatMessagesLoaded(
      conversationId: event.conversationId,
      conversation: conversation,
      messages: messages,
    ));
  }

  void _onSendMessage(
      EmployerChatSendMessage event, Emitter<EmployerChatState> emit) {
    final newMessage = ChatMessage(
      id: const Uuid().v4(),
      conversationId: event.conversationId,
      senderId: 'me',
      text: event.text,
      sentAt: DateTime.now(),
      isMe: true,
    );

    final existing = _messages[event.conversationId] ?? [];
    _messages[event.conversationId] = [...existing, newMessage];

    final conversation = _conversations.firstWhere(
      (c) => c.id == event.conversationId,
      orElse: () => _conversations.first,
    );

    final idx = _conversations.indexWhere((c) => c.id == event.conversationId);
    if (idx >= 0) {
      _conversations[idx] = ChatConversation(
        id: conversation.id,
        participantName: conversation.participantName,
        participantRole: conversation.participantRole,
        diplomaId: conversation.diplomaId,
        diplomaTitle: conversation.diplomaTitle,
        lastMessage: event.text,
        lastMessageAt: DateTime.now(),
      );
    }

    if (idx >= 0) {
      emit(EmployerChatMessagesLoaded(
        conversationId: event.conversationId,
        conversation: _conversations[idx],
        messages: _messages[event.conversationId]!,
      ));
    }
  }
}
