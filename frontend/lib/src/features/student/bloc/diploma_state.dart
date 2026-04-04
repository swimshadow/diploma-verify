import 'package:equatable/equatable.dart';
import '../data/models/diploma_model.dart';

abstract class DiplomaState extends Equatable {
  const DiplomaState();
  @override
  List<Object?> get props => [];
}

class DiplomaInitial extends DiplomaState {}

class DiplomaLoading extends DiplomaState {}

class DiplomaLoaded extends DiplomaState {
  final List<Diploma> allDiplomas;
  final List<Diploma> filteredDiplomas;
  final DiplomaStatus? activeFilter;

  const DiplomaLoaded({
    required this.allDiplomas,
    required this.filteredDiplomas,
    this.activeFilter,
  });

  int get totalCount => allDiplomas.length;
  int get verifiedCount =>
      allDiplomas.where((d) => d.status == DiplomaStatus.verified).length;
  int get processingCount =>
      allDiplomas.where((d) => d.status == DiplomaStatus.processing).length;
  int get rejectedCount =>
      allDiplomas.where((d) => d.status == DiplomaStatus.rejected).length;

  @override
  List<Object?> get props => [allDiplomas, filteredDiplomas, activeFilter];
}

class DiplomaUploadInProgress extends DiplomaState {}

class DiplomaUploadSuccess extends DiplomaState {}

class DiplomaFailure extends DiplomaState {
  final String message;
  const DiplomaFailure(this.message);
  @override
  List<Object?> get props => [message];
}
