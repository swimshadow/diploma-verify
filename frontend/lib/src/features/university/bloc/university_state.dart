import 'package:equatable/equatable.dart';
import '../data/models/registry_diploma_model.dart';
import '../data/models/certificate_model.dart';
import '../data/models/import_model.dart';

abstract class UniversityState extends Equatable {
  const UniversityState();
  @override
  List<Object?> get props => [];
}

class UniversityInitial extends UniversityState {}

class UniversityLoading extends UniversityState {}

class UniversityLoaded extends UniversityState {
  final List<RegistryDiploma> diplomas;
  final List<UniversityCertificate> certificates;
  final List<ImportJob> importJobs;

  const UniversityLoaded({
    required this.diplomas,
    required this.certificates,
    required this.importJobs,
  });

  int get totalDiplomas => diplomas.length;
  int get activeDiplomas =>
      diplomas.where((d) => d.status == RegistryDiplomaStatus.active).length;
  int get revokedDiplomas =>
      diplomas.where((d) => d.status == RegistryDiplomaStatus.revoked).length;
  int get pendingDiplomas =>
      diplomas.where((d) => d.status == RegistryDiplomaStatus.pendingReview).length;
  int get activeCertificates =>
      certificates.where((c) => c.status == CertificateStatus.active).length;
  int get totalImportErrors =>
      importJobs.fold<int>(0, (sum, j) => sum + j.errorsCount);

  @override
  List<Object?> get props => [diplomas, certificates, importJobs];
}

class UniversityFailure extends UniversityState {
  final String message;
  const UniversityFailure(this.message);
  @override
  List<Object?> get props => [message];
}
