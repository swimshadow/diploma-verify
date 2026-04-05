import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/api_error_handler.dart';
import '../data/models/import_model.dart';
import '../data/university_repository.dart';
import 'import_event.dart';
import 'import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final UniversityRepository _repository;

  ImportBloc({required UniversityRepository repository})
      : _repository = repository,
        super(ImportIdle()) {
    on<ImportStarted>(_onStarted);
  }

  Future<void> _onStarted(
      ImportStarted event, Emitter<ImportState> emit) async {
    final job = ImportJob(
      id: 'imp-new-${DateTime.now().millisecondsSinceEpoch}',
      fileName: event.fileName,
      format: ImportFormat.csv,
      status: ImportStatus.inProgress,
      totalRecords: 1,
      processedRecords: 0,
      errorsCount: 0,
      startedAt: DateTime.now(),
    );
    emit(ImportRunning(job));

    try {
      await _repository.uploadDiploma(
        fileBytes: event.fileBytes,
        fileName: event.fileName,
        metadata: event.metadata ?? {},
      );

      final completed = ImportJob(
        id: job.id,
        fileName: job.fileName,
        format: job.format,
        status: ImportStatus.completed,
        totalRecords: 1,
        processedRecords: 1,
        errorsCount: 0,
        startedAt: job.startedAt,
        completedAt: DateTime.now(),
      );
      emit(ImportCompleted(completed));
    } catch (e) {
      final failed = ImportJob(
        id: job.id,
        fileName: job.fileName,
        format: job.format,
        status: ImportStatus.failed,
        totalRecords: 1,
        processedRecords: 0,
        errorsCount: 1,
        startedAt: job.startedAt,
        completedAt: DateTime.now(),
      );
      emit(ImportCompleted(failed));
      emit(ImportFailed(ApiErrorHandler.message(e)));
    }
  }
}
