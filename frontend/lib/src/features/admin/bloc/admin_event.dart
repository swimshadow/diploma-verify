import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class AdminLoadRequested extends AdminEvent {}

class AdminBlockUser extends AdminEvent {
  final String userId;
  const AdminBlockUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminUnblockUser extends AdminEvent {
  final String userId;
  const AdminUnblockUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminChangeUserRole extends AdminEvent {
  final String userId;
  final String newRole;
  const AdminChangeUserRole(this.userId, this.newRole);
  @override
  List<Object?> get props => [userId, newRole];
}

class AdminApproveUniversity extends AdminEvent {
  final String universityId;
  const AdminApproveUniversity(this.universityId);
  @override
  List<Object?> get props => [universityId];
}

class AdminRejectUniversity extends AdminEvent {
  final String universityId;
  final String comment;
  const AdminRejectUniversity(this.universityId, this.comment);
  @override
  List<Object?> get props => [universityId, comment];
}

class AdminVerifyDiploma extends AdminEvent {
  final String diplomaId;
  const AdminVerifyDiploma(this.diplomaId);
  @override
  List<Object?> get props => [diplomaId];
}

class AdminRejectDiploma extends AdminEvent {
  final String diplomaId;
  const AdminRejectDiploma(this.diplomaId);
  @override
  List<Object?> get props => [diplomaId];
}

class AdminRetryDiploma extends AdminEvent {
  final String diplomaId;
  const AdminRetryDiploma(this.diplomaId);
  @override
  List<Object?> get props => [diplomaId];
}
