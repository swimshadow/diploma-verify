import 'package:get_it/get_it.dart';

import '../logging/app_logger.dart';
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
  final log = AppLogger.instance;
  log.info('ServiceLocator', 'setupServiceLocator() → начало регистрации');

  // Storage
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());
  log.info('ServiceLocator', 'Зарегистрирован: TokenStorage');

  // Network
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(tokenStorage: getIt<TokenStorage>()),
  );
  log.info('ServiceLocator', 'Зарегистрирован: DioClient');

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dio: getIt<DioClient>().dio,
      tokenStorage: getIt<TokenStorage>(),
    ),
  );
  log.info('ServiceLocator', 'Зарегистрирован: AuthRepository');

  getIt.registerLazySingleton<DiplomaRepository>(
    () => DiplomaRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: DiplomaRepository');

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: NotificationRepository');

  getIt.registerLazySingleton<VerifyRepository>(
    () => VerifyRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: VerifyRepository');

  getIt.registerLazySingleton<EmployerRepository>(
    () => EmployerRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: EmployerRepository');

  getIt.registerLazySingleton<UniversityRepository>(
    () => UniversityRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: UniversityRepository');

  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: AdminRepository');

  getIt.registerLazySingleton<CertificateRepository>(
    () => CertificateRepository(dio: getIt<DioClient>().dio),
  );
  log.info('ServiceLocator', 'Зарегистрирован: CertificateRepository');

  log.info('ServiceLocator', 'setupServiceLocator() ← завершено, ${getIt.allReadySync() ? "все готово" : "lazy init"}');
}
