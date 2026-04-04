import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/registry_diploma_model.dart';
import '../data/models/certificate_model.dart';
import '../data/university_repository.dart';
import 'university_event.dart';
import 'university_state.dart';

class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  final UniversityRepository _repository;

  UniversityBloc({required UniversityRepository repository})
      : _repository = repository,
        super(UniversityInitial()) {
    on<UniversityLoadRequested>(_onLoad);
    on<UniversityRevokeDiploma>(_onRevoke);
    on<UniversityReissueCertificate>(_onReissue);
  }

  Future<void> _onLoad(
      UniversityLoadRequested event, Emitter<UniversityState> emit) async {
    emit(UniversityLoading());
    try {
      final raw = await _repository.fetchDiplomas();
      final diplomas = raw.map(_mapDiploma).toList();
      emit(UniversityLoaded(
        diplomas: diplomas,
        certificates: const [],
        importJobs: const [],
      ));
    } catch (_) {
      emit(const UniversityLoaded(
        diplomas: [],
        certificates: [],
        importJobs: [],
      ));
    }
  }

  Future<void> _onRevoke(
      UniversityRevokeDiploma event, Emitter<UniversityState> emit) async {
    final current = state;
    if (current is! UniversityLoaded) return;

    try {
      await _repository.revokeDiploma(event.diplomaId);
    } catch (_) {
      // continue with local update
    }

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

  static RegistryDiplomaStatus _parseStatus(String? s) {
    switch (s) {
      case 'active':
      case 'verified':
        return RegistryDiplomaStatus.active;
      case 'revoked':
        return RegistryDiplomaStatus.revoked;
      default:
        return RegistryDiplomaStatus.pendingReview;
    }
  }

  static RegistryDiploma _mapDiploma(Map<String, dynamic> j) {
    return RegistryDiploma(
      id: j['id']?.toString() ?? '',
      holderFullName: (j['full_name'] ?? j['holder_full_name'] ?? '').toString(),
      faculty: (j['faculty'] ?? '').toString(),
      speciality: (j['specialization'] ?? j['speciality'] ?? '').toString(),
      educationLevel: (j['degree'] ?? j['education_level'] ?? '').toString(),
      diplomaSeries: (j['series'] ?? j['diploma_series'] ?? '').toString(),
      diplomaNumber: (j['diploma_number'] ?? '').toString(),
      issueDate: DateTime.tryParse(j['issue_date'] ?? '') ?? DateTime.now(),
      gpa: (j['gpa'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(j['status']?.toString()),
      certificateId: j['certificate_id']?.toString(),
      trustScore: (j['trust_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      antifraudScore: (j['antifraud_score'] as num?)?.toDouble() ?? 0.0,
      antifraudVerdict: (j['antifraud_verdict'] ?? '').toString(),
      antifraudWarnings: (j['antifraud_warnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
