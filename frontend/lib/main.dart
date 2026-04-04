import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/logging/app_bloc_observer.dart';
import 'src/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  final logger = AppLogger.instance;
  logger.info('App', '🚀 DiplomaVerify starting…');

  // Global BLoC observer — logs every event, transition, error
  Bloc.observer = AppBlocObserver();

  // Catch Flutter framework errors
  FlutterError.onError = (details) {
    logger.error('Flutter', details.exceptionAsString(),
        details.exception, details.stack);
  };

  // Run inside error zone to catch uncaught async errors
  runZonedGuarded(
    () => runApp(const App()),
    (error, stack) {
      logger.error('Zone', 'Uncaught error', error, stack);
    },
  );
}
