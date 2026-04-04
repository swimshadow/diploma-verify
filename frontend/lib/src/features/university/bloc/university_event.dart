import 'package:equatable/equatable.dart';

abstract class UniversityEvent extends Equatable {
  const UniversityEvent();
  @override
  List<Object?> get props => [];
}

class UniversityLoadRequested extends UniversityEvent {}

class UniversityRevokeDiploma extends UniversityEvent {
  final String diplomaId;
  const UniversityRevokeDiploma(this.diplomaId);
  @override
  List<Object?> get props => [diplomaId];
}

class UniversityReissueCertificate extends UniversityEvent {
  final String certificateId;
  const UniversityReissueCertificate(this.certificateId);
  @override
  List<Object?> get props => [certificateId];
}
