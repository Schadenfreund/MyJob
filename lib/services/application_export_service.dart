import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/job_application.dart';
import 'application_statistics_markdown_service.dart';
import 'log_service.dart';

/// Result of an export operation
class ExportResult {
  const ExportResult({
    required this.success,
    this.folderPath,
    this.dateString,
    this.error,
  });

  final bool success;
  final String? folderPath;
  final String? dateString;
  final String? error;

  /// No applications to export
  static const empty = ExportResult(success: false, error: 'empty');

  /// User cancelled the folder picker
  static const cancelled = ExportResult(success: false, error: 'cancelled');
}

/// Service for exporting application data (statistics markdown, etc.)
///
/// Extracts file I/O and generation logic from the UI layer so the
/// screen only handles presentation and user interaction.
class ApplicationExportService {
  ApplicationExportService._();
  static final instance = ApplicationExportService._();

  /// Export bilingual statistics markdown files to [outputDir].
  ///
  /// Returns an [ExportResult] indicating success/failure, the folder
  /// path written to, and the date string used in filenames.
  Future<ExportResult> exportStatisticsMarkdown({
    required List<JobApplication> applications,
    required String outputDir,
  }) async {
    if (applications.isEmpty) {
      return ExportResult.empty;
    }

    try {
      // Generate both English and German markdown
      final englishMarkdown =
          ApplicationStatisticsMarkdownService.generateEnglishMarkdown(
        applications: applications,
      );
      final germanMarkdown =
          ApplicationStatisticsMarkdownService.generateGermanMarkdown(
        applications: applications,
      );

      // Create filenames with date
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final englishFile =
          File('$outputDir\\Application_Statistics_EN_$dateStr.md');
      final germanFile =
          File('$outputDir\\Application_Statistics_DE_$dateStr.md');

      // Save both files
      await englishFile.writeAsString(englishMarkdown, encoding: utf8);
      await germanFile.writeAsString(germanMarkdown, encoding: utf8);

      logInfo('Statistics exported to $outputDir', tag: 'Export');

      return ExportResult(
        success: true,
        folderPath: outputDir,
        dateString: dateStr,
      );
    } catch (e, stackTrace) {
      logError('Failed to export statistics',
          error: e, stackTrace: stackTrace, tag: 'Export');
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
