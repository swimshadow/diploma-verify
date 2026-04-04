import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import '../data/models/diploma_model.dart';

abstract class DiplomaEvent extends Equatable {
  const DiplomaEvent();
  @override
  List<Object?> get props => [];
}

class DiplomaLoadRequested extends DiplomaEvent {}

class DiplomaFilterChanged extends DiplomaEvent {
  final DiplomaStatus? status;
  const DiplomaFilterChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class DiplomaUploadRequested extends DiplomaEvent {
  final Uint8List fileBytes;
  final String fileName;
  const DiplomaUploadRequested({
    required this.fileBytes,
    required this.fileName,
  });
  @override
  List<Object?> get props => [fileName];
}
