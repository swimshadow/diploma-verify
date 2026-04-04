import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final Map<String, dynamic> profile;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.role,
    required this.profile,
  });

  @override
  List<Object?> get props => [email, password, role, profile];
}

class AuthLogoutRequested extends AuthEvent {}
