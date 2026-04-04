import 'package:flutter_bloc/flutter_bloc.dart';

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
      emit(const VerifyFailure('Диплом не найден по указанному ID'));
    }
  }

  Future<void> _onByFile(
      VerifyByFileUpload event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    try {
      final data = await _repository.verifyManually(
        diplomaNumber: event.fileName,
        series: '',
        fullName: '',
        issueDate: '',
      );
      emit(VerifySuccess(_mapResult(data, VerifyMethod.fileUpload)));
    } catch (_) {
      emit(const VerifyFailure('Не удалось проверить файл'));
    }
  }

  Future<void> _onByQr(VerifyByQr event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    try {
      final data = await _repository.verifyByQr(event.qrData);
      emit(VerifySuccess(_mapResult(data, VerifyMethod.qr)));
    } catch (_) {
      emit(const VerifyFailure('QR-код не распознан'));
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
          DateTime.tryParse(j['issue_date']?.toString() ?? '') ?? DateTime.now(),
      isAuthentic: j['valid'] == true,
      signatureVerified: j['signature_verified'] == true,
      blockchainVerified: j['blockchain_verified'] == true,
      blockchainBlock: (j['blockchain_block'] as num?)?.toInt(),
      chainIntact: j['chain_intact'] == true,
      timestampProof: j['timestamp_proof']?.toString(),
      reason: j['reason']?.toString(),
      method: method,
      verifiedAt: DateTime.now(),
    );
  }
}
