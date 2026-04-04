import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../data/models/chat_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<ChatLoadConversations>(_onLoadConversations);
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
  }

  final List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};

  void _onLoadConversations(
      ChatLoadConversations event, Emitter<ChatState> emit) {
    emit(ChatConversationsLoaded(_conversations));
  }

  void _onLoadMessages(ChatLoadMessages event, Emitter<ChatState> emit) {
    final conversation = _conversations.firstWhere(
      (c) => c.id == event.conversationId,
      orElse: () => _conversations.first,
    );
    final messages = _messages[event.conversationId] ?? [];
    emit(ChatMessagesLoaded(
      conversationId: event.conversationId,
      conversation: conversation,
      messages: messages,
    ));
  }

  void _onSendMessage(ChatSendMessage event, Emitter<ChatState> emit) {
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
      emit(ChatMessagesLoaded(
        conversationId: event.conversationId,
        conversation: _conversations[idx],
        messages: _messages[event.conversationId]!,
      ));
    }
  }
}
