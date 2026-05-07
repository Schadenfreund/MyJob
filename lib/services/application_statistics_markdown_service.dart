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

    final sortedByDate = applications.toList()
      ..sort((a, b) {
        if (a.applicationDate == null && b.applicationDate == null) return 0;
        if (a.applicationDate == null) return 1;
        if (b.applicationDate == null) return -1;
        return b.applicationDate!.compareTo(a.applicationDate!);
      });

    final interviewing = byStatus[ApplicationStatus.interviewing] ?? [];
    final awaiting = byStatus[ApplicationStatus.applied] ?? []
      ..sort((a, b) =>
          _daysSince(b.applicationDate).compareTo(_daysSince(a.applicationDate)));
    final drafts = byStatus[ApplicationStatus.draft] ?? [];
    final successful = byStatus[ApplicationStatus.successful] ?? [];
    final rejected = byStatus[ApplicationStatus.rejected] ?? [];
    final noResponse = byStatus[ApplicationStatus.noResponse] ?? [];

    _writeHeader(buffer, stats, isGerman);
    _writeAtAGlance(buffer, stats, isGerman);
    _writeActivePipeline(buffer, interviewing, awaiting, drafts, isGerman);
    _writeOutcomes(buffer, successful, rejected, noResponse, isGerman);
    _writeFullLog(buffer, sortedByDate, isGerman);
    _writeStatusTimeline(buffer, sortedByDate, isGerman);

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
      buffer.writeln('|--------|-------:|-------:|');
      buffer.writeln(
          '| Im Gespräch | ${stats['interviewing']} | ${pct(stats['interviewing'] as int)} |');
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
      buffer.writeln();
      buffer.writeln(
          '**Antwortquote:** ${stats['responseRate']}% · **Gesprächsquote:** ${stats['interviewRate']}% · **Erfolgsquote:** ${stats['successRate']}%');
    } else {
      buffer.writeln('| Status | Count | Share |');
      buffer.writeln('|--------|------:|------:|');
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
      buffer.writeln();
      buffer.writeln(
          '**Response rate:** ${stats['responseRate']}% · **Interview rate:** ${stats['interviewRate']}% · **Success rate:** ${stats['successRate']}%');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeActivePipeline(
    StringBuffer buffer,
    List<JobApplication> interviewing,
    List<JobApplication> awaiting,
    List<JobApplication> drafts,
    bool isGerman,
  ) {
    final total = interviewing.length + awaiting.length + drafts.length;
    if (total == 0) return;

    buffer.writeln(isGerman
        ? '## Aktive Bewerbungen ($total)'
        : '## Active Pipeline ($total)');
    buffer.writeln();

    // ── Interviewing ──────────────────────────────────────────────────────────
    if (interviewing.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### Im Gespräch (${interviewing.length})'
          : '### Interviewing (${interviewing.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Tage im Status | Gehalt | Kontakt |'
          : '| Applied | Company | Position | Location | Days in Stage | Salary | Contact |');
      buffer.writeln(
          '|---------|-------------|----------|----------|--------------|--------|---------|');

      for (final app in interviewing) {
        final applied = _fmtDate(app.applicationDate);
        final days = _daysSince(_currentStatusDate(app));
        final salary = _orDash(app.salary);
        final contact = _orDash(app.contactPerson);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | ${days}d | $salary | $contact |');
      }
      buffer.writeln();
    }

    // ── Awaiting response ─────────────────────────────────────────────────────
    if (awaiting.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### Wartend auf Antwort (${awaiting.length})'
          : '### Awaiting Response (${awaiting.length})');
      buffer.writeln();
      if (isGerman) {
        buffer.writeln(
            '*Sortiert nach längster Wartezeit. Bewerbungen mit > 14 Tagen ohne Antwort können nachgehakt werden.*');
      } else {
        buffer.writeln(
            '*Sorted by longest wait. Applications with > 14 days without reply may be worth following up.*');
      }
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Wartezeit | Gehalt |'
          : '| Applied | Company | Position | Location | Waiting | Salary |');
      buffer.writeln(
          '|---------|-------------|----------|----------|---------|--------|');

      for (final app in awaiting) {
        final applied = _fmtDate(app.applicationDate);
        final waiting = _daysSince(app.applicationDate);
        final salary = _orDash(app.salary);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | ${waiting}d | $salary |');
      }
      buffer.writeln();
    }

    // ── Drafts ────────────────────────────────────────────────────────────────
    if (drafts.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### Entwürfe (${drafts.length})'
          : '### Drafts (${drafts.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Unternehmen | Position | Standort | Zuletzt bearbeitet |'
          : '| Company | Position | Location | Last Edited |');
      buffer.writeln('|-------------|----------|----------|--------------------|');

      for (final app in drafts) {
        final edited = _fmtDate(app.lastUpdated ?? app.applicationDate);
        buffer.writeln(
            '| ${app.company} | ${app.position} | ${app.location ?? '-'} | $edited |');
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
        : '## Outcomes ($total)');
    buffer.writeln();

    // ── Successful ────────────────────────────────────────────────────────────
    if (successful.isNotEmpty) {
      buffer.writeln(isGerman
          ? '### ✓ Erfolgreich (${successful.length})'
          : '### ✓ Successful (${successful.length})');
      buffer.writeln();
      buffer.writeln(isGerman
          ? '| Beworben | Unternehmen | Position | Standort | Angebot am | Dauer | Gehalt |'
          : '| Applied | Company | Position | Location | Offer Date | Days | Salary |');
      buffer.writeln(
          '|---------|-------------|----------|----------|------------|-------|--------|');

      for (final app in successful) {
        final applied = _fmtDate(app.applicationDate);
        final outcomeDate = _getOutcomeDate(app);
        final offerDate = _fmtDate(outcomeDate);
        final days = _daysBetween(app.applicationDate, outcomeDate);
        final salary = _orDash(app.salary);
        buffer.writeln(
            '| $applied | ${app.company} | ${app.position} | ${app.location ?? '-'} | $offerDate | $days | $salary |');
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

    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeFullLog(
      StringBuffer buffer, List<JobApplication> applications, bool isGerman) {
    buffer.writeln(isGerman
        ? '## Vollständiger Bewerbungslog (${applications.length})'
        : '## Full Application Log (${applications.length})');
    buffer.writeln();
    buffer.writeln(isGerman
        ? 'Alle Bewerbungen chronologisch, neueste zuerst. Notizen und Statusverläufe finden sich im Abschnitt *Statusverlauf* unten.'
        : 'All applications chronologically, most recent first. Notes and status histories are in the *Status History* section below.');
    buffer.writeln();

    if (applications.isEmpty) {
      buffer.writeln(
          isGerman ? '*Keine Bewerbungen vorhanden.*' : '*No applications.*');
      buffer.writeln();
      return;
    }

    buffer.writeln(isGerman
        ? '| Datum | Unternehmen | Position | Standort | Status | Gehalt |'
        : '| Date | Company | Position | Location | Status | Salary |');
    buffer.writeln('|-------|-------------|----------|----------|--------|--------|');

    for (final app in applications) {
      final date = app.applicationDate != null
          ? _fmtDate(app.applicationDate)
          : (isGerman ? 'Entwurf' : 'Draft');
      final status =
          isGerman ? _getStatusLabelDe(app.status) : _getStatusLabel(app.status);
      final salary = app.salary?.isNotEmpty == true
          ? app.salary!.replaceAll('|', '\\|')
          : '-';
      buffer.writeln(
          '| $date | ${app.company} | ${app.position} | ${app.location ?? '-'} | $status | $salary |');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
  }

  static void _writeStatusTimeline(
      StringBuffer buffer, List<JobApplication> applications, bool isGerman) {
    final relevant = applications
        .where((app) =>
            app.status != ApplicationStatus.draft ||
            app.safeStatusHistory.isNotEmpty)
        .toList();

    if (relevant.isEmpty) return;

    buffer.writeln(isGerman ? '## Statusverlauf' : '## Status History');
    buffer.writeln();
    buffer.writeln(isGerman
        ? 'Detaillierter Statusverlauf jeder Bewerbung inkl. Notizen, neueste zuerst.'
        : 'Detailed status progression per application including notes, most recent first.');
    buffer.writeln();

    for (final app in relevant) {
      final statusLabel = isGerman
          ? _getStatusLabelDe(app.status)
          : _getStatusLabel(app.status);
      buffer.writeln('### ${app.company} – ${app.position} ($statusLabel)');
      buffer.writeln();

      // Metadata line
      final meta = <String>[];
      if (app.applicationDate != null) {
        meta.add(isGerman
            ? 'Beworben: ${_fmtDate(app.applicationDate)}'
            : 'Applied: ${_fmtDate(app.applicationDate)}');
      }
      if (app.location?.isNotEmpty == true) {
        meta.add(isGerman ? 'Ort: ${app.location}' : 'Location: ${app.location}');
      }
      if (app.salary?.isNotEmpty == true) {
        meta.add(isGerman ? 'Gehalt: ${app.salary}' : 'Salary: ${app.salary}');
      }
      if (app.contactPerson?.isNotEmpty == true) {
        meta.add(isGerman
            ? 'Kontakt: ${app.contactPerson}'
            : 'Contact: ${app.contactPerson}');
        if (app.contactEmail?.isNotEmpty == true) {
          meta.last += ' (${app.contactEmail})';
        }
      }
      if (meta.isNotEmpty) {
        buffer.writeln(meta.join(' · '));
        buffer.writeln();
      }

      // Notes
      if (app.notes?.isNotEmpty == true) {
        buffer.writeln(isGerman ? '> **Notiz:** ${app.notes}' : '> **Note:** ${app.notes}');
        buffer.writeln();
      }

      // Status history table
      final history = _effectiveHistory(app);
      if (history.isEmpty) {
        buffer.writeln(
            isGerman ? '*Kein Verlauf vorhanden.*' : '*No history available.*');
      } else {
        buffer.writeln(isGerman
            ? '| Datum | Status | Notizen |'
            : '| Date | Status | Notes |');
        buffer.writeln('|-------|--------|---------|');
        for (final entry in history) {
          final date = _fmtDate(entry.changedAt);
          final entryStatus = isGerman
              ? _getStatusLabelDe(entry.status)
              : _getStatusLabel(entry.status);
          final notes = entry.notes?.isNotEmpty == true
              ? entry.notes!.replaceAll('\n', ' ').replaceAll('|', '\\|')
              : '-';
          buffer.writeln('| $date | $entryStatus | $notes |');
        }
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

  static String _orDash(String? value) =>
      value?.isNotEmpty == true ? value! : '-';

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

  /// Returns actual history if present, otherwise synthesises from legacy fields.
  static List<StatusChange> _effectiveHistory(JobApplication app) {
    if (app.safeStatusHistory.isNotEmpty) {
      return app.chronologicalStatusHistory;
    }
    final synthetic = <StatusChange>[];
    final created = app.applicationDate ?? app.lastUpdated;
    if (created != null) {
      synthetic.add(StatusChange(
          status: app.status == ApplicationStatus.draft
              ? ApplicationStatus.draft
              : ApplicationStatus.applied,
          changedAt: created));
    }
    if (app.status != ApplicationStatus.draft &&
        app.status != ApplicationStatus.applied &&
        app.lastUpdated != null) {
      synthetic.add(StatusChange(status: app.status, changedAt: app.lastUpdated!));
    }
    return synthetic;
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

    String rate(num n) =>
        total > 0 ? (n / total * 100).toStringAsFixed(1) : '0.0';

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
      'successRate': rate(successful),
      'responseRate': rate(total - noResponse),
      'interviewRate': rate(interviewing + successful),
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

  static String _getStatusLabel(ApplicationStatus status) => switch (status) {
        ApplicationStatus.draft => 'Draft',
        ApplicationStatus.applied => 'Applied',
        ApplicationStatus.interviewing => 'Interviewing',
        ApplicationStatus.successful => 'Successful',
        ApplicationStatus.rejected => 'Rejected',
        ApplicationStatus.noResponse => 'No Response',
      };

  static String _getStatusLabelDe(ApplicationStatus status) => switch (status) {
        ApplicationStatus.draft => 'Entwurf',
        ApplicationStatus.applied => 'Beworben',
        ApplicationStatus.interviewing => 'Im Gespräch',
        ApplicationStatus.successful => 'Erfolgreich',
        ApplicationStatus.rejected => 'Abgelehnt',
        ApplicationStatus.noResponse => 'Keine Antwort',
      };
}
