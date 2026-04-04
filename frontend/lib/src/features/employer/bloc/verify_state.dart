import 'package:equatable/equatable.dart';
import '../data/models/verification_model.dart';

abstract class VerifyState extends Equatable {
  const VerifyState();
  @override
  List<Object?> get props => [];
}

class VerifyInitial extends VerifyState {}

class VerifyLoading extends VerifyState {}

class VerifySuccess extends VerifyState {
  final VerificationResult result;
  const VerifySuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class VerifyFailure extends VerifyState {
  final String message;
  const VerifyFailure(this.message);
  @override
  List<Object?> get props => [message];
}
