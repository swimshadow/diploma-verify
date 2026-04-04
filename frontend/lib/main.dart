import 'package:flutter/material.dart';

import 'app.dart';
import 'src/core/di/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const App());
}
