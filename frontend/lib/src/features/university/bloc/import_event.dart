import 'package:equatable/equatable.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();
  @override
  List<Object?> get props => [];
}

class ImportStarted extends ImportEvent {
  final String fileName;
  final String formatLabel;
  const ImportStarted({required this.fileName, required this.formatLabel});
  @override
  List<Object?> get props => [fileName, formatLabel];
}
