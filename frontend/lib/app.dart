import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'src/core/di/service_locator.dart';
import 'src/core/logging/log_overlay.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/bloc/auth_bloc.dart';
import 'src/features/auth/bloc/auth_state.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/student/bloc/chat_bloc.dart';
import 'src/features/student/bloc/chat_event.dart';
import 'src/features/student/bloc/diploma_bloc.dart';
import 'src/features/student/bloc/diploma_event.dart';
import 'src/features/student/data/diploma_repository.dart';
import 'src/features/employer/bloc/employer_bloc.dart';
import 'src/features/employer/bloc/employer_event.dart';
import 'src/features/employer/bloc/verify_bloc.dart';
import 'src/features/employer/bloc/employer_chat_bloc.dart';
import 'src/features/employer/bloc/employer_chat_event.dart';
import 'src/features/employer/data/verify_repository.dart';
import 'src/features/employer/data/employer_repository.dart';
import 'src/features/university/bloc/university_bloc.dart';
import 'src/features/university/bloc/university_event.dart';
import 'src/features/university/bloc/import_bloc.dart';
import 'src/features/university/data/university_repository.dart';
import 'src/features/admin/bloc/admin_bloc.dart';
import 'src/features/admin/bloc/admin_event.dart';
import 'src/features/admin/data/admin_repository.dart';
import 'src/features/notifications/bloc/notification_bloc.dart';
import 'src/features/notifications/bloc/notification_event_state.dart';
import 'src/features/notifications/data/notification_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final DiplomaBloc _diplomaBloc;
  late final ChatBloc _chatBloc;
  late final EmployerBloc _employerBloc;
  late final VerifyBloc _verifyBloc;
  late final EmployerChatBloc _employerChatBloc;
  late final UniversityBloc _universityBloc;
  late final ImportBloc _importBloc;
  late final AdminBloc _adminBloc;
  late final NotificationBloc _notificationBloc;
  late final GoRouter _router;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(repository: getIt<AuthRepository>());
    _diplomaBloc = DiplomaBloc(repository: getIt<DiplomaRepository>());
    _chatBloc = ChatBloc();
    _employerBloc = EmployerBloc(repository: getIt<EmployerRepository>());
    _verifyBloc = VerifyBloc(repository: getIt<VerifyRepository>());
    _employerChatBloc = EmployerChatBloc();
    _universityBloc =
        UniversityBloc(repository: getIt<UniversityRepository>());
    _importBloc = ImportBloc(repository: getIt<UniversityRepository>());
    _adminBloc = AdminBloc(repository: getIt<AdminRepository>());
    _notificationBloc =
        NotificationBloc(repository: getIt<NotificationRepository>());
    _router = createRouter(_authBloc);

    // Load data for all BLoCs once user is authenticated
    _authSub = _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _loadAllData();
      }
    });
  }

  void _loadAllData() {
    _diplomaBloc.add(DiplomaLoadRequested());
    _chatBloc.add(ChatLoadConversations());
    _employerBloc.add(EmployerLoadRequested());
    _employerChatBloc.add(EmployerChatLoadConversations());
    _universityBloc.add(UniversityLoadRequested());
    _adminBloc.add(AdminLoadRequested());
    _notificationBloc.add(NotificationLoadRequested());
  }

  @override
  void dispose() {
    _authSub.cancel();
    _authBloc.close();
    _diplomaBloc.close();
    _chatBloc.close();
    _employerBloc.close();
    _verifyBloc.close();
    _employerChatBloc.close();
    _universityBloc.close();
    _importBloc.close();
    _adminBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _diplomaBloc),
        BlocProvider.value(value: _chatBloc),
        BlocProvider.value(value: _employerBloc),
        BlocProvider.value(value: _verifyBloc),
        BlocProvider.value(value: _employerChatBloc),
        BlocProvider.value(value: _universityBloc),
        BlocProvider.value(value: _importBloc),
        BlocProvider.value(value: _adminBloc),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: LogOverlay(
        child: MaterialApp.router(
          title: 'DiplomaVerify',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
