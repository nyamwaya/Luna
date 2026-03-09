import 'package:logger/logger.dart';

/// Centralized application logging wrapper.
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: SimplePrinter(
      colors: false,
      printTime: false,
    ),
  );

  /// Writes an informational log message.
  static void info(String message, {Map<String, Object?>? data}) {
    _logger.i(_formatMessage(message, data));
  }

  /// Writes a warning log message.
  static void warning(String message, {Map<String, Object?>? data}) {
    _logger.w(_formatMessage(message, data));
  }

  /// Writes an error log message.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _logger.e(_formatMessage(message, data), error: error, stackTrace: stackTrace);
  }

  static String _formatMessage(String message, Map<String, Object?>? data) {
    if (data == null || data.isEmpty) {
      return message;
    }

    return '$message | data=$data';
  }
}
