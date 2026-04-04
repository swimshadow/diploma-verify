import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/diploma_repository.dart';
import '../data/models/diploma_model.dart';
import 'diploma_event.dart';
import 'diploma_state.dart';

class DiplomaBloc extends Bloc<DiplomaEvent, DiplomaState> {
  static const _tag = 'DiplomaBloc';
  final _log = AppLogger.instance;
  final DiplomaRepository _repository;

  DiplomaBloc({required DiplomaRepository repository})
      : _repository = repository,
        super(DiplomaInitial()) {
    on<DiplomaLoadRequested>(_onLoad);
    on<DiplomaFilterChanged>(_onFilter);
    on<DiplomaUploadRequested>(_onUpload);
    _log.info(_tag, 'DiplomaBloc создан');
  }

  List<Diploma> _diplomas = [];

  Future<void> _onLoad(
      DiplomaLoadRequested event, Emitter<DiplomaState> emit) async {
    _log.info(_tag, '_onLoad → загрузка дипломов');
    emit(DiplomaLoading());
    try {
      final raw = await _repository.fetchMyDiplomas();
      _log.info(_tag, '_onLoad ← получено ${raw.length} дипломов');
      _diplomas = raw.map(_mapDiploma).toList();
    } catch (e, st) {
      _log.error(_tag, '_onLoad ОШИБКА', e, st);
      _diplomas = [];
    }
    emit(DiplomaLoaded(
      allDiplomas: _diplomas,
      filteredDiplomas: _diplomas,
    ));
  }

  void _onFilter(DiplomaFilterChanged event, Emitter<DiplomaState> emit) {
    _log.info(_tag, '_onFilter → status=${event.status}');
    final filtered = event.status == null
        ? _diplomas
        : _diplomas.where((d) => d.status == event.status).toList();
    _log.info(_tag, '_onFilter ← ${filtered.length} из ${_diplomas.length}');
    emit(DiplomaLoaded(
      allDiplomas: _diplomas,
      filteredDiplomas: filtered,
      activeFilter: event.status,
    ));
  }

  Future<void> _onUpload(
      DiplomaUploadRequested event, Emitter<DiplomaState> emit) async {
    _log.info(_tag, '_onUpload → файл=${event.fileName}, ${event.fileBytes.length} байт');
    emit(DiplomaUploadInProgress());

    try {
      await _repository.uploadDiploma(
        fileBytes: event.fileBytes,
        fileName: event.fileName,
        metadata: {},
      );
      _log.info(_tag, '_onUpload ← загрузка на сервер OK');
    } catch (e, st) {
      _log.error(_tag, '_onUpload ОШИБКА при загрузке', e, st);
    }

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

  static DiplomaStatus _parseStatus(String? s) {
    switch (s) {
      case 'verified':
        return DiplomaStatus.verified;
      case 'processing':
        return DiplomaStatus.processing;
      case 'recognized':
        return DiplomaStatus.recognized;
      case 'rejected':
        return DiplomaStatus.rejected;
      default:
        return DiplomaStatus.uploaded;
    }
  }

  static Diploma _mapDiploma(Map<String, dynamic> j) {
    return Diploma(
      id: j['id']?.toString() ?? '',
      title: (j['degree'] ?? j['specialization'] ?? 'Диплом').toString(),
      university: (j['university_name'] ?? '').toString(),
      speciality: (j['specialization'] ?? '').toString(),
      diplomaNumber: (j['diploma_number'] ?? '').toString(),
      issueDate: DateTime.tryParse(j['issue_date'] ?? '') ?? DateTime.now(),
      status: _parseStatus(j['status']?.toString()),
      trustScore: (j['trust_score'] as num?)?.toDouble() ?? 0.0,
      certificateId: j['certificate_id']?.toString(),
      fileUrl: j['file_id']?.toString(),
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      timeline: const [],
      antifraudScore: (j['antifraud_score'] as num?)?.toDouble() ?? 0.0,
      antifraudVerdict: (j['antifraud_verdict'] ?? '').toString(),
      antifraudWarnings: (j['antifraud_warnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
