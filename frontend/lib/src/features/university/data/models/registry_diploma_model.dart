import 'package:equatable/equatable.dart';

enum RegistryDiplomaStatus {
  active,
  revoked,
  pendingReview,
}

extension RegistryDiplomaStatusX on RegistryDiplomaStatus {
  String get label {
    switch (this) {
      case RegistryDiplomaStatus.active:
        return 'Активен';
      case RegistryDiplomaStatus.revoked:
        return 'Отозван';
      case RegistryDiplomaStatus.pendingReview:
        return 'На рассмотрении';
    }
  }
}

class RegistryDiploma extends Equatable {
  final String id;
  final String holderFullName;
  final String faculty;
  final String speciality;
  final String educationLevel;
  final String diplomaSeries;
  final String diplomaNumber;
  final DateTime issueDate;
  final double gpa;
  final RegistryDiplomaStatus status;
  final String? certificateId;
  final double trustScore;
  final DateTime createdAt;
  final List<EmployerCheck> employerChecks;
  final double antifraudScore;
  final String antifraudVerdict;
  final List<String> antifraudWarnings;

  const RegistryDiploma({
    required this.id,
    required this.holderFullName,
    required this.faculty,
    required this.speciality,
    required this.educationLevel,
    required this.diplomaSeries,
    required this.diplomaNumber,
    required this.issueDate,
    required this.gpa,
    required this.status,
    this.certificateId,
    required this.trustScore,
    required this.createdAt,
    this.employerChecks = const [],
    this.antifraudScore = 0.0,
    this.antifraudVerdict = '',
    this.antifraudWarnings = const [],
  });

  @override
  List<Object?> get props => [id, status, trustScore, antifraudScore];
}

class EmployerCheck extends Equatable {
  final String employerName;
  final DateTime checkedAt;
  final bool isAuthentic;

  const EmployerCheck({
    required this.employerName,
    required this.checkedAt,
    required this.isAuthentic,
  });

  @override
  List<Object?> get props => [employerName, checkedAt];
}
