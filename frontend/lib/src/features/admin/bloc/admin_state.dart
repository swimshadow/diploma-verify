import 'package:equatable/equatable.dart';
import '../data/models/admin_models.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<PlatformUser> users;
  final List<ModerationUniversity> universities;
  final List<AdminDiploma> diplomas;
  final List<ServiceHealth> services;
  final List<AuditLog> logs;

  const AdminLoaded({
    required this.users,
    required this.universities,
    required this.diplomas,
    required this.services,
    required this.logs,
  });

  int get totalUsers => users.length;
  int get studentCount => users.where((u) => u.role == 'student').length;
  int get employerCount => users.where((u) => u.role == 'employer').length;
  int get universityCount => users.where((u) => u.role == 'university').length;
  int get adminCount => users.where((u) => u.role == 'admin').length;
  int get blockedCount => users.where((u) => u.isBlocked).length;

  int get pendingUniversities =>
      universities.where((u) => u.status == ModerationStatus.pending).length;
  int get disputedDiplomas =>
      diplomas.where((d) => d.status == AdminDiplomaStatus.disputed || d.status == AdminDiplomaStatus.pendingReview).length;
  int get verifiedDiplomas =>
      diplomas.where((d) => d.status == AdminDiplomaStatus.verified).length;

  int get healthyServices =>
      services.where((s) => s.status == ServiceStatus.healthy).length;
  int get degradedServices =>
      services.where((s) => s.status == ServiceStatus.degraded).length;
  int get downServices =>
      services.where((s) => s.status == ServiceStatus.down).length;

  @override
  List<Object?> get props => [users, universities, diplomas, services, logs];
}

class AdminFailure extends AdminState {
  final String message;
  const AdminFailure(this.message);
  @override
  List<Object?> get props => [message];
}
