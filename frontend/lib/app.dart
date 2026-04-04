import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'src/core/di/service_locator.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/bloc/auth_bloc.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/student/bloc/chat_bloc.dart';
import 'src/features/student/bloc/chat_event.dart';
import 'src/features/student/bloc/diploma_bloc.dart';
import 'src/features/student/bloc/diploma_event.dart';
import 'src/features/employer/bloc/employer_bloc.dart';
import 'src/features/employer/bloc/employer_event.dart';
import 'src/features/employer/bloc/verify_bloc.dart';
import 'src/features/employer/bloc/employer_chat_bloc.dart';
import 'src/features/employer/bloc/employer_chat_event.dart';

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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(repository: getIt<AuthRepository>());
    _diplomaBloc = DiplomaBloc()..add(DiplomaLoadRequested());
    _chatBloc = ChatBloc()..add(ChatLoadConversations());
    _employerBloc = EmployerBloc()..add(EmployerLoadRequested());
    _verifyBloc = VerifyBloc();
    _employerChatBloc = EmployerChatBloc()..add(EmployerChatLoadConversations());
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _diplomaBloc.close();
    _chatBloc.close();
    _employerBloc.close();
    _verifyBloc.close();
    _employerChatBloc.close();
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
      ],
      child: MaterialApp.router(
        title: 'DiplomaVerify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
