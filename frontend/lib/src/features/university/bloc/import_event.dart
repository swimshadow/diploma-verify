import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();
  @override
  List<Object?> get props => [];
}

class ImportStarted extends ImportEvent {
  final String fileName;
  final String formatLabel;
  final Uint8List fileBytes;
  final Map<String, dynamic>? metadata;
  const ImportStarted({
    required this.fileName,
    required this.formatLabel,
    required this.fileBytes,
    this.metadata,
  });
  @override
  List<Object?> get props => [fileName, formatLabel];
}
