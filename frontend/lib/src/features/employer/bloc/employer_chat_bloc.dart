import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../student/data/models/chat_model.dart';
import '../data/mock_data.dart';
import 'employer_chat_event.dart';
import 'employer_chat_state.dart';

class EmployerChatBloc extends Bloc<EmployerChatEvent, EmployerChatState> {
  EmployerChatBloc() : super(EmployerChatInitial()) {
    on<EmployerChatLoadConversations>(_onLoadConversations);
    on<EmployerChatLoadMessages>(_onLoadMessages);
    on<EmployerChatSendMessage>(_onSendMessage);
  }

  List<ChatConversation> _conversations = [];

  void _onLoadConversations(
      EmployerChatLoadConversations event, Emitter<EmployerChatState> emit) {
    _conversations = List.of(mockEmployerConversations);
    emit(EmployerChatConversationsLoaded(_conversations));
  }

  void _onLoadMessages(
      EmployerChatLoadMessages event, Emitter<EmployerChatState> emit) {
    final conversation = _conversations.firstWhere(
      (c) => c.id == event.conversationId,
      orElse: () => _conversations.first,
    );
    final messages = mockEmployerMessages[event.conversationId] ?? [];
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

    final existing = mockEmployerMessages[event.conversationId] ?? [];
    mockEmployerMessages[event.conversationId] = [...existing, newMessage];

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

    emit(EmployerChatMessagesLoaded(
      conversationId: event.conversationId,
      conversation: _conversations[idx],
      messages: mockEmployerMessages[event.conversationId]!,
    ));
  }
}
