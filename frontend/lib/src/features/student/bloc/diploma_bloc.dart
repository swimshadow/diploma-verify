import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import '../data/models/diploma_model.dart';
import 'diploma_event.dart';
import 'diploma_state.dart';

class DiplomaBloc extends Bloc<DiplomaEvent, DiplomaState> {
  DiplomaBloc() : super(DiplomaInitial()) {
    on<DiplomaLoadRequested>(_onLoad);
    on<DiplomaFilterChanged>(_onFilter);
    on<DiplomaUploadRequested>(_onUpload);
  }

  List<Diploma> _diplomas = [];

  void _onLoad(DiplomaLoadRequested event, Emitter<DiplomaState> emit) {
    emit(DiplomaLoading());
    _diplomas = List.of(mockDiplomas);
    emit(DiplomaLoaded(
      allDiplomas: _diplomas,
      filteredDiplomas: _diplomas,
    ));
  }

  void _onFilter(DiplomaFilterChanged event, Emitter<DiplomaState> emit) {
    final filtered = event.status == null
        ? _diplomas
        : _diplomas.where((d) => d.status == event.status).toList();
    emit(DiplomaLoaded(
      allDiplomas: _diplomas,
      filteredDiplomas: filtered,
      activeFilter: event.status,
    ));
  }

  Future<void> _onUpload(
      DiplomaUploadRequested event, Emitter<DiplomaState> emit) async {
    emit(DiplomaUploadInProgress());

    // Mock upload delay
    await Future<void>.delayed(const Duration(seconds: 2));

    final newDiploma = Diploma(
      id: const Uuid().v4(),
      title: 'Новый диплом',
      university: 'Ожидает распознавания',
      speciality: '—',
      diplomaNumber: '—',
      issueDate: DateTime.now(),
      status: DiplomaStatus.uploaded,
      trustScore: 0.0,
      createdAt: DateTime.now(),
      timeline: [
        VerificationStep(
          title: 'Загружен',
          completedAt: DateTime.now(),
        ),
        const VerificationStep(
          title: 'В обработке',
          isCurrent: true,
        ),
        const VerificationStep(title: 'Распознавание AI'),
        const VerificationStep(title: 'Подтверждение университетом'),
      ],
    );

    _diplomas = [newDiploma, ..._diplomas];
    emit(DiplomaUploadSuccess());
    emit(DiplomaLoaded(
      allDiplomas: _diplomas,
      filteredDiplomas: _diplomas,
    ));
  }
}
