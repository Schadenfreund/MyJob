/// Application-wide constants and configurations
///
/// This file provides centralized configuration for MyJob app.
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
  static const String appName = 'MyJob';
  static const String version = '1.0.3';
  static const String description = 'Job Application Management Tool';
  static const String supportEmail = 'support@myjob.app';
}

/// Application status for job applications
enum ApplicationStatus {
  draft('Draft', 'Application in progress'),
  applied('Applied', 'Application submitted'),
  interviewing('Interviewing', 'In interview process'),
  successful('Successful', 'Job offer accepted'),
  rejected('Rejected', 'Application rejected'),
  noResponse('No Response', 'No response received');

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

/// Auto-update configuration
class UpdateConfig {
  static const String githubOwner = 'Schadenfreund';
  static const String githubRepo = 'MyJob';
  static const String releasesApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
  static const String releasesPageUrl =
      'https://github.com/$githubOwner/$githubRepo/releases';

  /// Expected asset filename pattern (version will be inserted)
  static String assetFilename(String version) => 'MyJob-v$version-windows.zip';

  static const Duration checkTimeout = Duration(seconds: 30);
  static const Duration downloadTimeout = Duration(minutes: 10);

  /// Minimum time between update checks (to respect rate limits)
  static const Duration minCheckInterval = Duration(hours: 1);
}
