import 'package:equatable/equatable.dart';

enum DiplomaStatus {
  uploaded,
  processing,
  recognized,
  verified,
  rejected,
}

extension DiplomaStatusX on DiplomaStatus {
  String get label {
    switch (this) {
      case DiplomaStatus.uploaded:
        return 'Загружен';
      case DiplomaStatus.processing:
        return 'В обработке';
      case DiplomaStatus.recognized:
        return 'Распознан';
      case DiplomaStatus.verified:
        return 'Подтверждён';
      case DiplomaStatus.rejected:
        return 'Отклонён';
    }
  }

  bool get isFinal =>
      this == DiplomaStatus.verified || this == DiplomaStatus.rejected;
}

class VerificationStep extends Equatable {
  final String title;
  final DateTime? completedAt;
  final bool isCurrent;

  const VerificationStep({
    required this.title,
    this.completedAt,
    this.isCurrent = false,
  });

  bool get isCompleted => completedAt != null;

  @override
  List<Object?> get props => [title, completedAt, isCurrent];
}

class Diploma extends Equatable {
  final String id;
  final String title;
  final String university;
  final String speciality;
  final String diplomaNumber;
  final DateTime issueDate;
  final DiplomaStatus status;
  final double trustScore;
  final String? certificateId;
  final String? fileUrl;
  final List<VerificationStep> timeline;
  final DateTime createdAt;
  final double antifraudScore;
  final String antifraudVerdict;
  final List<String> antifraudWarnings;

  const Diploma({
    required this.id,
    required this.title,
    required this.university,
    required this.speciality,
    required this.diplomaNumber,
    required this.issueDate,
    required this.status,
    required this.trustScore,
    this.certificateId,
    this.fileUrl,
    required this.timeline,
    required this.createdAt,
    this.antifraudScore = 0.0,
    this.antifraudVerdict = '',
    this.antifraudWarnings = const [],
  });

  @override
  List<Object?> get props => [id, status, trustScore, antifraudScore];
}
