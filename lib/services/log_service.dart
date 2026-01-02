import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Centralized logging service for the application
///
/// Writes logs to a file in the user data directory for debugging purposes.
/// Also prints to console in debug mode.
class LogService {
  static LogService? _instance;
  static LogService get instance => _instance ??= LogService._();

  LogService._();

  File? _logFile;
  final List<String> _buffer = [];
  bool _isInitialized = false;

  /// Initialize the logging service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/MyLife/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Create log file with date
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/mylife_$date.log');

      // Write startup header
      await _logFile!.writeAsString(
        '\n\n=== MyLife Started at ${DateTime.now().toIso8601String()} ===\n',
        mode: FileMode.append,
      );

      _isInitialized = true;

      // Flush any buffered logs
      for (final log in _buffer) {
        await _writeToFile(log);
      }
      _buffer.clear();
    } catch (e) {
      debugPrint('LogService: Failed to initialize: $e');
    }
  }

  /// Log an info message
  void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  /// Log a warning message
  void warning(String message, {String? tag}) {
    _log('WARN', message, tag: tag);
  }

  /// Log an error message with optional stack trace
  void error(String message,
      {Object? error, StackTrace? stackTrace, String? tag}) {
    final errorDetails = error != null ? '\n  Error: $error' : '';
    final stackDetails = stackTrace != null ? '\n  Stack: $stackTrace' : '';
    _log('ERROR', '$message$errorDetails$stackDetails', tag: tag);
  }

  /// Log a debug message (only in debug mode)
  void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag);
    }
  }

  void _log(String level, String message, {String? tag}) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final tagStr = tag != null ? '[$tag] ' : '';
    final logLine = '$timestamp [$level] $tagStr$message';

    // Always print to console in debug mode
    if (kDebugMode) {
      debugPrint(logLine);
    }

    // Write to file
    if (_isInitialized && _logFile != null) {
      _writeToFile('$logLine\n');
    } else {
      // Buffer until initialized
      _buffer.add('$logLine\n');
    }
  }

  Future<void> _writeToFile(String content) async {
    try {
      await _logFile?.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      debugPrint('LogService: Failed to write: $e');
    }
  }

  /// Get the log file path for display to user
  Future<String?> getLogFilePath() async {
    if (_logFile != null) {
      return _logFile!.path;
    }
    return null;
  }

  /// Get recent log entries (last N lines)
  Future<List<String>> getRecentLogs({int count = 100}) async {
    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }

    try {
      final lines = await _logFile!.readAsLines();
      final start = lines.length > count ? lines.length - count : 0;
      return lines.sublist(start);
    } catch (e) {
      return ['Error reading logs: $e'];
    }
  }

  /// Clear old log files (older than N days)
  Future<void> cleanOldLogs({int keepDays = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/MyLife/logs');

      if (!await logDir.exists()) return;

      final cutoff = DateTime.now().subtract(Duration(days: keepDays));

      await for (final file in logDir.list()) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoff)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('LogService: Failed to clean old logs: $e');
    }
  }
}

/// Convenience function for quick logging
void logInfo(String message, {String? tag}) =>
    LogService.instance.info(message, tag: tag);
void logWarning(String message, {String? tag}) =>
    LogService.instance.warning(message, tag: tag);
void logError(String message,
        {Object? error, StackTrace? stackTrace, String? tag}) =>
    LogService.instance
        .error(message, error: error, stackTrace: stackTrace, tag: tag);
void logDebug(String message, {String? tag}) =>
    LogService.instance.debug(message, tag: tag);
