import 'package:dio/dio.dart';

import 'app_logger.dart';

/// Dio interceptor that produces gorgeous HTTP logs.
///
/// Logs request → response cycle with timing, status codes,
/// headers (redacted), body previews, and errors.
class LoggingInterceptor extends Interceptor {
  static const _tag = 'HTTP';
  final _logger = AppLogger.instance;
  final _pending = <RequestOptions, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _pending[options] = DateTime.now();

    final buf = StringBuffer()
      ..writeln('──▶ ${options.method} ${options.uri}')
      ..writeln('    Headers: ${_redactHeaders(options.headers)}');

    if (options.data != null) {
      final preview = _bodyPreview(options.data);
      buf.writeln('    Body: $preview');
    }

    _logger.network(_tag, buf.toString().trimRight());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = _elapsed(response.requestOptions);
    final status = response.statusCode ?? 0;
    final emoji = status < 300
        ? '✅'
        : status < 400
            ? '↪️'
            : '⚠️';

    final buf = StringBuffer()
      ..writeln(
          '$emoji ◀── $status ${response.requestOptions.method} ${response.requestOptions.uri} [${duration}ms]')
      ..writeln('    Body: ${_bodyPreview(response.data)}');

    _logger.network(_tag, buf.toString().trimRight());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final duration = _elapsed(err.requestOptions);
    final status = err.response?.statusCode ?? 0;

    final buf = StringBuffer()
      ..writeln(
          '💥 ◀── $status ${err.requestOptions.method} ${err.requestOptions.uri} [${duration}ms]')
      ..writeln('    Type: ${err.type.name}')
      ..writeln('    Message: ${err.message ?? 'no message'}');

    if (err.response?.data != null) {
      buf.writeln('    Response: ${_bodyPreview(err.response!.data)}');
    }

    _logger.error(_tag, buf.toString().trimRight(), err);
    handler.next(err);
  }

  // ─── helpers ───────────────────────────────────────────────

  int _elapsed(RequestOptions opts) {
    final start = _pending.remove(opts);
    if (start == null) return -1;
    return DateTime.now().difference(start).inMilliseconds;
  }

  static Map<String, String> _redactHeaders(Map<String, dynamic> headers) {
    const sensitive = {'authorization', 'cookie', 'set-cookie', 'x-encrypted'};
    return headers.map((key, value) {
      if (sensitive.contains(key.toLowerCase())) {
        final s = value.toString();
        return MapEntry(key, s.length > 10 ? '${s.substring(0, 10)}***' : '***');
      }
      return MapEntry(key, value.toString());
    });
  }

  static String _bodyPreview(dynamic data, {int maxLen = 300}) {
    if (data == null) return '<empty>';
    if (data is FormData) {
      return '<FormData: ${data.fields.length} fields, ${data.files.length} files>';
    }
    final str = data.toString();
    if (str.length <= maxLen) return AppLogger.redact(str);
    return '${AppLogger.redact(str.substring(0, maxLen))}… (${str.length} chars)';
  }
}
