import 'package:intl/intl.dart';
import '../models/job_application.dart';
import '../constants/app_constants.dart';

/// Generates bilingual (EN/DE) job-application statistics reports in Markdown.
class ApplicationStatisticsMarkdownService {
  static String generateEnglishMarkdown({
    required List<JobApplication> applications,
  }) =>
      _generateMarkdown(applications, isGerman: false);

  static String generateGermanMarkdown({
    required List<JobApplication> applications,
  }) =>
      _generateMarkdown(applications, isGerman: true);

  // ===========================================================================
  // TOP-LEVEL GENERATOR
  // ===========================================================================

  static String _generateMarkdown(List<JobApplication> applications,
      {required bool isGerman}) {
    final buffer = StringBuffer();
    final stats = _calculateStatistics(applications);
    final byStatus = _groupByStatus(applications);

    final interviewing = byStatus[ApplicationStatus.interviewing] ?? [];
    final awaiting = byStatus[ApplicationStatus.applied] ?? []
      ..sort((a, b) =>
          _daysSince(b.applicationDate).compareTo(_daysSince(a.applicationDate)));
    final successful = byStatus[ApplicationStatus.successful] ?? [];
    final rejected = byStatus[ApplicationStatus.rejected] ?? [];
    final noResponse = byStatus[ApplicationStatus.noResponse] ?? [];

    _writeHeader(buffer, stats, isGerman);
    _writeAtAGlance(buffer, stats, isGerman);
    _writeActivePipeline(buffer, interviewing, awaiting, isGerman);
    _writeOutcomes(buffer, successful, rejected, noResponse, isGerman);

    return buffer.toString();
  }

  // ===========================================================================
  // SECTIONS
  // ===========================================================================

  static void _writeHeader(
      StringBuffer buffer, Map<String, dynamic> stats, bool isGerman) {
    final genDate = isGerman
        ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())
        : DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now());

    buffer.writeln(isGerman ? '# Bewerbungsbericht' : '# Job Application Report');
    buffer.writeln();
    if (isGerman) {
      buffer.writeln(
          '**Erstellt:** $genDate · **Bewerbungen gesamt:** ${stats['total']}');
    } else {
      buffer.writeln(
          '**Generated:** $genDate · **Total applications:** ${stats['total']}');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeAtAGlance(
      StringBuffer buffer, Map<String, dynamic> stats, bool isGerman) {
    buffer.writeln(isGerman ? '## Auf einen Blick' : '## At a Glance');
    buffer.writeln();

    final total = stats['total'] as int;
    String pct(int n) =>
        total > 0 ? '${(n / total * 100).toStringAsFixed(1)}%' : '0%';

    if (isGerman) {
      buffer.writeln('| Status | Anzahl | Anteil |');
      buffer.writeln('| :---- | ----: | ----: |');
      buffer.writeln(
          '| Vorstellungsgespräch | ${stats['interviewing']} | ${pct(stats['interviewing'] as int)} |');
      buffer.writeln(
          '| Beworben / Wartend | ${stats['applied']} | ${pct(stats['applied'] as int)} |');
      buffer.writeln(
          '| Entwurf | ${stats['draft']} | ${pct(stats['draft'] as int)} |');
      buffer.writeln(
          '| **Aktiv gesamt** | **${stats['active']}** | **${pct(stats['active'] as int)}** |');
      buffer.writeln(
          '| Erfolgreich | ${stats['successful']} | ${pct(stats['successful'] as int)} |');
      buffer.writeln(
          '| Abgelehnt | ${stats['rejected']} | ${pct(stats['rejected'] as int)} |');
      buffer.writeln(
          '| Keine Antwort | ${stats['noResponse']} | ${pct(stats['noResponse'] as int)} |');
      buffer.writeln(
          '| **Abgeschlossen gesamt** | **${stats['closed']}** | **${pct(stats['closed'] as int)}** |');
    } else {
      buffer.writeln('| Status | Count | Share |');
      buffer.writeln('| :---- | ----: | ----: |');
      buffer.writeln(
          '| Interviewing | ${stats['interviewing']} | ${pct(stats['interviewing'] as int)} |');
      buffer.writeln(
          '| Applied / Awaiting | ${stats['applied']} | ${pct(stats['applied'] as int)} |');
      buffer.writeln(
          '| Draft | ${stats['draft']} | ${pct(stats['draft'] as int)} |');
      buffer.writeln(
          '| **Active total** | **${stats['active']}** | **${pct(stats['active'] as int)}** |');
      buffer.writeln(
          '| Successful | ${stats['successful']} | ${pct(stats['successful'] as int)} |');
      buffer.writeln(
          '| Rejected | ${stats['rejected']} | ${pct(stats['rejected'] as int)} |');
      buffer.writeln(
          '| No Response | ${stats['noResponse']} | ${pct(stats['noResponse'] as int)} |');
      buffer.writeln(
          '| **Closed total** | **${stats['closed']}** | **${pct(stats['closed'] as int)}** |');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeActivePipeline(
    StringBuffer buffer,
    List<JobApplication> interviewing,
    List<JobApplication> awaiting,
    bool isGerman,
  ) {
    final total = interviewing.length + awaiting.length;
    if (total == 0) return;

    buffer.writeln(isGerman
        ? '## Aktive Bewerbungen ($total)'
        : '## Active Applications ($total)');
    buffer.writeln();

    // ── Interviewing ──────────────────────────────────────────────────────────
    if (interviewing.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### Vorstellungsgespräch (${interviewing.length})'
          : '### Interviewing (${interviewing.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Tage im Status |'
          : '| Applied | Company | Position | Location | Days in Stage |');
      buffer.writeln('|---------|-------------|----------|----------|--------------|');

      for (final app in interviewing) {
        final applied = _fmtDate(app.applicationDate);
        final days = _daysSince(_currentStatusDate(app));
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | ${days}d |');
      }
      buffer.writeln();
    }

    // ── Awaiting response ─────────────────────────────────────────────────────
    if (awaiting.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### Wartend auf Antwort (${awaiting.length})'
          : '### Awaiting Response (${awaiting.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Wartezeit |'
          : '| Applied | Company | Position | Location | Waiting |');
      buffer.writeln('|---------|-------------|----------|----------|---------|');

      for (final app in awaiting) {
        final applied = _fmtDate(app.applicationDate);
        final waiting = _daysSince(app.applicationDate);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | ${waiting}d |');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeOutcomes(
    StringBuffer buffer,
    List<JobApplication> successful,
    List<JobApplication> rejected,
    List<JobApplication> noResponse,
    bool isGerman,
  ) {
    final total = successful.length + rejected.length + noResponse.length;
    if (total == 0) return;

    buffer.writeln(isGerman
        ? '## Abgeschlossene Bewerbungen ($total)'
        : '## Closed Applications ($total)');
    buffer.writeln();

    // ── Successful ────────────────────────────────────────────────────────────
    if (successful.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### ✓ Erfolgreich (${successful.length})'
          : '### ✓ Successful (${successful.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Angebot am | Dauer |'
          : '| Applied | Company | Position | Location | Offer Date | Days |');
      buffer.writeln(
          '|---------|-------------|----------|----------|------------|-------|');

      for (final app in successful) {
        final applied = _fmtDate(app.applicationDate);
        final outcomeDate = _getOutcomeDate(app);
        final offerDate = _fmtDate(outcomeDate);
        final days = _daysBetween(app.applicationDate, outcomeDate);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | $offerDate | $days |');
      }
      buffer.writeln();
    }

    // ── Rejected ──────────────────────────────────────────────────────────────
    if (rejected.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### ✗ Abgelehnt (${rejected.length})'
          : '### ✗ Rejected (${rejected.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Abgelehnt am | Dauer |'
          : '| Applied | Company | Position | Location | Rejected On | Days |');
      buffer.writeln(
          '|---------|-------------|----------|----------|-------------|-------|');

      for (final app in rejected) {
        final applied = _fmtDate(app.applicationDate);
        final outcomeDate = _getOutcomeDate(app);
        final rejDate = _fmtDate(outcomeDate);
        final days = _daysBetween(app.applicationDate, outcomeDate);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | $rejDate | $days |');
      }
      buffer.writeln();
    }

    // ── No Response ───────────────────────────────────────────────────────────
    if (noResponse.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### – Keine Antwort (${noResponse.length})'
          : '### – No Response (${noResponse.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Gewartet |'
          : '| Applied | Company | Position | Location | Waited |');
      buffer.writeln('|---------|-------------|----------|----------|---------|');

      final sorted = [...noResponse]
        ..sort((a, b) =>
            _daysSince(b.applicationDate).compareTo(_daysSince(a.applicationDate)));

      for (final app in sorted) {
        final applied = _fmtDate(app.applicationDate);
        final outcomeDate = _getOutcomeDate(app) ?? app.lastUpdated;
        final days = _daysBetween(app.applicationDate, outcomeDate);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | $days |');
      }
      buffer.writeln();
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static String _fmtDate(DateTime? dt) =>
      dt != null ? DateFormat('dd.MM.yyyy').format(dt) : '-';

  static int _daysSince(DateTime? dt) =>
      dt != null ? DateTime.now().difference(dt).inDays : 0;

  static String _daysBetween(DateTime? from, DateTime? to) {
    if (from == null || to == null) return '-';
    final d = to.difference(from).inDays;
    return '${d}d';
  }

  /// Date when the application last transitioned to its current status.
  static DateTime? _currentStatusDate(JobApplication app) {
    if (app.safeStatusHistory.isNotEmpty) {
      final history = app.chronologicalStatusHistory;
      return history
          .lastWhere((c) => c.status == app.status,
              orElse: () => history.last)
          .changedAt;
    }
    return app.lastUpdated ?? app.applicationDate;
  }

  /// Date of the terminal status change (used for outcomes).
  static DateTime? _getOutcomeDate(JobApplication app) {
    if (app.safeStatusHistory.isNotEmpty) {
      final history = app.chronologicalStatusHistory;
      return history
          .lastWhere((c) => c.status == app.status,
              orElse: () => history.last)
          .changedAt;
    }
    return app.lastUpdated;
  }

  // ===========================================================================
  // STATISTICS & GROUPING
  // ===========================================================================

  static Map<String, dynamic> _calculateStatistics(
      List<JobApplication> applications) {
    final total = applications.length;
    final draft =
        applications.where((a) => a.status == ApplicationStatus.draft).length;
    final applied =
        applications.where((a) => a.status == ApplicationStatus.applied).length;
    final interviewing = applications
        .where((a) => a.status == ApplicationStatus.interviewing)
        .length;
    final successful = applications
        .where((a) => a.status == ApplicationStatus.successful)
        .length;
    final rejected =
        applications.where((a) => a.status == ApplicationStatus.rejected).length;
    final noResponse = applications
        .where((a) => a.status == ApplicationStatus.noResponse)
        .length;
    final active = draft + applied + interviewing;
    final closed = successful + rejected + noResponse;

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
    };
  }

  static Map<ApplicationStatus, List<JobApplication>> _groupByStatus(
      List<JobApplication> applications) {
    final grouped = <ApplicationStatus, List<JobApplication>>{};
    for (final app in applications) {
      grouped.putIfAbsent(app.status, () => []).add(app);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        if (a.applicationDate == null && b.applicationDate == null) return 0;
        if (a.applicationDate == null) return 1;
        if (b.applicationDate == null) return -1;
        return b.applicationDate!.compareTo(a.applicationDate!);
      });
    }
    return grouped;
  }
}
