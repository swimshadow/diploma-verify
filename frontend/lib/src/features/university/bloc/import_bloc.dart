import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/import_model.dart';
import 'import_event.dart';
import 'import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  ImportBloc() : super(ImportIdle()) {
    on<ImportStarted>(_onStarted);
  }

  Future<void> _onStarted(
      ImportStarted event, Emitter<ImportState> emit) async {
    final job = ImportJob(
      id: 'imp-new-${DateTime.now().millisecondsSinceEpoch}',
      fileName: event.fileName,
      format: ImportFormat.csv,
      status: ImportStatus.inProgress,
      totalRecords: 100,
      processedRecords: 0,
      errorsCount: 0,
      startedAt: DateTime.now(),
    );
    emit(ImportRunning(job));

    // Simulate progress
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      final updated = ImportJob(
        id: job.id,
        fileName: job.fileName,
        format: job.format,
        status: i == 10 ? ImportStatus.completed : ImportStatus.inProgress,
        totalRecords: 100,
        processedRecords: i * 10,
        errorsCount: i >= 8 ? 2 : 0,
        startedAt: job.startedAt,
        completedAt: i == 10 ? DateTime.now() : null,
      );
      if (i == 10) {
        emit(ImportCompleted(updated));
      } else {
        emit(ImportRunning(updated));
      }
    }
  }
}
