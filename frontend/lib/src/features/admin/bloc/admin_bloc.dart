import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import '../data/models/admin_models.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(AdminInitial()) {
    on<AdminLoadRequested>(_onLoad);
    on<AdminBlockUser>(_onBlock);
    on<AdminUnblockUser>(_onUnblock);
    on<AdminChangeUserRole>(_onChangeRole);
    on<AdminApproveUniversity>(_onApproveUni);
    on<AdminRejectUniversity>(_onRejectUni);
    on<AdminVerifyDiploma>(_onVerifyDiploma);
    on<AdminRejectDiploma>(_onRejectDiploma);
    on<AdminRetryDiploma>(_onRetryDiploma);
  }

  void _onLoad(AdminLoadRequested event, Emitter<AdminState> emit) {
    emit(AdminLoading());
    emit(AdminLoaded(
      users: mockPlatformUsers,
      universities: mockModerationUniversities,
      diplomas: mockAdminDiplomas,
      services: mockServiceHealth,
      logs: mockAuditLogs,
    ));
  }

  AdminLoaded? get _loaded {
    final s = state;
    return s is AdminLoaded ? s : null;
  }

  void _onBlock(AdminBlockUser event, Emitter<AdminState> emit) {
    final current = _loaded;
    if (current == null) return;
    emit(AdminLoaded(
      users: current.users.map((u) {
        if (u.id == event.userId) {
          return PlatformUser(
            id: u.id, email: u.email, fullName: u.fullName,
            role: u.role, isBlocked: true,
            createdAt: u.createdAt, lastLoginAt: u.lastLoginAt,
          );
        }
        return u;
      }).toList(),
      universities: current.universities,
      diplomas: current.diplomas,
      services: current.services,
      logs: current.logs,
    ));
  }

  void _onUnblock(AdminUnblockUser event, Emitter<AdminState> emit) {
    final current = _loaded;
    if (current == null) return;
    emit(AdminLoaded(
      users: current.users.map((u) {
        if (u.id == event.userId) {
          return PlatformUser(
            id: u.id, email: u.email, fullName: u.fullName,
            role: u.role, isBlocked: false,
            createdAt: u.createdAt, lastLoginAt: u.lastLoginAt,
          );
        }
        return u;
      }).toList(),
      universities: current.universities,
      diplomas: current.diplomas,
      services: current.services,
      logs: current.logs,
    ));
  }

  void _onChangeRole(AdminChangeUserRole event, Emitter<AdminState> emit) {
    final current = _loaded;
    if (current == null) return;
    emit(AdminLoaded(
      users: current.users.map((u) {
        if (u.id == event.userId) {
          return PlatformUser(
            id: u.id, email: u.email, fullName: u.fullName,
            role: event.newRole, isBlocked: u.isBlocked,
            createdAt: u.createdAt, lastLoginAt: u.lastLoginAt,
          );
        }
        return u;
      }).toList(),
      universities: current.universities,
      diplomas: current.diplomas,
      services: current.services,
      logs: current.logs,
    ));
  }

  void _onApproveUni(AdminApproveUniversity event, Emitter<AdminState> emit) {
    final current = _loaded;
    if (current == null) return;
    emit(AdminLoaded(
      users: current.users,
      universities: current.universities.map((u) {
        if (u.id == event.universityId) {
          return ModerationUniversity(
            id: u.id, name: u.name, city: u.city,
            contactEmail: u.contactEmail,
            status: ModerationStatus.approved,
            appliedAt: u.appliedAt,
          );
        }
        return u;
      }).toList(),
      diplomas: current.diplomas,
      services: current.services,
      logs: current.logs,
    ));
  }

  void _onRejectUni(AdminRejectUniversity event, Emitter<AdminState> emit) {
    final current = _loaded;
    if (current == null) return;
    emit(AdminLoaded(
      users: current.users,
      universities: current.universities.map((u) {
        if (u.id == event.universityId) {
          return ModerationUniversity(
            id: u.id, name: u.name, city: u.city,
            contactEmail: u.contactEmail,
            status: ModerationStatus.rejected,
            moderatorComment: event.comment,
            appliedAt: u.appliedAt,
          );
        }
        return u;
      }).toList(),
      diplomas: current.diplomas,
      services: current.services,
      logs: current.logs,
    ));
  }

  void _onVerifyDiploma(AdminVerifyDiploma event, Emitter<AdminState> emit) {
    _updateDiplomaStatus(event.diplomaId, AdminDiplomaStatus.verified, emit);
  }

  void _onRejectDiploma(AdminRejectDiploma event, Emitter<AdminState> emit) {
    _updateDiplomaStatus(event.diplomaId, AdminDiplomaStatus.rejected, emit);
  }

  void _onRetryDiploma(AdminRetryDiploma event, Emitter<AdminState> emit) {
    _updateDiplomaStatus(event.diplomaId, AdminDiplomaStatus.pendingReview, emit);
  }

  void _updateDiplomaStatus(
      String id, AdminDiplomaStatus status, Emitter<AdminState> emit) {
    final current = _loaded;
    if (current == null) return;
    emit(AdminLoaded(
      users: current.users,
      universities: current.universities,
      diplomas: current.diplomas.map((d) {
        if (d.id == id) {
          return AdminDiploma(
            id: d.id, holderName: d.holderName,
            universityName: d.universityName,
            diplomaNumber: d.diplomaNumber,
            status: status, trustScore: d.trustScore,
            ocrText: d.ocrText, fileUrl: d.fileUrl,
            uploadedAt: d.uploadedAt,
          );
        }
        return d;
      }).toList(),
      services: current.services,
      logs: current.logs,
    ));
  }
}
