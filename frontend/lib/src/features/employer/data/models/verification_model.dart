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
  final bool signatureVerified;
  final bool blockchainVerified;
  final int? blockchainBlock;
  final bool chainIntact;
  final String? timestampProof;
  final String? reason;
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
    this.signatureVerified = false,
    this.blockchainVerified = false,
    this.blockchainBlock,
    this.chainIntact = false,
    this.timestampProof,
    this.reason,
    required this.method,
    required this.verifiedAt,
  });

  @override
  List<Object?> get props => [id, isAuthentic, signatureVerified];
}

class VerificationHistoryEntry extends Equatable {
  final String id;
  final String? diplomaId;
  final VerifyMethod method;
  final bool isAuthentic;
  final DateTime checkedAt;

  const VerificationHistoryEntry({
    required this.id,
    this.diplomaId,
    required this.method,
    required this.isAuthentic,
    required this.checkedAt,
  });

  @override
  List<Object?> get props => [id, checkedAt];
}
