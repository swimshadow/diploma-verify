import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import '../data/models/registry_diploma_model.dart';
import '../data/models/certificate_model.dart';
import 'university_event.dart';
import 'university_state.dart';

class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  UniversityBloc() : super(UniversityInitial()) {
    on<UniversityLoadRequested>(_onLoad);
    on<UniversityRevokeDiploma>(_onRevoke);
    on<UniversityReissueCertificate>(_onReissue);
  }

  void _onLoad(UniversityLoadRequested event, Emitter<UniversityState> emit) {
    emit(UniversityLoading());
    emit(UniversityLoaded(
      diplomas: mockRegistryDiplomas,
      certificates: mockCertificates,
      importJobs: mockImportJobs,
    ));
  }

  void _onRevoke(
      UniversityRevokeDiploma event, Emitter<UniversityState> emit) {
    final current = state;
    if (current is! UniversityLoaded) return;

    final updated = current.diplomas.map((d) {
      if (d.id == event.diplomaId) {
        return RegistryDiploma(
          id: d.id,
          holderFullName: d.holderFullName,
          faculty: d.faculty,
          speciality: d.speciality,
          educationLevel: d.educationLevel,
          diplomaSeries: d.diplomaSeries,
          diplomaNumber: d.diplomaNumber,
          issueDate: d.issueDate,
          gpa: d.gpa,
          status: RegistryDiplomaStatus.revoked,
          certificateId: d.certificateId,
          trustScore: 0,
          createdAt: d.createdAt,
          employerChecks: d.employerChecks,
        );
      }
      return d;
    }).toList();

    emit(UniversityLoaded(
      diplomas: updated,
      certificates: current.certificates,
      importJobs: current.importJobs,
    ));
  }

  void _onReissue(
      UniversityReissueCertificate event, Emitter<UniversityState> emit) {
    final current = state;
    if (current is! UniversityLoaded) return;

    final updated = current.certificates.map((c) {
      if (c.id == event.certificateId) {
        return UniversityCertificate(
          id: c.id,
          diplomaId: c.diplomaId,
          holderFullName: c.holderFullName,
          diplomaNumber: c.diplomaNumber,
          status: CertificateStatus.reissued,
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 365)),
          checksCount: 0,
        );
      }
      return c;
    }).toList();

    emit(UniversityLoaded(
      diplomas: current.diplomas,
      certificates: updated,
      importJobs: current.importJobs,
    ));
  }
}
