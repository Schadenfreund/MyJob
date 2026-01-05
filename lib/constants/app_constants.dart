/// Application-wide constants and configurations
///
/// This file provides centralized configuration for MyLife app.
library;

/// HTTP request configuration
class HttpConfig {
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration imageTimeout = Duration(seconds: 30);
  static const Duration retryDelay = Duration(milliseconds: 500);
  static const int maxRetries = 2;
}

/// File validation constants
class FileConfig {
  static final RegExp invalidFilenameChars = RegExp(r'[\\/:*?"<>|]');
  static final RegExp multipleSpaces = RegExp(r'\s+');

  static String sanitizeFilename(String filename) => filename
      .replaceAll(invalidFilenameChars, '')
      .replaceAll(multipleSpaces, ' ')
      .trim();

  static const int maxFilenameLength = 200;
}

/// Application metadata
class AppInfo {
  static const String appName = 'MyLife';
  static const String version = '1.0.0';
  static const String description = 'Job Application Management Tool';
  static const String supportEmail = 'support@mylife.app';
}

/// Application status for job applications
enum ApplicationStatus {
  draft('Draft', 'Application in progress'),
  applied('Applied', 'Application submitted'),
  interviewing('Interviewing', 'In interview process'),
  offered('Offered', 'Received job offer'),
  accepted('Accepted', 'Offer accepted'),
  rejected('Rejected', 'Application rejected'),
  withdrawn('Withdrawn', 'Application withdrawn');

  const ApplicationStatus(this.label, this.description);
  final String label;
  final String description;
}

/// Supported languages for documents
enum DocumentLanguage {
  en('English', 'en', '🇬🇧'),
  de('German', 'de', '🇩🇪');

  const DocumentLanguage(this.label, this.code, this.flag);
  final String label;
  final String code;
  final String flag;

  /// Get language from code string
  static DocumentLanguage fromCode(String code) {
    return DocumentLanguage.values.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => DocumentLanguage.en,
    );
  }

  /// Convert to JSON-serializable string
  String toJson() => code;

  /// Create from JSON string
  static DocumentLanguage fromJson(String json) => fromCode(json);
}

/// Debug configuration
class DebugConfig {
  static const bool verboseLogging = false;
  static const bool showDebugOverlay = false;
}
