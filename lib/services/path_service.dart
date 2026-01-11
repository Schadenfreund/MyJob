import 'dart:io';
import 'package:path/path.dart' as p;

/// Centralized path service for UserData folder management
///
/// Provides a single source of truth for accessing the portable UserData
/// folder and its subdirectories. Caches the path for efficiency.
class PathService {
  PathService._();

  static final PathService instance = PathService._();

  String? _userDataPath;

  /// Get the portable UserData folder path
  ///
  /// Returns the path to the UserData folder next to the executable.
  /// Creates the folder and necessary subdirectories if they don't exist.
  /// Caches the result for subsequent calls.
  Future<String> getUserDataPath() async {
    if (_userDataPath != null) return _userDataPath!;

    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    _userDataPath = p.join(exeDir, 'UserData');

    final userDataDir = Directory(_userDataPath!);
    if (!userDataDir.existsSync()) {
      userDataDir.createSync(recursive: true);
    }

    return _userDataPath!;
  }

  /// Get UserData path synchronously (only works after async initialization)
  ///
  /// Throws if getUserDataPath() hasn't been called yet.
  String getUserDataPathSync() {
    if (_userDataPath == null) {
      throw StateError(
        'PathService not initialized. Call getUserDataPath() first.',
      );
    }
    return _userDataPath!;
  }

  /// Ensure a subdirectory exists within UserData
  ///
  /// Example: ensureSubdirectory('applications') creates UserData/applications
  Future<String> ensureSubdirectory(String subPath) async {
    final userDataPath = await getUserDataPath();
    final fullPath = p.join(userDataPath, subPath);
    final dir = Directory(fullPath);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return fullPath;
  }

  /// Ensure multiple subdirectories exist within UserData
  ///
  /// Example: ensureSubdirectories(['profiles/en', 'profiles/de', 'applications'])
  Future<void> ensureSubdirectories(List<String> subPaths) async {
    for (final subPath in subPaths) {
      await ensureSubdirectory(subPath);
    }
  }

  /// Get a file path within UserData
  ///
  /// Example: getFilePath('applications', 'app123.json')
  /// Returns: UserData/applications/app123.json
  Future<String> getFilePath(String subPath, String filename) async {
    final userDataPath = await getUserDataPath();
    return p.join(userDataPath, subPath, filename);
  }

  /// Get a file path within UserData (synchronous version)
  ///
  /// Only works after getUserDataPath() has been called.
  String getFilePathSync(String subPath, String filename) {
    final userDataPath = getUserDataPathSync();
    return p.join(userDataPath, subPath, filename);
  }

  /// Clear the cached path (useful for testing)
  void clearCache() {
    _userDataPath = null;
  }
}
