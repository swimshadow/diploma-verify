import 'package:equatable/equatable.dart';

enum VerificationStatus {
  verified,
  pending,
  suspicious,
  notChecked,
}

extension VerificationStatusX on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.verified:
        return 'Подтверждён';
      case VerificationStatus.pending:
        return 'На проверке';
      case VerificationStatus.suspicious:
        return 'Подозрительный';
      case VerificationStatus.notChecked:
        return 'Не проверен';
    }
  }
}

class Employee extends Equatable {
  final String id;
  final String fullName;
  final String position;
  final String department;
  final String email;
  final String? phone;
  final VerificationStatus diplomaStatus;
  final List<String> diplomaIds;
  final DateTime hiredAt;

  const Employee({
    required this.id,
    required this.fullName,
    required this.position,
    required this.department,
    required this.email,
    this.phone,
    required this.diplomaStatus,
    required this.diplomaIds,
    required this.hiredAt,
  });

  @override
  List<Object?> get props => [id, diplomaStatus];
}
