import 'package:equatable/equatable.dart';
import '../data/models/employee_model.dart';
import '../data/models/verification_model.dart';

abstract class EmployerState extends Equatable {
  const EmployerState();
  @override
  List<Object?> get props => [];
}

class EmployerInitial extends EmployerState {}

class EmployerLoading extends EmployerState {}

class EmployerLoaded extends EmployerState {
  final List<Employee> employees;
  final List<VerificationHistoryEntry> history;

  const EmployerLoaded({
    required this.employees,
    required this.history,
  });

  int get totalEmployees => employees.length;
  int get verifiedCount =>
      employees.where((e) => e.diplomaStatus == VerificationStatus.verified).length;
  int get suspiciousCount =>
      employees.where((e) => e.diplomaStatus == VerificationStatus.suspicious).length;
  int get pendingCount =>
      employees.where((e) => e.diplomaStatus == VerificationStatus.pending).length;

  @override
  List<Object?> get props => [employees, history];
}

class EmployerFailure extends EmployerState {
  final String message;
  const EmployerFailure(this.message);
  @override
  List<Object?> get props => [message];
}
