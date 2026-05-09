import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';
import '../models/update_info.dart';
import '../utils/version_utils.dart';
import '../utils/platform_utils.dart';
import 'log_service.dart';

/// Service for checking and installing application updates from GitHub releases
class UpdateService extends ChangeNotifier {
  UpdateState _state = UpdateState.idle;
  UpdateInfo? _updateInfo;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  DateTime? _lastCheckTime;
  String? _downloadedZipPath;
  String? _extractedUpdatePath;

  // Cancellation token for download
  bool _downloadCancelled = false;

  UpdateState get state => _state;
  UpdateInfo? get updateInfo => _updateInfo;
  String? get errorMessage => _errorMessage;
  double get downloadProgress => _downloadProgress;
  DateTime? get lastCheckTime => _lastCheckTime;
  bool get hasUpdate => _state == UpdateState.available;

  /// Current app version from constants
  String get currentVersion => AppInfo.version;

  /// Check for updates from GitHub releases
  Future<void> checkForUpdates({bool force = false}) async {
    // Respect rate limits unless forced
    if (!force && _lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < UpdateConfig.minCheckInterval) {
        logDebug(
            'Skipping update check - last check was ${elapsed.inMinutes} minutes ago', tag: 'Update');
        return;
      }
    }

    if (_state.isLoading) return;

    _setState(UpdateState.checking);
    _errorMessage = null;

    try {
      final client = http.Client();
      try {
        final response = await client
            .get(
              Uri.parse(UpdateConfig.releasesApiUrl),
              headers: {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'MyJob-App/${AppInfo.version}',
              },
            )
            .timeout(UpdateConfig.checkTimeout);

        _lastCheckTime = DateTime.now();

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          _updateInfo = UpdateInfo.fromGitHubRelease(json);

          // Compare versions
          final current = SemanticVersion.parse(currentVersion);
          final latest = SemanticVersion.parse(_updateInfo!.version);

          if (latest.isNewerThan(current)) {
            _setState(UpdateState.available);
            logInfo(
                'Update available: $currentVersion -> ${_updateInfo!.version}'
                '${_updateInfo!.hasValidDownload ? '' : ' (no direct download)'}', tag: 'Update');
          } else {
            _setState(UpdateState.upToDate);
            logInfo('Already on latest version: $currentVersion', tag: 'Update');
          }
        } else if (response.statusCode == 404) {
          // No published releases found on GitHub
          _setError('No releases found. Check manually at github.com');
          logWarning('No releases found on GitHub (404)', tag: 'Update');
        } else if (response.statusCode == 403) {
          // Rate limited
          _setError('GitHub API rate limit exceeded. Try again later.');
        } else {
          _setError('Failed to check for updates (${response.statusCode})');
        }
      } finally {
        client.close();
      }
    } on SocketException {
      _setError('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      _setError('Network error: ${e.message}');
    } on FormatException {
      _setError('Invalid response from server.');
    } catch (e) {
      _setError('Failed to check for updates: $e');
    }
  }

  /// Download the update ZIP file
  Future<void> downloadUpdate() async {
    if (_updateInfo == null || !_state.canDownload) return;

    // No direct download URL — fall back to the releases page
    if (!_updateInfo!.hasValidDownload) {
      logInfo('No direct download URL, opening releases page', tag: 'Update');
      await openReleasesPage();
      return;
    }

    _setState(UpdateState.downloading);
    _downloadProgress = 0.0;
    _downloadCancelled = false;
    _errorMessage = null;

    try {
      final tempDir = Directory.systemTemp;
      final zipFilename =
          'MyJob-v${_updateInfo!.version}-windows.zip';
      final zipPath = p.join(tempDir.path, zipFilename);

      logInfo('Downloading update to: $zipPath', tag: 'Update');

      // Download with progress tracking
      final client = http.Client();
      try {
        final request =
            http.Request('GET', Uri.parse(_updateInfo!.downloadUrl));
        request.headers['User-Agent'] = 'MyJob-App/${AppInfo.version}';

        final response = await client.send(request);

        if (response.statusCode != 200) {
          _setError('Download failed (${response.statusCode})');
          return;
        }

        final contentLength = response.contentLength ?? _updateInfo!.downloadSize;
        final bytes = <int>[];
        int received = 0;

        await for (final chunk in response.stream) {
          if (_downloadCancelled) {
            logInfo('Download cancelled by user', tag: 'Update');
            _setState(UpdateState.available);
            return;
          }

          bytes.addAll(chunk);
          received += chunk.length;

          if (contentLength > 0) {
            _downloadProgress = received / contentLength;
            notifyListeners();
          }
        }

        // Write to file
        final zipFile = File(zipPath);
        await zipFile.writeAsBytes(bytes);
        _downloadedZipPath = zipPath;

        logInfo('Download complete: ${bytes.length} bytes', tag: 'Update');

        // Verify integrity before extraction
        if (!await _verifyChecksum(bytes)) return;

        // Extract the update
        await _extractUpdate();
      } finally {
        client.close();
      }
    } on SocketException {
      _setError('Download interrupted. Please check your connection.');
    } catch (e) {
      _setError('Download failed: $e');
    }
  }

  /// Cancel an ongoing download
  void cancelDownload() {
    _downloadCancelled = true;
  }

  /// Verify the downloaded ZIP against the published SHA256 checksum.
  /// Returns true if verification passes or no checksum is available.
  Future<bool> _verifyChecksum(List<int> bytes) async {
    if (_updateInfo?.checksumUrl == null) {
      logDebug('No checksum URL available — skipping verification', tag: 'Update');
      return true;
    }

    _setState(UpdateState.verifying);

    try {
      final client = http.Client();
      try {
        final response = await client
            .get(
              Uri.parse(_updateInfo!.checksumUrl!),
              headers: {'User-Agent': 'MyJob-App/${AppInfo.version}'},
            )
            .timeout(UpdateConfig.checkTimeout);

        if (response.statusCode != 200) {
          logWarning('Could not fetch checksum (${response.statusCode}) '
              '— skipping verification', tag: 'Update');
          return true;
        }

        // .sha256 files typically contain: "<hash>  <filename>" or just "<hash>"
        final expectedHash =
            response.body.trim().split(RegExp(r'\s+')).first.toLowerCase();
        final actualHash = sha256.convert(bytes).toString().toLowerCase();

        if (expectedHash == actualHash) {
          logInfo('Checksum verified: $actualHash', tag: 'Update');
          return true;
        } else {
          logError(
              'Checksum mismatch! Expected: $expectedHash, Got: $actualHash', tag: 'Update');
          _setError(
              'Download integrity check failed. The file may be corrupted. '
              'Please try again.');
          return false;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      logWarning('Checksum verification error: $e — skipping', tag: 'Update');
      return true;
    }
  }

  /// Extract the downloaded ZIP to a temp folder
  Future<void> _extractUpdate() async {
    if (_downloadedZipPath == null) return;

    _setState(UpdateState.extracting);

    try {
      final tempDir = Directory.systemTemp;
      final extractPath = p.join(tempDir.path, 'MyJob_Update');
      final extractDir = Directory(extractPath);

      // Clean up any previous extraction
      if (extractDir.existsSync()) {
        extractDir.deleteSync(recursive: true);
      }
      extractDir.createSync(recursive: true);

      logInfo('Extracting update to: $extractPath', tag: 'Update');

      // Extract in isolate to keep UI responsive
      final success = await compute(_extractZipIsolate, {
        'zipPath': _downloadedZipPath!,
        'destPath': extractPath,
      });

      if (success) {
        _extractedUpdatePath = extractPath;
        _setState(UpdateState.readyToInstall);
        logInfo('Extraction complete', tag: 'Update');
      } else {
        _setError('Failed to extract update. The download may be corrupted.');
      }
    } catch (e) {
      _setError('Extraction failed: $e');
    }
  }

  /// Install the update by generating and running a PowerShell updater script.
  Future<void> installUpdate() async {
    if (_extractedUpdatePath == null || !_state.canInstall) return;

    _setState(UpdateState.installing);

    try {
      final appDir = p.dirname(Platform.resolvedExecutable);
      final scriptPath = await _generateUpdaterScript(appDir);

      logInfo('Launching updater script: $scriptPath', tag: 'Update');

      // Encode the script as UTF-16LE Base64 for PowerShell's -EncodedCommand.
      // Unlike -File or -Command, -EncodedCommand is never subject to execution
      // policy — the most reliable way to run a script on any Windows machine.
      final scriptContent = await File(scriptPath).readAsString();
      final utf16leBytes = <int>[];
      for (final char in scriptContent.codeUnits) {
        utf16leBytes.add(char & 0xFF);
        utf16leBytes.add((char >> 8) & 0xFF);
      }
      final encodedCommand = base64.encode(utf16leBytes);

      // Route through cmd /c start /b to break Job Object inheritance.
      // ProcessStartMode.detached alone uses DETACHED_PROCESS, which does NOT
      // escape the parent's Windows Job Object. If the Job carries
      // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE (set by VS Code, Explorer, etc.),
      // the child is killed the instant exit(0) closes the parent.
      // cmd's "start" spawns an independent process that survives the parent's exit.
      await Process.start(
        'cmd.exe',
        ['/c', 'start', '/b', 'powershell.exe', '-NonInteractive', '-EncodedCommand', encodedCommand],
        mode: ProcessStartMode.detached,
      );

      logInfo('Exiting app for update...', tag: 'Update');
      exit(0);
    } catch (e) {
      _setError('Failed to start update installer: $e');
    }
  }

  /// Generate the PowerShell script that performs the actual update.
  ///
  /// Uses Get-Process (no console window), robocopy (reliable copy that
  /// preserves UserData via /XD), and logs every step to a file.
  Future<String> _generateUpdaterScript(String appDir) async {
    final scriptPath = p.join(Directory.systemTemp.path, 'myjob_updater.ps1');
    final logPath = p.join(Directory.systemTemp.path, 'myjob_update.log');
    final exeName = p.basename(Platform.resolvedExecutable);
    final processName =
        exeName.replaceAll(RegExp(r'\.exe$', caseSensitive: false), '');

    // Unwrap single-folder ZIP root (e.g. MyJob-v1.2.0-windows/)
    String updateContentPath = _extractedUpdatePath!;
    final subdirs = Directory(_extractedUpdatePath!)
        .listSync()
        .whereType<Directory>()
        .toList();
    if (subdirs.length == 1) updateContentPath = subdirs.first.path;

    // Single-quoted PS strings are literal — Windows backslash paths are safe.
    final script = '''
function Log(\$msg) {
    "[(\$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))] \$msg" |
        Out-File -Append -Encoding utf8 -FilePath '$logPath'
}

Log "=== MyJob Update Started ==="
Log "Version: ${_updateInfo?.version}"
Log "Source:  $updateContentPath"
Log "Target:  $appDir"

# Wait for app to exit (max 60 s)
Log "Waiting for $processName to exit..."
Start-Sleep -Seconds 2
\$waited = 0
while (Get-Process -Name '$processName' -ErrorAction SilentlyContinue) {
    Start-Sleep -Seconds 1
    \$waited++
    if (\$waited -ge 60) {
        Log "WARNING: Timeout after \$waited s, proceeding anyway"
        break
    }
}
Log "Process exited after \$waited s"

# Copy all files, skip UserData so settings and data are preserved
Log "Copying files..."
\$output = & robocopy '$updateContentPath' '$appDir' /E /XD UserData /R:5 /W:2 /NP 2>&1
\$rc = \$LASTEXITCODE
\$output | Out-File -Append -Encoding utf8 -FilePath '$logPath'
Log "Robocopy exit code: \$rc"

# Robocopy exit codes 0-7 are success; 8+ indicate errors
if (\$rc -ge 8) {
    Log "ERROR: File copy failed (robocopy code \$rc)"
    exit 1
}

# Clean up temp files
Log "Cleaning up..."
Remove-Item -Path '$_extractedUpdatePath' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path '$_downloadedZipPath' -Force -ErrorAction SilentlyContinue

# Restart the app
Log "Restarting app..."
Start-Sleep -Seconds 1
Start-Process -FilePath '$appDir\\$exeName' -WorkingDirectory '$appDir'
Log "=== Update Complete ==="
''';

    await File(scriptPath).writeAsString(script);
    logDebug('Updater script generated at: $scriptPath', tag: 'Update');
    return scriptPath;
  }

  /// Open the GitHub releases page in browser (fallback for manual update)
  Future<void> openReleasesPage() async {
    await PlatformUtils.openUrl(UpdateConfig.releasesPageUrl);
  }

  /// Reset state (e.g., after dismissing an error)
  void reset() {
    _state = UpdateState.idle;
    _errorMessage = null;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  void _setState(UpdateState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = UpdateState.error;
    notifyListeners();
    logError('Update error: $message', tag: 'Update');
  }

  /// Isolate function for ZIP extraction
  static Future<bool> _extractZipIsolate(Map<String, String> params) async {
    try {
      final zipPath = params['zipPath']!;
      final destPath = params['destPath']!;

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      debugPrint('[Update Isolate] Extracting ${archive.length} files...');

      for (final file in archive) {
        final filename = file.name;

        // Reject path traversal attempts
        if (filename.contains('..') || filename.startsWith('/') || filename.startsWith('\\')) {
          debugPrint('[Update Isolate] Skipping suspicious entry: $filename');
          continue;
        }

        // Verify resolved path stays within destination
        final resolvedPath = p.normalize(p.join(destPath, filename));
        if (!resolvedPath.startsWith(destPath)) {
          debugPrint('[Update Isolate] Path traversal blocked: $filename');
          continue;
        }

        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(resolvedPath);
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        } else {
          final outDir = Directory(resolvedPath);
          outDir.createSync(recursive: true);
        }
      }

      debugPrint('[Update Isolate] Extraction complete');
      return true;
    } catch (e) {
      debugPrint('[Update Isolate] Error: $e');
      return false;
    }
  }
}
