import 'package:intl/intl.dart';
import '../models/job_application.dart';
import '../constants/app_constants.dart';

/// Service for generating application statistics in Markdown format
/// Supports separate English and German exports
class ApplicationStatisticsMarkdownService {
  /// Generate English statistics markdown
  static String generateEnglishMarkdown({
    required List<JobApplication> applications,
  }) {
    return _generateMarkdown(applications, isGerman: false);
  }

  /// Generate German statistics markdown
  static String generateGermanMarkdown({
    required List<JobApplication> applications,
  }) {
    return _generateMarkdown(applications, isGerman: true);
  }

  static String _generateMarkdown(List<JobApplication> applications,
      {required bool isGerman}) {
    final buffer = StringBuffer();
    final stats = _calculateStatistics(applications);
    final byStatus = _groupByStatus(applications);

    // Sort applications by date (most recent first)
    final sortedApps = applications.toList()
      ..sort((a, b) {
        if (a.applicationDate == null && b.applicationDate == null) return 0;
        if (a.applicationDate == null) return 1;
        if (b.applicationDate == null) return -1;
        return b.applicationDate!.compareTo(a.applicationDate!);
      });

    // Header
    buffer
        .writeln(isGerman ? '# Bewerbungsbericht' : '# Job Application Report');
    buffer.writeln();
    buffer.writeln(isGerman
        ? '**Erstellt am:** ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}'
        : '**Generated on:** ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Executive Summary
    _writeExecutiveSummary(buffer, stats, isGerman);
    buffer.writeln();

    // Application History - Chronological
    _writeApplicationHistory(buffer, sortedApps, isGerman);
    buffer.writeln();

    // Status Breakdown
    _writeStatusBreakdown(buffer, byStatus, isGerman);
    buffer.writeln();

    // Statistics Summary
    _writeStatisticsSummary(buffer, stats, isGerman);

    return buffer.toString();
  }

  static Map<String, dynamic> _calculateStatistics(
      List<JobApplication> applications) {
    final total = applications.length;
    final draft = applications
        .where((app) => app.status == ApplicationStatus.draft)
        .length;
    final applied = applications
        .where((app) => app.status == ApplicationStatus.applied)
        .length;
    final interviewing = applications
        .where((app) => app.status == ApplicationStatus.interviewing)
        .length;
    final successful = applications
        .where((app) => app.status == ApplicationStatus.successful)
        .length;
    final rejected = applications
        .where((app) => app.status == ApplicationStatus.rejected)
        .length;
    final noResponse = applications
        .where((app) => app.status == ApplicationStatus.noResponse)
        .length;

    final active = draft + applied + interviewing;
    final closed = successful + rejected + noResponse;
    final successRate =
        total > 0 ? (successful / total * 100).toStringAsFixed(1) : '0.0';
    final responseRate = total > 0
        ? ((total - noResponse) / total * 100).toStringAsFixed(1)
        : '0.0';
    final interviewRate = total > 0
        ? ((interviewing + successful) / total * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'total': total,
      'draft': draft,
      'applied': applied,
      'interviewing': interviewing,
      'successful': successful,
      'rejected': rejected,
      'noResponse': noResponse,
      'active': active,
      'closed': closed,
      'successRate': successRate,
      'responseRate': responseRate,
      'interviewRate': interviewRate,
    };
  }

  static Map<ApplicationStatus, List<JobApplication>> _groupByStatus(
      List<JobApplication> applications) {
    final Map<ApplicationStatus, List<JobApplication>> grouped = {};

    for (final app in applications) {
      grouped.putIfAbsent(app.status, () => []).add(app);
    }

    // Sort each group by date (most recent first)
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        if (a.applicationDate == null && b.applicationDate == null) return 0;
        if (a.applicationDate == null) return 1;
        if (b.applicationDate == null) return -1;
        return b.applicationDate!.compareTo(a.applicationDate!);
      });
    }

    return grouped;
  }

  static void _writeExecutiveSummary(
      StringBuffer buffer, Map<String, dynamic> stats, bool isGerman) {
    buffer.writeln(isGerman ? '## Zusammenfassung' : '## Executive Summary');
    buffer.writeln();

    if (isGerman) {
      buffer.writeln(
          'Dieser Bericht enthält eine vollständige Übersicht über ${stats['total']} Bewerbungen.');
      buffer.writeln(
          'Derzeit sind ${stats['active']} Bewerbungen aktiv und ${stats['closed']} abgeschlossen.');
      buffer.writeln();
      buffer.writeln(
          '**Erfolgsquote:** ${stats['successRate']}% der Bewerbungen waren erfolgreich.');
      buffer.writeln();
      buffer.writeln(
          '**Antwortquote:** ${stats['responseRate']}% der Unternehmen haben geantwortet.');
      buffer.writeln();
      buffer.writeln(
          '**Gesprächsquote:** ${stats['interviewRate']}% der Bewerbungen führten zu Gesprächen.');
    } else {
      buffer.writeln(
          'This report contains a complete overview of ${stats['total']} job applications.');
      buffer.writeln(
          'Currently, ${stats['active']} applications are active and ${stats['closed']} are closed.');
      buffer.writeln();
      buffer.writeln(
          '**Success Rate:** ${stats['successRate']}% of applications were successful.');
      buffer.writeln();
      buffer.writeln(
          '**Response Rate:** ${stats['responseRate']}% of companies responded.');
      buffer.writeln();
      buffer.writeln(
          '**Interview Rate:** ${stats['interviewRate']}% of applications led to interviews.');
    }
  }

  static void _writeApplicationHistory(
      StringBuffer buffer, List<JobApplication> applications, bool isGerman) {
    buffer
        .writeln(isGerman ? '## Bewerbungsverlauf' : '## Application History');
    buffer.writeln();
    buffer.writeln(isGerman
        ? 'Chronologische Übersicht aller Bewerbungen (neueste zuerst):'
        : 'Chronological overview of all applications (most recent first):');
    buffer.writeln();

    if (applications.isEmpty) {
      buffer.writeln(isGerman
          ? '*Keine Bewerbungen vorhanden.*'
          : '*No applications available.*');
      return;
    }

    buffer.writeln(isGerman
        ? '| Datum | Unternehmen | Position | Standort | Status | Notizen |'
        : '| Date | Company | Position | Location | Status | Notes |');
    buffer.writeln(
        '|-------|-------------|----------|----------|--------|---------|');

    for (final app in applications) {
      final date = app.applicationDate != null
          ? DateFormat('dd.MM.yyyy').format(app.applicationDate!)
          : (isGerman ? 'Entwurf' : 'Draft');
      final company = app.company.isNotEmpty ? app.company : '-';
      final position = app.position.isNotEmpty ? app.position : '-';
      final location = app.location?.isNotEmpty == true ? app.location! : '-';
      final status = isGerman
          ? _getStatusLabelDe(app.status)
          : _getStatusLabel(app.status);
      final notes = app.notes?.isNotEmpty == true
          ? app.notes!.replaceAll('\n', ' ').replaceAll('|', '\\|')
          : '-';

      buffer.writeln(
          '| $date | $company | $position | $location | $status | ${notes.length > 50 ? '${notes.substring(0, 47)}...' : notes} |');
    }
  }

  static void _writeStatusBreakdown(StringBuffer buffer,
      Map<ApplicationStatus, List<JobApplication>> byStatus, bool isGerman) {
    buffer.writeln(
        isGerman ? '## Bewerbungen nach Status' : '## Applications by Status');
    buffer.writeln();

    // Define order for status display
    final statusOrder = [
      ApplicationStatus.interviewing,
      ApplicationStatus.applied,
      ApplicationStatus.draft,
      ApplicationStatus.successful,
      ApplicationStatus.rejected,
      ApplicationStatus.noResponse,
    ];

    for (final status in statusOrder) {
      final apps = byStatus[status];
      if (apps == null || apps.isEmpty) continue;

      final label =
          isGerman ? _getStatusLabelDe(status) : _getStatusLabel(status);

      buffer.writeln('### $label (${apps.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Datum | Unternehmen | Position | Standort |'
          : '| Date | Company | Position | Location |');
      buffer.writeln('|-------|-------------|----------|----------|');

      for (final app in apps) {
        final date = app.applicationDate != null
            ? DateFormat('dd.MM.yyyy').format(app.applicationDate!)
            : '-';
        final location = app.location ?? '-';
        buffer.writeln(
            '| $date | ${app.company} | ${app.position} | $location |');
      }
      buffer.writeln();
    }
  }

  static void _writeStatisticsSummary(
      StringBuffer buffer, Map<String, dynamic> stats, bool isGerman) {
    buffer.writeln(
        isGerman ? '## Statistische Übersicht' : '## Statistical Overview');
    buffer.writeln();

    buffer.writeln(
        isGerman ? '### Status-Verteilung' : '### Status Distribution');
    buffer.writeln();
    buffer.writeln(isGerman
        ? '| Status | Anzahl | Prozent |'
        : '| Status | Count | Percentage |');
    buffer.writeln('|--------|--------|-----------|');

    final total = stats['total'] as int;

    final statusData = [
      ('Interviewing', 'Im Gespräch', stats['interviewing']),
      ('Applied', 'Beworben', stats['applied']),
      ('Draft', 'Entwurf', stats['draft']),
      ('Successful', 'Erfolgreich', stats['successful']),
      ('Rejected', 'Abgelehnt', stats['rejected']),
      ('No Response', 'Keine Antwort', stats['noResponse']),
    ];

    for (final (labelEn, labelDe, count) in statusData) {
      final label = isGerman ? labelDe : labelEn;
      final percentage =
          total > 0 ? ((count as int) / total * 100).toStringAsFixed(1) : '0.0';
      buffer.writeln('| $label | $count | $percentage% |');
    }

    buffer.writeln();
    buffer.writeln(isGerman ? '### Gesamtstatistik' : '### Overall Statistics');
    buffer.writeln();
    buffer.writeln(isGerman ? '| Kennzahl | Wert |' : '| Metric | Value |');
    buffer.writeln('|----------|------|');
    buffer.writeln(isGerman
        ? '| Bewerbungen gesamt | ${stats['total']} |'
        : '| Total Applications | ${stats['total']} |');
    buffer.writeln(isGerman
        ? '| Aktive Bewerbungen | ${stats['active']} |'
        : '| Active Applications | ${stats['active']} |');
    buffer.writeln(isGerman
        ? '| Abgeschlossene Bewerbungen | ${stats['closed']} |'
        : '| Closed Applications | ${stats['closed']} |');
    buffer.writeln(isGerman
        ? '| Erfolgsquote | ${stats['successRate']}% |'
        : '| Success Rate | ${stats['successRate']}% |');
    buffer.writeln(isGerman
        ? '| Antwortquote | ${stats['responseRate']}% |'
        : '| Response Rate | ${stats['responseRate']}% |');
    buffer.writeln(isGerman
        ? '| Gesprächsquote | ${stats['interviewRate']}% |'
        : '| Interview Rate | ${stats['interviewRate']}% |');
  }

  static String _getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.interviewing:
        return 'Interviewing';
      case ApplicationStatus.successful:
        return 'Successful';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.noResponse:
        return 'No Response';
    }
  }

  static String _getStatusLabelDe(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Entwurf';
      case ApplicationStatus.applied:
        return 'Beworben';
      case ApplicationStatus.interviewing:
        return 'Im Gespräch';
      case ApplicationStatus.successful:
        return 'Erfolgreich';
      case ApplicationStatus.rejected:
        return 'Abgelehnt';
      case ApplicationStatus.noResponse:
        return 'Keine Antwort';
    }
  }
}
