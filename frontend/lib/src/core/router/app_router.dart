import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';
import '../../features/dashboard/presentation/screens/employer_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/university_dashboard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/student/presentation/screens/certificate_screen.dart';
import '../../features/student/presentation/screens/chat_conversation_screen.dart';
import '../../features/student/presentation/screens/chat_list_screen.dart';
import '../../features/student/presentation/screens/diploma_detail_screen.dart';
import '../../features/student/presentation/screens/diploma_list_screen.dart';
import '../../features/student/presentation/screens/diploma_upload_screen.dart';
import '../../features/student/presentation/screens/student_profile_screen.dart';
import '../../features/employer/presentation/screens/verify_diploma_screen.dart';
import '../../features/employer/presentation/screens/verify_result_screen.dart';
import '../../features/employer/presentation/screens/employee_list_screen.dart';
import '../../features/employer/presentation/screens/employee_card_screen.dart';
import '../../features/employer/presentation/screens/verification_history_screen.dart';
import '../../features/employer/presentation/screens/employer_chat_list_screen.dart';
import '../../features/employer/presentation/screens/employer_chat_conversation_screen.dart';
import '../../features/employer/presentation/screens/api_integration_screen.dart';
import '../../features/employer/presentation/screens/employer_profile_screen.dart';
import 'route_names.dart';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _GoRouterAuthRefresh(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/role-select' ||
          state.matchedLocation == '/forgot-password';
      final isOnPublic = state.matchedLocation == '/' ||
          state.matchedLocation == '/splash' ||
          isOnAuth;

      if (authState is AuthLoading || authState is AuthInitial) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      if (authState is AuthAuthenticated) {
        if (isOnPublic) return '/dashboard';
        return null;
      }

      // Unauthenticated
      if (!isOnPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/role-select',
        name: RouteNames.roleSelect,
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (_, state) {
          final role = state.uri.queryParameters['role'] ?? 'student';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: RouteNames.dashboard,
        builder: (context, _) {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            switch (authState.user.role) {
              case 'university':
                return const UniversityDashboardScreen();
              case 'student':
                return const StudentDashboardScreen();
              case 'employer':
                return const EmployerDashboardScreen();
            }
          }
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      // Student routes
      GoRoute(
        path: '/student/diplomas',
        name: RouteNames.studentDiplomas,
        builder: (_, _) => const DiplomaListScreen(),
      ),
      GoRoute(
        path: '/student/diploma/:id',
        name: RouteNames.studentDiplomaDetail,
        builder: (_, state) =>
            DiplomaDetailScreen(diplomaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/student/upload',
        name: RouteNames.studentUpload,
        builder: (_, _) => const DiplomaUploadScreen(),
      ),
      GoRoute(
        path: '/student/certificate/:certId',
        name: RouteNames.studentCertificate,
        builder: (_, state) =>
            CertificateScreen(certificateId: state.pathParameters['certId']!),
      ),
      GoRoute(
        path: '/student/chats',
        name: RouteNames.studentChats,
        builder: (_, _) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/student/chat/:chatId',
        name: RouteNames.studentChatConversation,
        builder: (_, state) => ChatConversationScreen(
            conversationId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: '/student/profile',
        name: RouteNames.studentProfile,
        builder: (_, _) => const StudentProfileScreen(),
      ),
      // Employer routes
      GoRoute(
        path: '/employer/verify',
        name: RouteNames.employerVerify,
        builder: (_, _) => const VerifyDiplomaScreen(),
      ),
      GoRoute(
        path: '/employer/verify-result/:resultId',
        name: RouteNames.employerVerifyResult,
        builder: (_, state) =>
            VerifyResultScreen(resultId: state.pathParameters['resultId']!),
      ),
      GoRoute(
        path: '/employer/employees',
        name: RouteNames.employerEmployees,
        builder: (_, _) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/employer/employee/:id',
        name: RouteNames.employerEmployeeCard,
        builder: (_, state) =>
            EmployeeCardScreen(employeeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/employer/history',
        name: RouteNames.employerHistory,
        builder: (_, _) => const VerificationHistoryScreen(),
      ),
      GoRoute(
        path: '/employer/chats',
        name: RouteNames.employerChats,
        builder: (_, _) => const EmployerChatListScreen(),
      ),
      GoRoute(
        path: '/employer/chat/:chatId',
        name: RouteNames.employerChatConversation,
        builder: (_, state) => EmployerChatConversationScreen(
            conversationId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: '/employer/api',
        name: RouteNames.employerApi,
        builder: (_, _) => const ApiIntegrationScreen(),
      ),
      GoRoute(
        path: '/employer/profile',
        name: RouteNames.employerProfile,
        builder: (_, _) => const EmployerProfileScreen(),
      ),
    ],
  );
}

class _GoRouterAuthRefresh extends ChangeNotifier {
  _GoRouterAuthRefresh(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}
