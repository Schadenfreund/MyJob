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

    _writeHeader(buffer, isGerman);
    _writeAtAGlance(buffer, stats, isGerman);
    _writeActivePipeline(buffer, interviewing, awaiting, isGerman);
    _writeOutcomes(buffer, successful, rejected, noResponse, isGerman);

    return buffer.toString();
  }

  // ===========================================================================
  // SECTIONS
  // ===========================================================================

  static void _writeHeader(StringBuffer buffer, bool isGerman) {
    final genDate = isGerman
        ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())
        : DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now());

    buffer.writeln(isGerman ? '# Bewerbungsbericht' : '# Job Application Report');
    buffer.writeln();
    buffer.writeln(
        isGerman ? '**Erstellt:** $genDate' : '**Generated:** $genDate');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeAtAGlance(
      StringBuffer buffer, Map<String, dynamic> stats, bool isGerman) {
    buffer.writeln(isGerman ? '## Auf einen Blick' : '## At a Glance');
    buffer.writeln();

    if (isGerman) {
      buffer.writeln('| Status | Anzahl |');
      buffer.writeln('| :---- | :---- |');
      buffer.writeln('| Bewerbungen gesamt | ${stats['total']} |');
      buffer.writeln('| Aktive Bewerbungen | ${stats['active']} |');
      buffer.writeln('| Abgelehnt | ${stats['rejected']} |');
      buffer.writeln('| Keine Antwort | ${stats['noResponse']} |');
      buffer.writeln(
          '| *Vorstellungsgespräche bisher* | *${stats['interviewCount']}* |');
    } else {
      buffer.writeln('| Status | Count |');
      buffer.writeln('| :---- | :---- |');
      buffer.writeln('| Total applications | ${stats['total']} |');
      buffer.writeln('| Active applications | ${stats['active']} |');
      buffer.writeln('| Rejected | ${stats['rejected']} |');
      buffer.writeln('| No response | ${stats['noResponse']} |');
      buffer.writeln('| *Interviews so far* | *${stats['interviewCount']}* |');
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

    // ── Currently interviewing ────────────────────────────────────────────────
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
          ? '### Warten auf Antwort (${awaiting.length})'
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
        final days = _daysBetween(app.applicationDate, outcomeDate);

        // Annotate with interview date when the application reached that stage
        final interviewDate = _getInterviewDate(app);
        final rejCell = interviewDate != null
            ? isGerman
                ? '${_fmtDate(outcomeDate)} *(Vorstellungsgespräch am ${_fmtDate(interviewDate)})*'
                : '${_fmtDate(outcomeDate)} *(Interview on ${_fmtDate(interviewDate)})*'
            : _fmtDate(outcomeDate);

        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | $rejCell | $days |');
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
    return '${to.difference(from).inDays}d';
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

  /// Date of the first interviewing status entry, or the legacy interviewDate field.
  /// Returns null if the application never reached the interviewing stage.
  static DateTime? _getInterviewDate(JobApplication app) {
    for (final entry in app.chronologicalStatusHistory) {
      if (entry.status == ApplicationStatus.interviewing) return entry.changedAt;
    }
    return app.interviewDate;
  }

  /// True if the application ever reached the interviewing stage.
  static bool _hadInterview(JobApplication app) =>
      app.status == ApplicationStatus.interviewing ||
      app.safeStatusHistory
          .any((c) => c.status == ApplicationStatus.interviewing);

  // ===========================================================================
  // STATISTICS & GROUPING
  // ===========================================================================

  static Map<String, dynamic> _calculateStatistics(
      List<JobApplication> applications) {
    final total = applications.length;
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

    // Active = submitted applications still in play (drafts excluded)
    final active = applied + interviewing;

    // Count every application that ever reached the interviewing stage
    final interviewCount =
        applications.where(_hadInterview).length;

    return {
      'total': total,
      'applied': applied,
      'interviewing': interviewing,
      'successful': successful,
      'rejected': rejected,
      'noResponse': noResponse,
      'active': active,
      'interviewCount': interviewCount,
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
