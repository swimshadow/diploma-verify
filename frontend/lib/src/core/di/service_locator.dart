import 'package:get_it/get_it.dart';

import '../storage/token_storage.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/auth_repository.dart';

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
}
