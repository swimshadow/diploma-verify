import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final hasSession = await _repository.hasSession();
      if (!hasSession) {
        emit(AuthUnauthenticated());
        return;
      }
      final user = await _repository.me();
      emit(AuthAuthenticated(user));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.login(email: event.email, password: event.password);
      // Fetch full profile from /me
      final fullUser = await _repository.me();
      emit(AuthAuthenticated(fullUser));
    } on DioException catch (e) {
      final msg = _extractError(e);
      emit(AuthFailure(msg));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.register(
        email: event.email,
        password: event.password,
        role: event.role,
        profile: event.profile,
      );
      emit(AuthRegistered());
    } on DioException catch (e) {
      final msg = _extractError(e);
      emit(AuthFailure(msg));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
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
