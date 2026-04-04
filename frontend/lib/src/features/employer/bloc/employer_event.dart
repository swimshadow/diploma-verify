import 'package:equatable/equatable.dart';

abstract class EmployerEvent extends Equatable {
  const EmployerEvent();
  @override
  List<Object?> get props => [];
}

class EmployerLoadRequested extends EmployerEvent {}
