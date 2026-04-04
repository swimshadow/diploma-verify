import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/employer_repository.dart';
import '../data/models/verification_model.dart';
import 'employer_event.dart';
import 'employer_state.dart';

class EmployerBloc extends Bloc<EmployerEvent, EmployerState> {
  final EmployerRepository _repository;

  EmployerBloc({required EmployerRepository repository})
      : _repository = repository,
        super(EmployerInitial()) {
    on<EmployerLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      EmployerLoadRequested event, Emitter<EmployerState> emit) async {
    emit(EmployerLoading());
    try {
      final rawHistory = await _repository.fetchVerificationHistory();
      final history = rawHistory.map(_mapHistoryEntry).toList();
      emit(EmployerLoaded(
        employees: const [],
        history: history,
      ));
    } catch (_) {
      emit(const EmployerLoaded(
        employees: [],
        history: [],
      ));
    }
  }

  static VerifyMethod _parseMethod(String? s) {
    switch (s) {
      case 'qr':
        return VerifyMethod.qr;
      case 'file':
      case 'file_upload':
        return VerifyMethod.fileUpload;
      default:
        return VerifyMethod.certificateId;
    }
  }

  static VerificationHistoryEntry _mapHistoryEntry(Map<String, dynamic> j) {
    return VerificationHistoryEntry(
      id: j['id']?.toString() ?? '',
      diplomaId: j['diploma_id']?.toString(),
      method: _parseMethod(j['check_method']?.toString()),
      isAuthentic: j['result'] == true,
      checkedAt:
          DateTime.tryParse(j['checked_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
