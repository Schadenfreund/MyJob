import 'dart:io';

import '../services/log_service.dart';

/// Centralised helpers for platform-specific shell operations.
///
/// All methods are static and safe to call from any context.
abstract final class PlatformUtils {
  /// Open a folder in the system file explorer.
  static Future<void> openFolder(String folderPath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
      logWarning('openFolder failed: $e', tag: 'Platform');
    }
  }

  /// Open a folder and select a specific file inside it (Windows only,
  /// falls back to [openFolder] on other platforms).
  static Future<void> openFolderAndSelect(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        // open -R reveals the file in Finder
        await Process.run('open', ['-R', filePath]);
      } else {
        // Fallback: open the parent folder
        final parent = File(filePath).parent.path;
        await openFolder(parent);
      }
    } catch (e) {
      logWarning('openFolderAndSelect failed: $e', tag: 'Platform');
    }
  }

  /// Open a URL in the default browser.
  ///
  /// The [urlString] is validated to ensure it uses a safe scheme
  /// (`http`, `https`, or `mailto`) before being passed to the OS.
  /// On Windows the `cmd /c start` command interprets shell
  /// metacharacters, so `&` is escaped with `^&`.
  static Future<void> openUrl(String urlString) async {
    try {
      // Normalise scheme
      final url = urlString.startsWith('http://') ||
              urlString.startsWith('https://') ||
              urlString.startsWith('mailto:')
          ? urlString
          : 'https://$urlString';

      // Validate: only allow safe URL schemes
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !(uri.scheme == 'http' ||
              uri.scheme == 'https' ||
              uri.scheme == 'mailto')) {
        logWarning('Rejected unsafe URL: $url', tag: 'Platform');
        return;
      }

      if (Platform.isWindows) {
        // Escape `&` to prevent command chaining in cmd.exe
        final safeUrl = url.replaceAll('&', '^&');
        await Process.run('cmd', ['/c', 'start', '""', safeUrl]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      logWarning('openUrl failed: $e', tag: 'Platform');
    }
  }
}
