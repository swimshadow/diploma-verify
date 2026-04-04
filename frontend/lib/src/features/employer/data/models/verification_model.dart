import 'package:equatable/equatable.dart';

enum VerifyMethod {
  qr,
  certificateId,
  fileUpload,
}

extension VerifyMethodX on VerifyMethod {
  String get label {
    switch (this) {
      case VerifyMethod.qr:
        return 'QR-код';
      case VerifyMethod.certificateId:
        return 'ID сертификата';
      case VerifyMethod.fileUpload:
        return 'Загрузка файла';
    }
  }

  String get icon {
    switch (this) {
      case VerifyMethod.qr:
        return 'qr_code_scanner';
      case VerifyMethod.certificateId:
        return 'fingerprint';
      case VerifyMethod.fileUpload:
        return 'upload_file';
    }
  }
}

class VerificationResult extends Equatable {
  final String id;
  final String diplomaTitle;
  final String holderName;
  final String university;
  final String speciality;
  final String diplomaNumber;
  final DateTime issueDate;
  final bool isAuthentic;
  final double trustScore;
  final double antifraudScore;
  final String antifraudVerdict;
  final List<String> warnings;
  final VerifyMethod method;
  final DateTime verifiedAt;

  const VerificationResult({
    required this.id,
    required this.diplomaTitle,
    required this.holderName,
    required this.university,
    required this.speciality,
    required this.diplomaNumber,
    required this.issueDate,
    required this.isAuthentic,
    required this.trustScore,
    required this.antifraudScore,
    required this.antifraudVerdict,
    required this.warnings,
    required this.method,
    required this.verifiedAt,
  });

  @override
  List<Object?> get props => [id, trustScore, antifraudScore];
}

class VerificationHistoryEntry extends Equatable {
  final String id;
  final String diplomaTitle;
  final String holderName;
  final VerifyMethod method;
  final bool isAuthentic;
  final double confidenceScore;
  final DateTime checkedAt;

  const VerificationHistoryEntry({
    required this.id,
    required this.diplomaTitle,
    required this.holderName,
    required this.method,
    required this.isAuthentic,
    required this.confidenceScore,
    required this.checkedAt,
  });

  @override
  List<Object?> get props => [id, checkedAt];
}
