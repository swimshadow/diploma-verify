import 'package:flutter/material.dart';

import 'app_logger.dart';

/// Navigator observer that logs push/pop/replace navigation events.
class LoggingNavigatorObserver extends NavigatorObserver {
  static const _tag = 'Router';
  final _logger = AppLogger.instance;

  @override
  void didPush(Route route, Route? previousRoute) {
    _logger.navigation(
      _tag,
      '→ Push  ${_routeName(route)}'
      '${previousRoute != null ? '  (from ${_routeName(previousRoute)})' : ''}',
    );
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _logger.navigation(
      _tag,
      '← Pop   ${_routeName(route)}'
      '${previousRoute != null ? '  (back to ${_routeName(previousRoute)})' : ''}',
    );
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _logger.navigation(
      _tag,
      '⇄ Replace  ${_routeName(oldRoute)} → ${_routeName(newRoute)}',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _logger.navigation(
      _tag,
      '✖ Remove  ${_routeName(route)}',
    );
  }

  static String _routeName(Route? route) {
    if (route == null) return '?';
    return route.settings.name ?? route.runtimeType.toString();
  }
}
