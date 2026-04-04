import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/app_logger.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const _tag = 'AuthBloc';
  final _log = AppLogger.instance;
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    _log.info(_tag, 'AuthBloc создан');
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    _log.info(_tag, '_onCheckRequested → проверка сессии');
    emit(AuthLoading());
    try {
      final hasSession = await _repository.hasSession();
      _log.info(_tag, '_onCheckRequested: hasSession=$hasSession');
      if (!hasSession) {
        _log.info(_tag, '_onCheckRequested → AuthUnauthenticated (нет сессии)');
        emit(AuthUnauthenticated());
        return;
      }
      final user = await _repository.me();
      _log.info(_tag, '_onCheckRequested → AuthAuthenticated: role=${user.role}');
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      _log.error(_tag, '_onCheckRequested ОШИБКА', e, st);
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    _log.info(_tag, '_onLoginRequested → email=${event.email}');
    emit(AuthLoading());
    try {
      await _repository.login(email: event.email, password: event.password);
      _log.info(_tag, '_onLoginRequested: login OK, загрузка профиля…');
      final fullUser = await _repository.me();
      _log.info(_tag, '_onLoginRequested → AuthAuthenticated: role=${fullUser.role}');
      emit(AuthAuthenticated(fullUser));
    } on DioException catch (e) {
      final msg = _extractError(e);
      _log.error(_tag, '_onLoginRequested ОШИБКА: $msg', e);
      emit(AuthFailure(msg));
      emit(AuthUnauthenticated());
    } catch (e, st) {
      _log.error(_tag, '_onLoginRequested ОШИБКА (неожиданная)', e, st);
      emit(AuthFailure(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    _log.info(_tag, '_onRegisterRequested → email=${event.email}, role=${event.role}');
    emit(AuthLoading());
    try {
      await _repository.register(
        email: event.email,
        password: event.password,
        role: event.role,
        profile: event.profile,
      );
      _log.info(_tag, '_onRegisterRequested → AuthRegistered');
      emit(AuthRegistered());
    } on DioException catch (e) {
      final msg = _extractError(e);
      _log.error(_tag, '_onRegisterRequested ОШИБКА: $msg', e);
      emit(AuthFailure(msg));
    } catch (e, st) {
      _log.error(_tag, '_onRegisterRequested ОШИБКА (неожиданная)', e, st);
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    _log.info(_tag, '_onLogoutRequested → выход');
    await _repository.logout();
    _log.info(_tag, '_onLogoutRequested → AuthUnauthenticated');
    emit(AuthUnauthenticated());
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.map((d) => d['msg'] ?? d.toString()).join('; ');
      }
      return detail.toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Сервер не отвечает. Проверьте подключение.';
    }
    return 'Произошла ошибка. Попробуйте снова.';
  }
}
