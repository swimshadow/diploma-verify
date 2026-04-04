import 'package:equatable/equatable.dart';

class PlatformUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const PlatformUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.isBlocked = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [id, isBlocked, role];
}

enum ModerationStatus { pending, approved, rejected }

extension ModerationStatusX on ModerationStatus {
  String get label {
    switch (this) {
      case ModerationStatus.pending:
        return 'На модерации';
      case ModerationStatus.approved:
        return 'Подтверждён';
      case ModerationStatus.rejected:
        return 'Отклонён';
    }
  }
}

class ModerationUniversity extends Equatable {
  final String id;
  final String name;
  final String city;
  final String contactEmail;
  final ModerationStatus status;
  final String? moderatorComment;
  final DateTime appliedAt;

  const ModerationUniversity({
    required this.id,
    required this.name,
    required this.city,
    required this.contactEmail,
    required this.status,
    this.moderatorComment,
    required this.appliedAt,
  });

  @override
  List<Object?> get props => [id, status];
}

enum AdminDiplomaStatus { verified, rejected, disputed, pendingReview }

extension AdminDiplomaStatusX on AdminDiplomaStatus {
  String get label {
    switch (this) {
      case AdminDiplomaStatus.verified:
        return 'Подтверждён';
      case AdminDiplomaStatus.rejected:
        return 'Отклонён';
      case AdminDiplomaStatus.disputed:
        return 'Спорный';
      case AdminDiplomaStatus.pendingReview:
        return 'Ожидает проверки';
    }
  }
}

class AdminDiploma extends Equatable {
  final String id;
  final String holderName;
  final String universityName;
  final String diplomaNumber;
  final AdminDiplomaStatus status;
  final double trustScore;
  final String? ocrText;
  final String? fileUrl;
  final DateTime uploadedAt;

  const AdminDiploma({
    required this.id,
    required this.holderName,
    required this.universityName,
    required this.diplomaNumber,
    required this.status,
    required this.trustScore,
    this.ocrText,
    this.fileUrl,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [id, status];
}

enum ServiceStatus { healthy, degraded, down }

class ServiceHealth extends Equatable {
  final String name;
  final ServiceStatus status;
  final int queueSize;
  final double avgResponseMs;
  final int errorsLast24h;

  const ServiceHealth({
    required this.name,
    required this.status,
    this.queueSize = 0,
    this.avgResponseMs = 0,
    this.errorsLast24h = 0,
  });

  @override
  List<Object?> get props => [name, status];
}

enum LogAction { login, logout, roleChange, statusChange, block, unblock, diplomaReview, moderationDecision }

extension LogActionX on LogAction {
  String get label {
    switch (this) {
      case LogAction.login:
        return 'Вход';
      case LogAction.logout:
        return 'Выход';
      case LogAction.roleChange:
        return 'Смена роли';
      case LogAction.statusChange:
        return 'Смена статуса';
      case LogAction.block:
        return 'Блокировка';
      case LogAction.unblock:
        return 'Разблокировка';
      case LogAction.diplomaReview:
        return 'Проверка диплома';
      case LogAction.moderationDecision:
        return 'Модерация';
    }
  }
}

class AuditLog extends Equatable {
  final String id;
  final LogAction action;
  final String actorEmail;
  final String targetDescription;
  final DateTime timestamp;
  final String? details;

  const AuditLog({
    required this.id,
    required this.action,
    required this.actorEmail,
    required this.targetDescription,
    required this.timestamp,
    this.details,
  });

  @override
  List<Object?> get props => [id];
}
