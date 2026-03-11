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
  static final RegExp _invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final RegExp _multiUnderscores = RegExp(r'_+');
  static final RegExp _leadingTrailingUnderscores = RegExp(r'^_+|_+$');

  static const int maxFilenameLength = 200;

  /// Sanitize a string for safe use as a filename.
  ///
  /// Replaces Windows-invalid characters and control characters with
  /// underscores, collapses whitespace runs, strips leading/trailing
  /// underscores, and enforces [maxFilenameLength].
  ///
  /// If [useUnderscores] is true (default), whitespace is replaced
  /// with underscores; otherwise spaces are preserved but collapsed.
  static String sanitizeFilename(
    String filename, {
    bool useUnderscores = false,
  }) {
    if (filename.isEmpty) return 'Document';

    var result = filename.replaceAll(_invalidChars, '_');

    if (useUnderscores) {
      result = result
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(_multiUnderscores, '_');
    } else {
      result = result
          .replaceAll(_multiUnderscores, '_')
          .replaceAll(RegExp(r'\s+'), ' ');
    }

    result = result
        .replaceAll(_leadingTrailingUnderscores, '')
        .trim();

    if (result.isEmpty) return 'Document';
    if (result.length > maxFilenameLength) {
      result = result.substring(0, maxFilenameLength);
    }
    return result;
  }
}

/// Application metadata
class AppInfo {
  static const String appName = 'MyJob';
  static const String version = '1.1.8';
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

  String get localizationKey => switch (this) {
        ApplicationStatus.noResponse => 'status_no_response',
        _ => 'status_$name',
      };
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
