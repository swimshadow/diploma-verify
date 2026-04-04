import 'package:equatable/equatable.dart';

enum ImportFormat { csv, xlsx, json, xml, zip }

extension ImportFormatX on ImportFormat {
  String get label {
    switch (this) {
      case ImportFormat.csv:
        return 'CSV';
      case ImportFormat.xlsx:
        return 'XLSX';
      case ImportFormat.json:
        return 'JSON';
      case ImportFormat.xml:
        return 'XML';
      case ImportFormat.zip:
        return 'ZIP-архив';
    }
  }
}

enum ImportStatus { pending, inProgress, completed, failed }

extension ImportStatusX on ImportStatus {
  String get label {
    switch (this) {
      case ImportStatus.pending:
        return 'Ожидание';
      case ImportStatus.inProgress:
        return 'Выполняется';
      case ImportStatus.completed:
        return 'Завершён';
      case ImportStatus.failed:
        return 'Ошибка';
    }
  }
}

class ImportJob extends Equatable {
  final String id;
  final String fileName;
  final ImportFormat format;
  final ImportStatus status;
  final int totalRecords;
  final int processedRecords;
  final int errorsCount;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ImportError> errors;

  const ImportJob({
    required this.id,
    required this.fileName,
    required this.format,
    required this.status,
    required this.totalRecords,
    required this.processedRecords,
    required this.errorsCount,
    required this.startedAt,
    this.completedAt,
    this.errors = const [],
  });

  double get progress =>
      totalRecords > 0 ? processedRecords / totalRecords : 0;

  @override
  List<Object?> get props => [id, status, processedRecords];
}

class ImportError extends Equatable {
  final int row;
  final String field;
  final String message;

  const ImportError({
    required this.row,
    required this.field,
    required this.message,
  });

  @override
  List<Object?> get props => [row, field, message];
}
