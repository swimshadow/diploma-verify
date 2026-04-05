import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/crypto/ecp_service.dart';
import '../../../core/utils/api_error_handler.dart';
import '../data/admin_repository.dart';
import '../data/models/admin_models.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({required AdminRepository repository})
      : _repository = repository,
        super(AdminInitial()) {
    on<AdminLoadRequested>(_onLoad);
    on<AdminBlockUser>(_onBlock);
    on<AdminUnblockUser>(_onUnblock);
    on<AdminChangeUserRole>(_onChangeRole);
    on<AdminApproveUniversity>(_onApproveUni);
    on<AdminApproveUniversityWithEcp>(_onApproveUniEcp);
    on<AdminRejectUniversity>(_onRejectUni);
    on<AdminVerifyDiploma>(_onVerifyDiploma);
    on<AdminRejectDiploma>(_onRejectDiploma);
    on<AdminRetryDiploma>(_onRetryDiploma);
  }

  Future<void> _onLoad(
      AdminLoadRequested event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final rawAccounts = await _repository.fetchAccounts();
      final rawDiplomas = await _repository.fetchDiplomas();
      final rawLogs = await _repository.fetchAuditLogs();

      final users = rawAccounts.map(_mapUser).toList();
      final universities = users
          .where((u) => u.role == 'university')
          .map((u) => ModerationUniversity(
                id: u.id,
                name: u.fullName,
                city: '',
                contactEmail: u.email,
                status: u.isBlocked
                    ? ModerationStatus.rejected
                    : u.isVerified
                        ? ModerationStatus.approved
                        : ModerationStatus.pending,
                appliedAt: u.createdAt,
              ))
          .toList();
      final diplomas = rawDiplomas.map(_mapDiploma).toList();
      final logs = rawLogs.map(_mapLog).toList();

      emit(AdminLoaded(
        users: users,
        universities: universities,
        diplomas: diplomas,
        services: const [],
        logs: logs,
      ));
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.message(e)));
    }
  }

  AdminLoaded? get _loaded {
    final s = state;
    return s is AdminLoaded ? s : null;
  }

  Future<void> _onBlock(
      AdminBlockUser event, Emitter<AdminState> emit) async {
    final current = _loaded;
    if (current == null) return;
    try {
      await _repository.blockUser(event.userId);
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.message(e)));
      return;
    }
    emit(AdminLoaded(
      users: current.users.map((u) {
        if (u.id == event.userId) {
          return PlatformUser(
            id: u.id, email: u.email, fullName: u.fullName,
            role: u.role, isBlocked: true, isVerified: u.isVerified,
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

  Future<void> _onUnblock(
      AdminUnblockUser event, Emitter<AdminState> emit) async {
    final current = _loaded;
    if (current == null) return;
    try {
      await _repository.unblockUser(event.userId);
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.message(e)));
      return;
    }
    emit(AdminLoaded(
      users: current.users.map((u) {
        if (u.id == event.userId) {
          return PlatformUser(
            id: u.id, email: u.email, fullName: u.fullName,
            role: u.role, isBlocked: false, isVerified: u.isVerified,
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
            role: event.newRole, isBlocked: u.isBlocked, isVerified: u.isVerified,
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

  Future<void> _onApproveUni(AdminApproveUniversity event, Emitter<AdminState> emit) async {
    final current = _loaded;
    if (current == null) return;
    try {
      await _repository.verifyUniversity(event.universityId);
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.message(e)));
      return;
    }
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

  Future<void> _onApproveUniEcp(AdminApproveUniversityWithEcp event, Emitter<AdminState> emit) async {
    final current = _loaded;
    if (current == null) return;
    try {
      final ecpService = EcpService();
      final privateKey = ecpService.parsePrivateKeyPem(event.privateKeyPem);
      final publicKey = ecpService.extractPublicKey(privateKey);
      final publicKeyPem = ecpService.publicKeyToPem(publicKey);
      final payload = ecpService.buildApprovalPayload(event.universityId);
      final signature = ecpService.sign(payload, privateKey);

      await _repository.verifyUniversityWithEcp(
        accountId: event.universityId,
        payload: payload,
        signature: signature,
        publicKeyPem: publicKeyPem,
      );
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.message(e)));
      return;
    }
    emit(AdminLoaded(
      users: current.users,
      universities: current.universities.map((u) {
        if (u.id == event.universityId) {
          return ModerationUniversity(
            id: u.id, name: u.name, city: u.city,
            contactEmail: u.contactEmail,
            status: ModerationStatus.approved,
            ecpVerified: true,
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

  Future<void> _onRejectUni(AdminRejectUniversity event, Emitter<AdminState> emit) async {
    final current = _loaded;
    if (current == null) return;
    try {
      await _repository.unverifyUniversity(event.universityId);
    } catch (e) {
      emit(AdminFailure(ApiErrorHandler.message(e)));
      return;
    }
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
    _updateDiplomaStatus(event.diplomaId, AdminDiplomaStatus.verified, emit,
        apiCall: () =>
            _repository.forceVerifyDiploma(event.diplomaId, 'Admin verified'));
  }

  void _onRejectDiploma(AdminRejectDiploma event, Emitter<AdminState> emit) {
    _updateDiplomaStatus(event.diplomaId, AdminDiplomaStatus.rejected, emit,
        apiCall: () =>
            _repository.forceRevokeDiploma(event.diplomaId, 'Admin rejected'));
  }

  void _onRetryDiploma(AdminRetryDiploma event, Emitter<AdminState> emit) {
    _updateDiplomaStatus(
        event.diplomaId, AdminDiplomaStatus.pendingReview, emit);
  }

  void _updateDiplomaStatus(
      String id, AdminDiplomaStatus status, Emitter<AdminState> emit,
      {Future<void> Function()? apiCall}) {
    final current = _loaded;
    if (current == null) return;
    apiCall?.call(); // fire-and-forget
    emit(AdminLoaded(
      users: current.users,
      universities: current.universities,
      diplomas: current.diplomas.map((d) {
        if (d.id == id) {
          return AdminDiploma(
            id: d.id,
            holderName: d.holderName,
            universityName: d.universityName,
            diplomaNumber: d.diplomaNumber,
            status: status,
            trustScore: d.trustScore,
            ocrText: d.ocrText,
            fileUrl: d.fileUrl,
            uploadedAt: d.uploadedAt,
          );
        }
        return d;
      }).toList(),
      services: current.services,
      logs: current.logs,
    ));
  }

  // ── Mappers ──

  static PlatformUser _mapUser(Map<String, dynamic> j) {
    final profile = j['profile'] as Map<String, dynamic>? ?? {};
    final fullName = (profile['full_name'] ?? profile['name'] ?? profile['company_name'] ?? j['email'] ?? '').toString();
    return PlatformUser(
      id: j['id']?.toString() ?? '',
      email: (j['email'] ?? '').toString(),
      fullName: fullName,
      role: (j['role'] ?? 'student').toString(),
      isBlocked: j['is_blocked'] == true,
      isVerified: j['is_verified'] == true,
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      lastLoginAt: DateTime.tryParse(j['last_login_at']?.toString() ?? ''),
    );
  }

  static AdminDiplomaStatus _parseDiplomaStatus(String? s) {
    switch (s) {
      case 'verified':
        return AdminDiplomaStatus.verified;
      case 'rejected':
      case 'revoked':
        return AdminDiplomaStatus.rejected;
      case 'disputed':
        return AdminDiplomaStatus.disputed;
      default:
        return AdminDiplomaStatus.pendingReview;
    }
  }

  static AdminDiploma _mapDiploma(Map<String, dynamic> j) {
    return AdminDiploma(
      id: j['id']?.toString() ?? '',
      holderName: (j['full_name'] ?? j['holder_name'] ?? '').toString(),
      universityName:
          (j['university_name'] ?? j['university'] ?? '').toString(),
      diplomaNumber: (j['diploma_number'] ?? '').toString(),
      status: _parseDiplomaStatus(j['status']?.toString()),
      trustScore: (j['trust_score'] as num?)?.toDouble() ?? 0.0,
      ocrText: j['ocr_text']?.toString(),
      fileUrl: j['file_url']?.toString(),
      uploadedAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static LogAction _parseAction(String? s) {
    switch (s) {
      case 'login':
        return LogAction.login;
      case 'logout':
        return LogAction.logout;
      case 'role_change':
        return LogAction.roleChange;
      case 'status_change':
        return LogAction.statusChange;
      case 'block':
        return LogAction.block;
      case 'unblock':
        return LogAction.unblock;
      case 'diploma_review':
      case 'DIPLOMA_FORCE_VERIFIED':
      case 'DIPLOMA_FORCE_REVOKED':
        return LogAction.diplomaReview;
      case 'moderation_decision':
      case 'moderation':
        return LogAction.moderationDecision;
      default:
        return LogAction.statusChange;
    }
  }

  static AuditLog _mapLog(Map<String, dynamic> j) {
    return AuditLog(
      id: j['id']?.toString() ?? '',
      action: _parseAction(j['action']?.toString()),
      actorEmail: (j['actor_id'] ?? j['actor_email'] ?? '').toString(),
      targetDescription:
          (j['resource_type'] ?? j['target'] ?? '').toString(),
      timestamp:
          DateTime.tryParse(j['timestamp']?.toString() ?? j['created_at']?.toString() ?? '') ??
              DateTime.now(),
      details: j['new_value']?.toString(),
    );
  }
}
