import 'models/search_model.dart';

/// Searchable index combining data from all roles/features
final List<SearchResult> searchableItems = [
  // Diplomas (student)
  const SearchResult(
    id: 'dip-001',
    type: SearchResultType.diploma,
    title: 'Бакалавр информатики',
    subtitle: 'МГУ · БА-2024-001234 · Иванов И.И.',
    route: '/student/diploma/dip-001',
  ),
  const SearchResult(
    id: 'dip-002',
    type: SearchResultType.diploma,
    title: 'Магистр экономики',
    subtitle: 'НИУ ВШЭ · МА-2025-005678 · Иванов И.И.',
    route: '/student/diploma/dip-002',
  ),
  const SearchResult(
    id: 'dip-003',
    type: SearchResultType.diploma,
    title: 'Бакалавр юриспруденции',
    subtitle: 'МГЮА · БА-2023-009012 · Иванов И.И.',
    route: '/student/diploma/dip-003',
  ),

  // Employees (employer)
  const SearchResult(
    id: 'emp-001',
    type: SearchResultType.employee,
    title: 'Иванов Иван Иванович',
    subtitle: 'Разработчик · ООО "ТехноСофт"',
    route: '/employer/employee/emp-001',
  ),
  const SearchResult(
    id: 'emp-002',
    type: SearchResultType.employee,
    title: 'Петрова Анна Сергеевна',
    subtitle: 'Аналитик · ООО "ТехноСофт"',
    route: '/employer/employee/emp-002',
  ),
  const SearchResult(
    id: 'emp-003',
    type: SearchResultType.employee,
    title: 'Сидоров Пётр Алексеевич',
    subtitle: 'DevOps · ООО "ТехноСофт"',
    route: '/employer/employee/emp-003',
  ),

  // Universities
  const SearchResult(
    id: 'uni-001',
    type: SearchResultType.university,
    title: 'МГУ им. М.В. Ломоносова',
    subtitle: 'Москва · Одобрен',
  ),
  const SearchResult(
    id: 'uni-002',
    type: SearchResultType.university,
    title: 'НИУ ВШЭ',
    subtitle: 'Москва · Одобрен',
  ),
  const SearchResult(
    id: 'uni-003',
    type: SearchResultType.university,
    title: 'МГЮА им. О.Е. Кутафина',
    subtitle: 'Москва · На модерации',
  ),

  // Users (admin)
  const SearchResult(
    id: 'user-admin',
    type: SearchResultType.user,
    title: 'Админ Системный',
    subtitle: 'admin@diplomaverify.ru · admin',
  ),
  const SearchResult(
    id: 'user-student',
    type: SearchResultType.user,
    title: 'Иванов Иван Иванович',
    subtitle: 'ivanov@mail.ru · student',
  ),

  // Certificate IDs
  const SearchResult(
    id: 'cert-a1b2c3d4',
    type: SearchResultType.diploma,
    title: 'Сертификат CERT-A1B2C3D4',
    subtitle: 'Бакалавр информатики · МГУ',
    route: '/student/certificate/CERT-A1B2C3D4',
  ),
];
