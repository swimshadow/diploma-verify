import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

/// BLoC observer that logs every event, transition, and error.
class AppBlocObserver extends BlocObserver {
  static const _tag = 'BLoC';
  final _logger = AppLogger.instance;

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.bloc(_tag, '✦ Created  ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.bloc(
      _tag,
      '⚡ Event    ${bloc.runtimeType} ← ${_shortenType(event)}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.bloc(
      _tag,
      '🔄 Transit  ${bloc.runtimeType}: '
      '${_shortenType(transition.currentState)} → ${_shortenType(transition.nextState)}',
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is! Bloc) {
      // Cubit — no transitions, only changes
      _logger.bloc(
        _tag,
        '🔄 Change   ${bloc.runtimeType}: '
        '${_shortenType(change.currentState)} → ${_shortenType(change.nextState)}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _logger.error(
      _tag,
      '💣 Error in ${bloc.runtimeType}',
      error,
      stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.bloc(_tag, '✖ Closed   ${bloc.runtimeType}');
  }

  static String _shortenType(Object? obj) {
    if (obj == null) return 'null';
    final full = obj.runtimeType.toString();
    // Remove generic parameters: AuthState<User> → AuthState
    final idx = full.indexOf('<');
    return idx > 0 ? full.substring(0, idx) : full;
  }
}
