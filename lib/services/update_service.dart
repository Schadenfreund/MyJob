import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';
import '../models/update_info.dart';
import '../utils/version_utils.dart';

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
        debugPrint(
            'Skipping update check - last check was ${elapsed.inMinutes} minutes ago');
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

          if (latest.isNewerThan(current) && _updateInfo!.hasValidDownload) {
            _setState(UpdateState.available);
            debugPrint(
                'Update available: $currentVersion -> ${_updateInfo!.version}');
          } else {
            _setState(UpdateState.upToDate);
            debugPrint('Already on latest version: $currentVersion');
          }
        } else if (response.statusCode == 404) {
          // No releases found
          _setState(UpdateState.upToDate);
          debugPrint('No releases found on GitHub');
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

    _setState(UpdateState.downloading);
    _downloadProgress = 0.0;
    _downloadCancelled = false;
    _errorMessage = null;

    try {
      final tempDir = Directory.systemTemp;
      final zipFilename =
          'MyJob-v${_updateInfo!.version}-windows.zip';
      final zipPath = p.join(tempDir.path, zipFilename);

      debugPrint('Downloading update to: $zipPath');

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
            debugPrint('Download cancelled by user');
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

        debugPrint('Download complete: ${bytes.length} bytes');

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

      debugPrint('Extracting update to: $extractPath');

      // Extract in isolate to keep UI responsive
      final success = await compute(_extractZipIsolate, {
        'zipPath': _downloadedZipPath!,
        'destPath': extractPath,
      });

      if (success) {
        _extractedUpdatePath = extractPath;
        _setState(UpdateState.readyToInstall);
        debugPrint('Extraction complete');
      } else {
        _setError('Failed to extract update. The download may be corrupted.');
      }
    } catch (e) {
      _setError('Extraction failed: $e');
    }
  }

  /// Install the update by generating and running an updater script
  Future<void> installUpdate() async {
    if (_extractedUpdatePath == null || !_state.canInstall) return;

    _setState(UpdateState.installing);

    try {
      final appDir = p.dirname(Platform.resolvedExecutable);
      final scriptPath = await _generateUpdaterScript(appDir);

      debugPrint('Launching updater script: $scriptPath');

      // Launch the updater script as a detached process
      await Process.start(
        'cmd.exe',
        ['/c', 'start', '', '/b', scriptPath],
        mode: ProcessStartMode.detached,
        workingDirectory: Directory.systemTemp.path,
      );

      // Exit the app so the updater can replace files
      debugPrint('Exiting app for update...');
      exit(0);
    } catch (e) {
      _setError('Failed to start update installer: $e');
    }
  }

  /// Generate the Windows batch script that performs the actual update
  Future<String> _generateUpdaterScript(String appDir) async {
    final scriptPath = p.join(Directory.systemTemp.path, 'myjob_updater.bat');
    final exeName = p.basename(Platform.resolvedExecutable);

    // Find the actual content folder inside the extracted update
    // The ZIP contains a folder like "MyJob-v1.0.1-windows" with the actual files
    String updateContentPath = _extractedUpdatePath!;
    final extractedDir = Directory(_extractedUpdatePath!);
    final subdirs = extractedDir.listSync().whereType<Directory>().toList();
    if (subdirs.length == 1) {
      // The ZIP contains a single folder - use its contents
      updateContentPath = subdirs.first.path;
    }

    final script = '''
@echo off
:: MyJob Auto-Updater Script
:: Generated by MyJob v$currentVersion
:: Installing version ${_updateInfo?.version}

setlocal EnableDelayedExpansion

set "APP_DIR=$appDir"
set "UPDATE_DIR=$updateContentPath"
set "EXE_NAME=$exeName"
set "LOG_FILE=%TEMP%\\myjob_update.log"

echo [%date% %time%] Update started >> "%LOG_FILE%"
echo Updating MyJob to version ${_updateInfo?.version}...

:: Wait for app to close (max 30 seconds)
echo Waiting for MyJob to close...
set /a count=0
:waitloop
tasklist /FI "IMAGENAME eq %EXE_NAME%" 2>NUL | find /I /N "%EXE_NAME%">NUL
if "%ERRORLEVEL%"=="0" (
    set /a count+=1
    if !count! GEQ 30 (
        echo [%date% %time%] Timeout waiting for app to close >> "%LOG_FILE%"
        echo Error: MyJob did not close in time. Please close it manually and try again.
        pause
        exit /b 1
    )
    ping 127.0.0.1 -n 2 > nul
    goto :waitloop
)

echo [%date% %time%] App closed, starting file update >> "%LOG_FILE%"

:: Delete old app files (PRESERVE UserData folder!)
echo Removing old application files...
for %%F in ("%APP_DIR%\\*.exe") do (
    del /F /Q "%%F" 2>>"%LOG_FILE%"
)
for %%F in ("%APP_DIR%\\*.dll") do (
    del /F /Q "%%F" 2>>"%LOG_FILE%"
)
if exist "%APP_DIR%\\data" rmdir /S /Q "%APP_DIR%\\data" 2>>"%LOG_FILE%"

:: Copy new files
echo Installing new version...
xcopy /E /Y /Q "%UPDATE_DIR%\\*" "%APP_DIR%\\" >>"%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo [%date% %time%] File copy failed with error %ERRORLEVEL% >> "%LOG_FILE%"
    echo Error: Failed to copy update files. See %LOG_FILE% for details.
    pause
    exit /b 1
)

:: Cleanup temp files
echo Cleaning up...
rmdir /S /Q "$_extractedUpdatePath" 2>>"%LOG_FILE%"
del /F /Q "$_downloadedZipPath" 2>>"%LOG_FILE%"

echo [%date% %time%] Update complete, restarting app >> "%LOG_FILE%"
echo Update complete! Restarting MyJob...

:: Small delay before restart
ping 127.0.0.1 -n 2 > nul

:: Restart the app
start "" "%APP_DIR%\\%EXE_NAME%"

:: Delete this script
(goto) 2>nul & del "%~f0"
''';

    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(script);

    debugPrint('Updater script generated at: $scriptPath');
    return scriptPath;
  }

  /// Open the GitHub releases page in browser (fallback for manual update)
  Future<void> openReleasesPage() async {
    try {
      await Process.run('cmd', ['/c', 'start', UpdateConfig.releasesPageUrl]);
    } catch (e) {
      debugPrint('Failed to open releases page: $e');
    }
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
    debugPrint('Update error: $message');
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
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(destPath, filename));
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        } else {
          final outDir = Directory(p.join(destPath, filename));
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
