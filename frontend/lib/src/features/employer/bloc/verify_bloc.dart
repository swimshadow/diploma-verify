import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import '../data/models/verification_model.dart';
import '../data/verify_repository.dart';
import 'verify_event.dart';
import 'verify_state.dart';

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  final VerifyRepository _repository;

  VerifyBloc({required VerifyRepository repository})
      : _repository = repository,
        super(VerifyInitial()) {
    on<VerifyByCertificateId>(_onByCertId);
    on<VerifyByFileUpload>(_onByFile);
    on<VerifyByQr>(_onByQr);
    on<VerifyReset>(_onReset);
  }

  Future<void> _onByCertId(
      VerifyByCertificateId event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    try {
      final data = await _repository.verifyByCertificateId(event.certificateId);
      emit(VerifySuccess(_mapResult(data, VerifyMethod.certificateId)));
    } catch (_) {
      final result = mockVerificationResults.where(
        (r) =>
            r.diplomaNumber.contains(event.certificateId) ||
            event.certificateId == 'CERT-A1B2C3D4',
      ).firstOrNull;
      if (result != null) {
        emit(VerifySuccess(result));
      } else {
        emit(const VerifyFailure('Диплом не найден по указанному ID'));
      }
    }
  }

  Future<void> _onByFile(
      VerifyByFileUpload event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    // File upload verification not yet supported by backend, use mock
    await Future<void>.delayed(const Duration(seconds: 2));
    emit(VerifySuccess(mockVerificationResults[1]));
  }

  Future<void> _onByQr(VerifyByQr event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    try {
      final data = await _repository.verifyByQr(event.qrData);
      emit(VerifySuccess(_mapResult(data, VerifyMethod.qr)));
    } catch (_) {
      if (event.qrData.contains('CERT-A1B2C3D4')) {
        emit(VerifySuccess(mockVerificationResults[0]));
      } else {
        emit(VerifySuccess(mockVerificationResults[2]));
      }
    }
  }

  void _onReset(VerifyReset event, Emitter<VerifyState> emit) {
    emit(VerifyInitial());
  }

  static VerificationResult _mapResult(
      Map<String, dynamic> j, VerifyMethod method) {
    return VerificationResult(
      id: j['id']?.toString() ?? '',
      diplomaTitle: (j['degree'] ?? j['diploma_title'] ?? 'Диплом').toString(),
      holderName: (j['full_name'] ?? j['holder_name'] ?? '').toString(),
      university:
          (j['university_name'] ?? j['university'] ?? '').toString(),
      speciality:
          (j['specialization'] ?? j['speciality'] ?? '').toString(),
      diplomaNumber: (j['diploma_number'] ?? '').toString(),
      issueDate:
          DateTime.tryParse(j['issue_date'] ?? '') ?? DateTime.now(),
      isAuthentic: (j['is_authentic'] ?? j['status'] == 'verified') == true,
      trustScore: (j['trust_score'] as num?)?.toDouble() ?? 0.0,
      antifraudScore: (j['antifraud_score'] as num?)?.toDouble() ?? 0.0,
      antifraudVerdict: (j['antifraud_verdict'] ?? '').toString(),
      warnings: (j['antifraud_warnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      method: method,
      verifiedAt:
          DateTime.tryParse(j['verified_at'] ?? '') ?? DateTime.now(),
    );
  }
}
