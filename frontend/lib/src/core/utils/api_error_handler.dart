import 'package:dio/dio.dart';

/// Extracts a user-friendly error message from any exception.
///
/// Handles FastAPI error responses ({detail: ...}), network errors,
/// timeouts, and generic exceptions.
class ApiErrorHandler {
  const ApiErrorHandler._();

  /// Extract a human-readable message from [error].
  static String message(Object error) {
    if (error is DioException) return _fromDio(error);
    return 'Произошла непредвиденная ошибка';
  }

  static String _fromDio(DioException e) {
    // 1. Try to read FastAPI's `detail` field
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.map((d) {
          if (d is Map<String, dynamic>) {
            final field = _fieldLabel(d['loc']);
            final msg = d['msg']?.toString() ?? '';
            return field.isNotEmpty ? '$field: $msg' : msg;
          }
          return d.toString();
        }).join('\n');
      }
      return detail.toString();
    }

    // 2. Well-known HTTP status codes
    final status = e.response?.statusCode;
    switch (status) {
      case 400:
        return 'Неверный запрос. Проверьте введённые данные.';
      case 401:
        return 'Необходима авторизация.';
      case 403:
        return 'Доступ запрещён.';
      case 404:
        return 'Ресурс не найден.';
      case 409:
        return 'Конфликт данных. Возможно, запись уже существует.';
      case 413:
        return 'Файл слишком большой.';
      case 422:
        return 'Некорректные данные. Проверьте заполненные поля.';
      case 429:
        return 'Слишком много запросов. Подождите немного.';
      case 500:
        return 'Ошибка сервера. Попробуйте позже.';
      case 502:
      case 503:
        return 'Сервис временно недоступен.';
    }

    // 3. Network / timeout
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Сервер не отвечает. Проверьте подключение к сети.';
      case DioExceptionType.connectionError:
        return 'Нет подключения к серверу. Проверьте интернет-соединение.';
      case DioExceptionType.cancel:
        return 'Запрос был отменён.';
      default:
        break;
    }

    // 4. Fallback
    return 'Произошла ошибка. Попробуйте снова.';
  }

  /// Extracts a human-readable field name from FastAPI's `loc` array.
  /// e.g. ["body","email"] → "Email"
  static String _fieldLabel(dynamic loc) {
    if (loc is! List || loc.length < 2) return '';
    final raw = loc.last.toString();
    return _fieldNames[raw] ?? _capitalize(raw);
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static const _fieldNames = {
    'email': 'Email',
    'password': 'Пароль',
    'full_name': 'ФИО',
    'date_of_birth': 'Дата рождения',
    'company_name': 'Название компании',
    'inn': 'ИНН',
    'ogrn': 'ОГРН',
    'name': 'Название',
    'diploma_number': 'Номер диплома',
    'series': 'Серия',
    'issue_date': 'Дата выдачи',
    'specialization': 'Специализация',
    'degree': 'Степень',
    'role': 'Роль',
  };
}
