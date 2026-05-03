import 'package:intl/intl.dart';
import '../models/notes_data.dart';

/// Service for exporting notes as nicely formatted markdown.
/// Each note type gets a purpose-built layout.
class NoteExportService {
  /// Generate markdown for a single note in the given language.
  /// [linkedApplicationName] is the resolved "Company — Position" string
  /// for interview cheat sheets (caller resolves it from ApplicationsProvider).
  static String generateMarkdown({
    required NoteItem note,
    required bool isGerman,
    String? linkedApplicationName,
  }) {
    switch (note.type) {
      case NoteType.interviewCheatSheet:
        return _generateCheatSheet(note, isGerman, linkedApplicationName);
      case NoteType.companyLead:
        return _generateCompanyLead(note, isGerman);
      case NoteType.reminder:
        return _generateReminder(note, isGerman);
      case NoteType.todo:
        return _generateTodo(note, isGerman);
      case NoteType.generalNote:
        return _generateGeneralNote(note, isGerman);
    }
  }

  // ── Interview Cheat Sheet ────────────────────────────────────────────
  // Designed as a printable quick-reference for interview prep.

  static String _generateCheatSheet(
      NoteItem note, bool isGerman, String? linkedAppName) {
    final buf = StringBuffer();

    // Title
    buf.writeln(isGerman
        ? '# Interview-Vorbereitung: ${note.title}'
        : '# Interview Prep: ${note.title}');
    buf.writeln();

    // Prominent header block with the three key facts
    buf.writeln('> ${isGerman ? '**Erstellt:** ' : '**Created:** '}'
        '${_fmtDate(note.createdAt, isGerman)}');
    if (linkedAppName != null) {
      buf.writeln(
          '> ${isGerman ? '**Bewerbung:** ' : '**Application:** '}$linkedAppName');
    }
    if (note.interviewDate != null) {
      final dateLine =
          '${isGerman ? '**Interviewtermin:** ' : '**Interview:** '}'
          '${_fmtDate(note.interviewDate!, isGerman)}'
          ' — ${_interviewCountdown(note.interviewDate!, isGerman)}';
      buf.writeln('> $dateLine');
    }
    if (note.salaryExpectation != null && note.salaryExpectation!.isNotEmpty) {
      buf.writeln(
          '> ${isGerman ? '**Gehaltsvorstellung:** ' : '**Salary:** '}'
          '${note.salaryExpectation}');
    }
    buf.writeln();
    buf.writeln('---');
    buf.writeln();

    // Content sections — each only rendered if filled
    _writeSection(buf, isGerman ? 'Unternehmenshintergrund' : 'Company Background',
        note.companyBackground);
    _writeSection(buf, isGerman ? 'Warum ich gut passe' : 'Why I\'m a Good Fit',
        note.whyGoodFit);
    _writeSection(buf, isGerman ? 'Meine Stärken' : 'My Strengths',
        note.strengths);
    _writeSection(buf, isGerman ? 'Fragen an das Unternehmen' : 'Questions to Ask',
        note.questionsToAsk);
    _writeSection(buf, isGerman ? 'Recherche-Notizen' : 'Research Notes',
        note.researchNotes);
    _writeSection(buf, isGerman ? 'Zusätzliche Notizen' : 'Additional Notes',
        note.description);

    _writeTags(buf, note.tags);
    _writeFooter(buf, isGerman);
    return buf.toString();
  }

  // ── Company Lead ─────────────────────────────────────────────────────

  static String _generateCompanyLead(NoteItem note, bool isGerman) {
    final buf = StringBuffer();

    buf.writeln('# ${note.title}');
    buf.writeln();

    // Compact metadata line
    _writeMetaLine(buf, note, isGerman);

    // Lead status
    if (note.leadStatus != null) {
      final statusLabel = isGerman
          ? _getLeadStatusLabelDe(note.leadStatus!)
          : _getLeadStatusLabel(note.leadStatus!);
      buf.writeln(
          '**${isGerman ? 'Lead-Status' : 'Lead Status'}:** $statusLabel');
      buf.writeln();
    }

    // Contact details — compact list
    final details = <String>[];
    if (note.location != null && note.location!.isNotEmpty) {
      details.add(
          '**${isGerman ? 'Standort' : 'Location'}:** ${note.location}');
    }
    if (note.url != null && note.url!.isNotEmpty) {
      details.add(
          '**${isGerman ? 'Webseite' : 'Website'}:** <${note.url}>');
    }
    if (note.contactPerson != null && note.contactPerson!.isNotEmpty) {
      details.add(
          '**${isGerman ? 'Ansprechpartner' : 'Contact'}:** ${note.contactPerson}');
    }
    if (note.contactEmail != null && note.contactEmail!.isNotEmpty) {
      details.add(
          '**${isGerman ? 'E-Mail' : 'Email'}:** <${note.contactEmail}>');
    }
    if (details.isNotEmpty) {
      for (final d in details) {
        buf.writeln(d);
      }
      buf.writeln();
    }

    _writeSection(buf, isGerman ? 'Warum interessant?' : 'Why Interesting?',
        note.description);
    _writeTags(buf, note.tags);
    _writeFooter(buf, isGerman);
    return buf.toString();
  }

  // ── Reminder ─────────────────────────────────────────────────────────

  static String _generateReminder(NoteItem note, bool isGerman) {
    final buf = StringBuffer();

    buf.writeln('# ${note.title}');
    buf.writeln();
    _writeMetaLine(buf, note, isGerman);

    if (note.dueDate != null) {
      buf.writeln(
          '**${isGerman ? 'Fällig' : 'Due'}:** ${_fmtDate(note.dueDate!, isGerman)}');
      if (!note.completed) {
        final countdown = _dueDateCountdown(note.dueDate!, isGerman);
        buf.writeln('> $countdown');
      }
      buf.writeln();
    }

    _writeSection(buf, isGerman ? 'Details' : 'Details', note.description);
    _writeTags(buf, note.tags);
    _writeFooter(buf, isGerman);
    return buf.toString();
  }

  // ── To-Do ────────────────────────────────────────────────────────────

  static String _generateTodo(NoteItem note, bool isGerman) {
    final buf = StringBuffer();

    final checkbox = note.completed ? '[x]' : '[ ]';
    buf.writeln('# $checkbox ${note.title}');
    buf.writeln();
    _writeMetaLine(buf, note, isGerman);

    if (note.dueDate != null) {
      buf.writeln(
          '**${isGerman ? 'Fällig' : 'Due'}:** ${_fmtDate(note.dueDate!, isGerman)}');
      if (!note.completed) {
        buf.writeln('> ${_dueDateCountdown(note.dueDate!, isGerman)}');
      }
      buf.writeln();
    }

    _writeSection(
        buf, isGerman ? 'Beschreibung' : 'Description', note.description);
    _writeTags(buf, note.tags);
    _writeFooter(buf, isGerman);
    return buf.toString();
  }

  // ── General Note ─────────────────────────────────────────────────────

  static String _generateGeneralNote(NoteItem note, bool isGerman) {
    final buf = StringBuffer();

    buf.writeln('# ${note.title}');
    buf.writeln();
    _writeMetaLine(buf, note, isGerman);

    // For general notes the content is the main attraction — no h2 wrapper
    if (note.description != null && note.description!.isNotEmpty) {
      buf.writeln(_toBulletList(note.description!));
      buf.writeln();
    }

    _writeTags(buf, note.tags);
    _writeFooter(buf, isGerman);
    return buf.toString();
  }

  // ── Shared Helpers ───────────────────────────────────────────────────

  /// Compact one-line metadata (replaces the old 6-row table).
  static void _writeMetaLine(StringBuffer buf, NoteItem note, bool isGerman) {
    final parts = <String>[];

    final priorityIcon = _getPriorityIcon(note.priority);
    final priorityLabel = isGerman
        ? _getPriorityLabelDe(note.priority)
        : _getPriorityLabel(note.priority);
    parts.add('$priorityIcon $priorityLabel');

    parts.add(_getStatusLabel(note, isGerman));

    parts.add(
        '${isGerman ? 'Erstellt' : 'Created'}: ${_fmtDate(note.createdAt, isGerman)}');

    if (note.completedAt != null) {
      parts.add(
          '${isGerman ? 'Erledigt' : 'Completed'}: ${_fmtDate(note.completedAt!, isGerman)}');
    }

    buf.writeln('*${parts.join(' · ')}*');
    buf.writeln();
  }

  /// Write an h2 section with bullet-list formatted content.
  /// Skips entirely if [content] is null or empty.
  static void _writeSection(
      StringBuffer buf, String heading, String? content) {
    if (content == null || content.trim().isEmpty) return;
    buf.writeln('## $heading');
    buf.writeln();
    buf.writeln(_toBulletList(content));
    buf.writeln();
  }

  /// Convert multi-line text to a markdown bullet list.
  /// Single-line text is returned as-is.
  /// Lines already starting with `- ` or `* ` are left untouched.
  static String _toBulletList(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length <= 1) return text.trim();
    return lines.map((l) {
      final trimmed = l.trim();
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) return trimmed;
      return '- $trimmed';
    }).join('\n');
  }

  static void _writeTags(StringBuffer buf, List<String> tags) {
    if (tags.isEmpty) return;
    buf.writeln('## Tags');
    buf.writeln();
    buf.writeln(tags.map((t) => '`$t`').join(' · '));
    buf.writeln();
  }

  static void _writeFooter(StringBuffer buf, bool isGerman) {
    buf.writeln('---');
    buf.writeln();
    buf.writeln(isGerman
        ? '*Exportiert von MyJob — ${_fmtDate(DateTime.now(), true)}*'
        : '*Exported from MyJob — ${_fmtDate(DateTime.now(), false)}*');
  }

  // ── Date Formatting ──────────────────────────────────────────────────

  static String _fmtDate(DateTime date, bool isGerman) {
    return isGerman
        ? DateFormat('dd.MM.yyyy').format(date)
        : DateFormat('MMMM dd, yyyy').format(date);
  }

  static String _interviewCountdown(DateTime interviewDate, bool isGerman) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final intDay = DateTime(
        interviewDate.year, interviewDate.month, interviewDate.day);
    final diff = intDay.difference(today).inDays;

    if (diff < 0) return isGerman ? 'bereits vorbei' : 'already passed';
    if (diff == 0) return isGerman ? '**heute!**' : '**today!**';
    if (diff == 1) return isGerman ? 'morgen' : 'tomorrow';
    return isGerman ? 'in $diff Tagen' : 'in $diff days';
  }

  static String _dueDateCountdown(DateTime dueDate, bool isGerman) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueDay.difference(today).inDays;

    if (diff < 0) {
      return isGerman
          ? '**${-diff} Tage überfällig**'
          : '**${-diff} days overdue**';
    }
    if (diff == 0) return isGerman ? '**Heute fällig**' : '**Due today**';
    return isGerman ? 'Fällig in $diff Tagen' : 'Due in $diff days';
  }

  // ── Label Helpers ────────────────────────────────────────────────────

  static String _getStatusLabel(NoteItem note, bool isGerman) {
    if (note.archived) return isGerman ? '📦 Archiviert' : '📦 Archived';
    if (note.completed) return isGerman ? '✅ Erledigt' : '✅ Completed';
    return isGerman ? '📌 Aktiv' : '📌 Active';
  }

  static String _getPriorityIcon(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return '🔵';
      case NotePriority.medium:
        return '🟡';
      case NotePriority.high:
        return '🟠';
      case NotePriority.urgent:
        return '🔴';
    }
  }

  static String _getPriorityLabel(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return 'Low';
      case NotePriority.medium:
        return 'Medium';
      case NotePriority.high:
        return 'High';
      case NotePriority.urgent:
        return 'Urgent';
    }
  }

  static String _getPriorityLabelDe(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return 'Niedrig';
      case NotePriority.medium:
        return 'Mittel';
      case NotePriority.high:
        return 'Hoch';
      case NotePriority.urgent:
        return 'Dringend';
    }
  }

  static String _getLeadStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.researching:
        return '🔍 Researching';
      case LeadStatus.contacted:
        return '💬 Contacted';
      case LeadStatus.applied:
        return '📤 Applied';
      case LeadStatus.interviewing:
        return '🎯 Interviewing';
    }
  }

  static String _getLeadStatusLabelDe(LeadStatus status) {
    switch (status) {
      case LeadStatus.researching:
        return '🔍 Recherche';
      case LeadStatus.contacted:
        return '💬 Kontaktiert';
      case LeadStatus.applied:
        return '📤 Beworben';
      case LeadStatus.interviewing:
        return '🎯 Im Gespräch';
    }
  }
}
