import 'package:equatable/equatable.dart';

abstract class VerifyEvent extends Equatable {
  const VerifyEvent();
  @override
  List<Object?> get props => [];
}

class VerifyByCertificateId extends VerifyEvent {
  final String certificateId;
  const VerifyByCertificateId(this.certificateId);
  @override
  List<Object?> get props => [certificateId];
}

class VerifyByFileUpload extends VerifyEvent {
  final String filePath;
  final String fileName;
  const VerifyByFileUpload({required this.filePath, required this.fileName});
  @override
  List<Object?> get props => [filePath, fileName];
}

class VerifyByQr extends VerifyEvent {
  final String qrData;
  const VerifyByQr(this.qrData);
  @override
  List<Object?> get props => [qrData];
}

class VerifyReset extends VerifyEvent {}
