import 'package:equatable/equatable.dart';

enum CertificateStatus { active, expired, revoked, reissued }

extension CertificateStatusX on CertificateStatus {
  String get label {
    switch (this) {
      case CertificateStatus.active:
        return 'Активен';
      case CertificateStatus.expired:
        return 'Истёк';
      case CertificateStatus.revoked:
        return 'Отозван';
      case CertificateStatus.reissued:
        return 'Перевыпущен';
    }
  }
}

class UniversityCertificate extends Equatable {
  final String id;
  final String diplomaId;
  final String holderFullName;
  final String diplomaNumber;
  final CertificateStatus status;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int checksCount;

  const UniversityCertificate({
    required this.id,
    required this.diplomaId,
    required this.holderFullName,
    required this.diplomaNumber,
    required this.status,
    required this.issuedAt,
    this.expiresAt,
    this.checksCount = 0,
  });

  bool get canReissue =>
      status == CertificateStatus.expired ||
      status == CertificateStatus.revoked;

  @override
  List<Object?> get props => [id, status];
}
