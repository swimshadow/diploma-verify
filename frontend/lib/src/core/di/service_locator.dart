import 'package:get_it/get_it.dart';

import '../storage/token_storage.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/student/data/diploma_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/employer/data/verify_repository.dart';
import '../../features/employer/data/employer_repository.dart';
import '../../features/university/data/university_repository.dart';
import '../../features/admin/data/admin_repository.dart';
import '../../features/certificate/data/certificate_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Storage
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());

  // Network
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(tokenStorage: getIt<TokenStorage>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dio: getIt<DioClient>().dio,
      tokenStorage: getIt<TokenStorage>(),
    ),
  );
  getIt.registerLazySingleton<DiplomaRepository>(
    () => DiplomaRepository(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<VerifyRepository>(
    () => VerifyRepository(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<EmployerRepository>(
    () => EmployerRepository(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<UniversityRepository>(
    () => UniversityRepository(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepository(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<CertificateRepository>(
    () => CertificateRepository(dio: getIt<DioClient>().dio),
  );
}
