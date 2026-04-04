import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import 'verify_event.dart';
import 'verify_state.dart';

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  VerifyBloc() : super(VerifyInitial()) {
    on<VerifyByCertificateId>(_onByCertId);
    on<VerifyByFileUpload>(_onByFile);
    on<VerifyByQr>(_onByQr);
    on<VerifyReset>(_onReset);
  }

  Future<void> _onByCertId(
      VerifyByCertificateId event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    await Future<void>.delayed(const Duration(seconds: 2));

    final result = mockVerificationResults.where(
      (r) => r.diplomaNumber.contains(event.certificateId) ||
          event.certificateId == 'CERT-A1B2C3D4',
    ).firstOrNull;

    if (result != null) {
      emit(VerifySuccess(result));
    } else {
      emit(const VerifyFailure('Диплом не найден по указанному ID'));
    }
  }

  Future<void> _onByFile(
      VerifyByFileUpload event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    await Future<void>.delayed(const Duration(seconds: 3));
    // Mock: always return first result for file upload
    emit(VerifySuccess(mockVerificationResults[1]));
  }

  Future<void> _onByQr(VerifyByQr event, Emitter<VerifyState> emit) async {
    emit(VerifyLoading());
    await Future<void>.delayed(const Duration(seconds: 1));

    if (event.qrData.contains('CERT-A1B2C3D4')) {
      emit(VerifySuccess(mockVerificationResults[0]));
    } else {
      emit(VerifySuccess(mockVerificationResults[2]));
    }
  }

  void _onReset(VerifyReset event, Emitter<VerifyState> emit) {
    emit(VerifyInitial());
  }
}
