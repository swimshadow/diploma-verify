import 'models/employee_model.dart';
import 'models/verification_model.dart';
import '../../student/data/models/diploma_model.dart';
import '../../student/data/models/chat_model.dart';

// ── Employees ──

final List<Employee> mockEmployees = [
  Employee(
    id: 'emp-001',
    fullName: 'Иванов Алексей Петрович',
    position: 'Разработчик',
    department: 'IT-отдел',
    email: 'ivanov@technosoft.ru',
    phone: '+7 (999) 123-45-67',
    diplomaStatus: VerificationStatus.verified,
    diplomaIds: ['dip-001'],
    hiredAt: DateTime(2024, 9, 1),
  ),
  Employee(
    id: 'emp-002',
    fullName: 'Петрова Мария Сергеевна',
    position: 'Аналитик',
    department: 'Финансовый отдел',
    email: 'petrova@technosoft.ru',
    phone: '+7 (999) 234-56-78',
    diplomaStatus: VerificationStatus.pending,
    diplomaIds: ['dip-002'],
    hiredAt: DateTime(2025, 2, 15),
  ),
  Employee(
    id: 'emp-003',
    fullName: 'Сидоров Дмитрий Олегович',
    position: 'Юрист',
    department: 'Юридический отдел',
    email: 'sidorov@technosoft.ru',
    diplomaStatus: VerificationStatus.suspicious,
    diplomaIds: ['dip-003'],
    hiredAt: DateTime(2024, 3, 10),
  ),
  Employee(
    id: 'emp-004',
    fullName: 'Козлова Елена Игоревна',
    position: 'HR-менеджер',
    department: 'HR-отдел',
    email: 'kozlova@technosoft.ru',
    diplomaStatus: VerificationStatus.notChecked,
    diplomaIds: [],
    hiredAt: DateTime(2025, 1, 20),
  ),
];

// ── Verification Results ──

final List<VerificationResult> mockVerificationResults = [
  VerificationResult(
    id: 'vr-001',
    diplomaTitle: 'Бакалавр информатики',
    holderName: 'Иванов Алексей Петрович',
    university: 'МГУ им. М.В. Ломоносова',
    speciality: 'Программная инженерия',
    diplomaNumber: 'БА-2024-001234',
    issueDate: DateTime(2024, 6, 28),
    isAuthentic: true,
    trustScore: 0.97,
    antifraudScore: 0.95,
    antifraudVerdict: 'Подлинный документ',
    warnings: [],
    method: VerifyMethod.certificateId,
    verifiedAt: DateTime(2025, 3, 1, 10, 30),
  ),
  VerificationResult(
    id: 'vr-002',
    diplomaTitle: 'Магистр экономики',
    holderName: 'Петрова Мария Сергеевна',
    university: 'НИУ ВШЭ',
    speciality: 'Финансовая аналитика',
    diplomaNumber: 'МА-2025-005678',
    issueDate: DateTime(2025, 6, 15),
    isAuthentic: true,
    trustScore: 0.45,
    antifraudScore: 0.60,
    antifraudVerdict: 'Требуется дополнительная проверка',
    warnings: ['Низкий Trust Score', 'Диплом ещё на проверке в университете'],
    method: VerifyMethod.fileUpload,
    verifiedAt: DateTime(2025, 3, 10, 14, 0),
  ),
  VerificationResult(
    id: 'vr-003',
    diplomaTitle: 'Бакалавр юриспруденции',
    holderName: 'Сидоров Дмитрий Олегович',
    university: 'МГЮА им. О.Е. Кутафина',
    speciality: 'Гражданское право',
    diplomaNumber: 'БА-2023-009012',
    issueDate: DateTime(2023, 6, 30),
    isAuthentic: false,
    trustScore: 0.12,
    antifraudScore: 0.15,
    antifraudVerdict: 'Подозрение на подделку',
    warnings: [
      'Данные диплома не совпадают с реестром',
      'Шрифт документа отличается от стандартного',
      'QR-код отсутствует',
    ],
    method: VerifyMethod.qr,
    verifiedAt: DateTime(2025, 1, 16, 11, 0),
  ),
];

// ── Verification History ──

final List<VerificationHistoryEntry> mockVerificationHistory = [
  VerificationHistoryEntry(
    id: 'vh-001',
    diplomaTitle: 'Бакалавр информатики',
    holderName: 'Иванов А.П.',
    method: VerifyMethod.certificateId,
    isAuthentic: true,
    confidenceScore: 0.97,
    checkedAt: DateTime(2025, 3, 1, 10, 30),
  ),
  VerificationHistoryEntry(
    id: 'vh-002',
    diplomaTitle: 'Магистр экономики',
    holderName: 'Петрова М.С.',
    method: VerifyMethod.fileUpload,
    isAuthentic: true,
    confidenceScore: 0.45,
    checkedAt: DateTime(2025, 3, 10, 14, 0),
  ),
  VerificationHistoryEntry(
    id: 'vh-003',
    diplomaTitle: 'Бакалавр юриспруденции',
    holderName: 'Сидоров Д.О.',
    method: VerifyMethod.qr,
    isAuthentic: false,
    confidenceScore: 0.12,
    checkedAt: DateTime(2025, 1, 16, 11, 0),
  ),
  VerificationHistoryEntry(
    id: 'vh-004',
    diplomaTitle: 'Бакалавр информатики',
    holderName: 'Иванов А.П.',
    method: VerifyMethod.qr,
    isAuthentic: true,
    confidenceScore: 0.97,
    checkedAt: DateTime(2024, 12, 20, 9, 0),
  ),
  VerificationHistoryEntry(
    id: 'vh-005',
    diplomaTitle: 'Магистр экономики',
    holderName: 'Петрова М.С.',
    method: VerifyMethod.certificateId,
    isAuthentic: true,
    confidenceScore: 0.55,
    checkedAt: DateTime(2025, 2, 28, 16, 45),
  ),
];

// ── Employee diplomas (maps employee ID → diploma list) ──

final Map<String, List<Diploma>> mockEmployeeDiplomas = {
  'emp-001': [
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
      createdAt: DateTime(2024, 7, 1),
      timeline: [
        VerificationStep(title: 'Загружен', completedAt: DateTime(2024, 7, 1, 10, 0)),
        VerificationStep(title: 'В обработке', completedAt: DateTime(2024, 7, 1, 10, 5)),
        VerificationStep(title: 'Распознан AI', completedAt: DateTime(2024, 7, 1, 10, 12)),
        VerificationStep(title: 'Подтверждён университетом', completedAt: DateTime(2024, 7, 2, 14, 30)),
      ],
    ),
  ],
  'emp-002': [
    Diploma(
      id: 'dip-002',
      title: 'Магистр экономики',
      university: 'НИУ ВШЭ',
      speciality: 'Финансовая аналитика',
      diplomaNumber: 'МА-2025-005678',
      issueDate: DateTime(2025, 6, 15),
      status: DiplomaStatus.processing,
      trustScore: 0.45,
      createdAt: DateTime(2025, 7, 10),
      timeline: [
        VerificationStep(title: 'Загружен', completedAt: DateTime(2025, 7, 10, 9, 0)),
        VerificationStep(title: 'В обработке', completedAt: DateTime(2025, 7, 10, 9, 3)),
        const VerificationStep(title: 'Распознавание AI', isCurrent: true),
        const VerificationStep(title: 'Подтверждение университетом'),
      ],
    ),
  ],
  'emp-003': [
    Diploma(
      id: 'dip-003',
      title: 'Бакалавр юриспруденции',
      university: 'МГЮА им. О.Е. Кутафина',
      speciality: 'Гражданское право',
      diplomaNumber: 'БА-2023-009012',
      issueDate: DateTime(2023, 6, 30),
      status: DiplomaStatus.rejected,
      trustScore: 0.12,
      createdAt: DateTime(2024, 1, 15),
      timeline: [
        VerificationStep(title: 'Загружен', completedAt: DateTime(2024, 1, 15, 12, 0)),
        VerificationStep(title: 'В обработке', completedAt: DateTime(2024, 1, 15, 12, 4)),
        VerificationStep(title: 'Распознан AI', completedAt: DateTime(2024, 1, 15, 12, 15)),
        VerificationStep(title: 'Отклонён: данные не совпадают', completedAt: DateTime(2024, 1, 16, 10, 0)),
      ],
    ),
  ],
};

// ── Employer chat conversations ──

final List<ChatConversation> mockEmployerConversations = [
  ChatConversation(
    id: 'echat-001',
    participantName: 'Иванов Алексей Петрович',
    participantRole: 'student',
    diplomaId: 'dip-001',
    diplomaTitle: 'Бакалавр информатики',
    lastMessage: 'Спасибо, диплом подтверждён! Ждём вас на собеседовании.',
    lastMessageAt: DateTime(2025, 3, 15, 14, 30),
    unreadCount: 0,
  ),
  ChatConversation(
    id: 'echat-002',
    participantName: 'Петрова Мария Сергеевна',
    participantRole: 'student',
    diplomaId: 'dip-002',
    diplomaTitle: 'Магистр экономики',
    lastMessage: 'Здравствуйте! Можете ли вы предоставить скан диплома?',
    lastMessageAt: DateTime(2025, 3, 10, 9, 15),
    unreadCount: 2,
  ),
];

final Map<String, List<ChatMessage>> mockEmployerMessages = {
  'echat-001': [
    ChatMessage(
      id: 'em-1',
      conversationId: 'echat-001',
      senderId: 'me',
      text: 'Здравствуйте! Мы рассматриваем вашу кандидатуру. Можете поделиться ссылкой на проверку диплома?',
      sentAt: DateTime(2025, 3, 14, 10, 0),
      isMe: true,
    ),
    ChatMessage(
      id: 'em-2',
      conversationId: 'echat-001',
      senderId: 'student-1',
      text: 'Добрый день! Конечно, вот ссылка на сертификат: CERT-A1B2C3D4',
      sentAt: DateTime(2025, 3, 14, 11, 30),
      isMe: false,
    ),
    ChatMessage(
      id: 'em-3',
      conversationId: 'echat-001',
      senderId: 'me',
      text: 'Спасибо, диплом подтверждён! Ждём вас на собеседовании.',
      sentAt: DateTime(2025, 3, 15, 14, 30),
      isMe: true,
    ),
  ],
  'echat-002': [
    ChatMessage(
      id: 'em-4',
      conversationId: 'echat-002',
      senderId: 'me',
      text: 'Здравствуйте! Можете ли вы предоставить скан диплома?',
      sentAt: DateTime(2025, 3, 10, 9, 15),
      isMe: true,
    ),
  ],
};
