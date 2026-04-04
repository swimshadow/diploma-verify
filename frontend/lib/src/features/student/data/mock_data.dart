import 'package:uuid/uuid.dart';
import 'models/diploma_model.dart';
import 'models/chat_model.dart';

const _uuid = Uuid();

final List<Diploma> mockDiplomas = [
  Diploma(
    id: 'dip-001',
    title: 'Бакалавр информатики',
    university: 'МГУ им. М.В. Ломоносова',
    speciality: 'Программная инженерия',
    diplomaNumber: 'БА-2024-001234',
    issueDate: DateTime(2024, 6, 28),
    status: DiplomaStatus.verified,
    trustScore: 0.97,
    certificateId: 'CERT-A1B2C3D4',
    fileUrl: null,
    createdAt: DateTime(2024, 7, 1),
    timeline: [
      VerificationStep(
        title: 'Загружен',
        completedAt: DateTime(2024, 7, 1, 10, 0),
      ),
      VerificationStep(
        title: 'В обработке',
        completedAt: DateTime(2024, 7, 1, 10, 5),
      ),
      VerificationStep(
        title: 'Распознан AI',
        completedAt: DateTime(2024, 7, 1, 10, 12),
      ),
      VerificationStep(
        title: 'Подтверждён университетом',
        completedAt: DateTime(2024, 7, 2, 14, 30),
      ),
    ],
  ),
  Diploma(
    id: 'dip-002',
    title: 'Магистр экономики',
    university: 'НИУ ВШЭ',
    speciality: 'Финансовая аналитика',
    diplomaNumber: 'МА-2025-005678',
    issueDate: DateTime(2025, 6, 15),
    status: DiplomaStatus.processing,
    trustScore: 0.45,
    certificateId: null,
    fileUrl: null,
    createdAt: DateTime(2025, 7, 10),
    timeline: [
      VerificationStep(
        title: 'Загружен',
        completedAt: DateTime(2025, 7, 10, 9, 0),
      ),
      VerificationStep(
        title: 'В обработке',
        completedAt: DateTime(2025, 7, 10, 9, 3),
      ),
      const VerificationStep(
        title: 'Распознавание AI',
        isCurrent: true,
      ),
      const VerificationStep(title: 'Подтверждение университетом'),
    ],
  ),
  Diploma(
    id: 'dip-003',
    title: 'Бакалавр юриспруденции',
    university: 'МГЮА им. О.Е. Кутафина',
    speciality: 'Гражданское право',
    diplomaNumber: 'БА-2023-009012',
    issueDate: DateTime(2023, 6, 30),
    status: DiplomaStatus.rejected,
    trustScore: 0.12,
    certificateId: null,
    fileUrl: null,
    createdAt: DateTime(2024, 1, 15),
    timeline: [
      VerificationStep(
        title: 'Загружен',
        completedAt: DateTime(2024, 1, 15, 12, 0),
      ),
      VerificationStep(
        title: 'В обработке',
        completedAt: DateTime(2024, 1, 15, 12, 4),
      ),
      VerificationStep(
        title: 'Распознан AI',
        completedAt: DateTime(2024, 1, 15, 12, 15),
      ),
      VerificationStep(
        title: 'Отклонён: данные не совпадают',
        completedAt: DateTime(2024, 1, 16, 10, 0),
      ),
    ],
  ),
];

final List<ChatConversation> mockConversations = [
  ChatConversation(
    id: 'chat-001',
    participantName: 'ООО "ТехноСофт"',
    participantRole: 'employer',
    diplomaId: 'dip-001',
    diplomaTitle: 'Бакалавр информатики',
    lastMessage: 'Спасибо, диплом подтверждён! Ждём вас на собеседовании.',
    lastMessageAt: DateTime(2025, 3, 15, 14, 30),
    unreadCount: 1,
  ),
  ChatConversation(
    id: 'chat-002',
    participantName: 'АО "Финансгрупп"',
    participantRole: 'employer',
    diplomaId: 'dip-002',
    diplomaTitle: 'Магистр экономики',
    lastMessage: 'Здравствуйте! Можете ли вы предоставить скан диплома?',
    lastMessageAt: DateTime(2025, 3, 10, 9, 15),
    unreadCount: 0,
  ),
];

final Map<String, List<ChatMessage>> mockMessages = {
  'chat-001': [
    ChatMessage(
      id: _uuid.v4(),
      conversationId: 'chat-001',
      senderId: 'employer-1',
      text:
          'Здравствуйте! Мы рассматриваем вашу кандидатуру. Можете поделиться ссылкой на проверку диплома?',
      sentAt: DateTime(2025, 3, 14, 10, 0),
      isMe: false,
    ),
    ChatMessage(
      id: _uuid.v4(),
      conversationId: 'chat-001',
      senderId: 'me',
      text: 'Добрый день! Конечно, вот ссылка на сертификат: CERT-A1B2C3D4',
      sentAt: DateTime(2025, 3, 14, 11, 30),
      isMe: true,
    ),
    ChatMessage(
      id: _uuid.v4(),
      conversationId: 'chat-001',
      senderId: 'employer-1',
      text: 'Спасибо, диплом подтверждён! Ждём вас на собеседовании.',
      sentAt: DateTime(2025, 3, 15, 14, 30),
      isMe: false,
    ),
  ],
  'chat-002': [
    ChatMessage(
      id: _uuid.v4(),
      conversationId: 'chat-002',
      senderId: 'employer-2',
      text: 'Здравствуйте! Можете ли вы предоставить скан диплома?',
      sentAt: DateTime(2025, 3, 10, 9, 15),
      isMe: false,
    ),
  ],
};
