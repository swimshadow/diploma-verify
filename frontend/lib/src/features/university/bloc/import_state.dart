import 'package:equatable/equatable.dart';
import '../data/models/import_model.dart';

abstract class ImportState extends Equatable {
  const ImportState();
  @override
  List<Object?> get props => [];
}

class ImportIdle extends ImportState {}

class ImportRunning extends ImportState {
  final ImportJob job;
  const ImportRunning(this.job);
  @override
  List<Object?> get props => [job];
}

class ImportCompleted extends ImportState {
  final ImportJob job;
  const ImportCompleted(this.job);
  @override
  List<Object?> get props => [job];
}

class ImportFailed extends ImportState {
  final String message;
  const ImportFailed(this.message);
  @override
  List<Object?> get props => [message];
}
