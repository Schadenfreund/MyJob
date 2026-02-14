import 'package:intl/intl.dart';
import '../models/notes_data.dart';

/// Service for exporting a single note as human-readable markdown
/// Supports bilingual (English/German) export following the app's export pattern
class NoteExportService {
  /// Generate English markdown for a single note
  static String generateEnglishMarkdown({required NoteItem note}) {
    return _generateMarkdown(note, isGerman: false);
  }

  /// Generate German markdown for a single note
  static String generateGermanMarkdown({required NoteItem note}) {
    return _generateMarkdown(note, isGerman: true);
  }

  static String _generateMarkdown(NoteItem note, {required bool isGerman}) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# ${note.title}');
    buffer.writeln();
    buffer.writeln(isGerman
        ? '**Exportiert am:** ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}'
        : '**Exported on:** ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Metadata table
    buffer.writeln(isGerman ? '## Übersicht' : '## Overview');
    buffer.writeln();
    buffer.writeln(isGerman ? '| Feld | Wert |' : '| Field | Value |');
    buffer.writeln('|------|------|');
    buffer.writeln(
        '| ${isGerman ? 'Typ' : 'Type'} | ${isGerman ? _getTypeLabelDe(note.type) : _getTypeLabel(note.type)} |');
    final priorityLabel = isGerman
        ? _getPriorityLabelDe(note.priority)
        : _getPriorityLabel(note.priority);
    final priorityIcon = _getPriorityIcon(note.priority);
    buffer.writeln(
        '| ${isGerman ? 'Priorität' : 'Priority'} | $priorityIcon $priorityLabel |');
    buffer.writeln(
        '| ${isGerman ? 'Status' : 'Status'} | ${_getStatusLabel(note, isGerman)} |');
    buffer.writeln(
        '| ${isGerman ? 'Erstellt' : 'Created'} | ${DateFormat(isGerman ? 'dd.MM.yyyy HH:mm' : 'MMMM dd, yyyy HH:mm').format(note.createdAt)} |');

    if (note.dueDate != null) {
      buffer.writeln(
          '| ${isGerman ? 'Fällig' : 'Due'} | ${DateFormat(isGerman ? 'dd.MM.yyyy' : 'MMMM dd, yyyy').format(note.dueDate!)} |');
    }
    if (note.completedAt != null) {
      buffer.writeln(
          '| ${isGerman ? 'Erledigt am' : 'Completed'} | ${DateFormat(isGerman ? 'dd.MM.yyyy HH:mm' : 'MMMM dd, yyyy HH:mm').format(note.completedAt!)} |');
    }

    buffer.writeln();

    // Type-specific details
    switch (note.type) {
      case NoteType.companyLead:
        _writeCompanyLeadDetails(buffer, note, isGerman);
        break;
      case NoteType.reminder:
        _writeReminderDetails(buffer, note, isGerman);
        break;
      case NoteType.todo:
        _writeTodoDetails(buffer, note, isGerman);
        break;
      case NoteType.generalNote:
        _writeGeneralNoteDetails(buffer, note, isGerman);
        break;
    }

    // Tags
    if (note.tags.isNotEmpty) {
      buffer.writeln(isGerman ? '## Tags' : '## Tags');
      buffer.writeln();
      for (final tag in note.tags) {
        buffer.writeln('- `$tag`');
      }
      buffer.writeln();
    }

    // Footer
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(isGerman
        ? '*Exportiert von MyJob - Bewerbungsmanagement*'
        : '*Exported from MyJob - Application Management*');
    buffer.writeln();

    return buffer.toString();
  }

  static void _writeCompanyLeadDetails(
      StringBuffer buffer, NoteItem note, bool isGerman) {
    buffer.writeln(
        isGerman ? '## Firmendetails' : '## Company Details');
    buffer.writeln();

    // Lead status
    if (note.leadStatus != null) {
      final statusLabel = isGerman
          ? _getLeadStatusLabelDe(note.leadStatus!)
          : _getLeadStatusLabel(note.leadStatus!);
      buffer.writeln(
          '**${isGerman ? 'Status' : 'Lead Status'}:** $statusLabel');
      buffer.writeln();
    }

    if (note.location != null && note.location!.isNotEmpty) {
      buffer.writeln(
          '**${isGerman ? 'Standort' : 'Location'}:** ${note.location}');
      buffer.writeln();
    }
    if (note.url != null && note.url!.isNotEmpty) {
      buffer.writeln(
          '**${isGerman ? 'Webseite' : 'Website'}:** <${note.url}>');
      buffer.writeln();
    }
    if (note.contactPerson != null && note.contactPerson!.isNotEmpty) {
      buffer.writeln(
          '**${isGerman ? 'Ansprechpartner' : 'Contact Person'}:** ${note.contactPerson}');
      buffer.writeln();
    }
    if (note.contactEmail != null && note.contactEmail!.isNotEmpty) {
      buffer.writeln(
          '**${isGerman ? 'Kontakt-E-Mail' : 'Contact Email'}:** <${note.contactEmail}>');
      buffer.writeln();
    }

    if (note.description != null && note.description!.isNotEmpty) {
      buffer.writeln(isGerman
          ? '## Warum interessant?'
          : '## Why Interesting?');
      buffer.writeln();
      buffer.writeln(note.description);
      buffer.writeln();
    }
  }

  static void _writeReminderDetails(
      StringBuffer buffer, NoteItem note, bool isGerman) {
    if (note.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(
          note.dueDate!.year, note.dueDate!.month, note.dueDate!.day);
      final diff = dueDay.difference(today).inDays;

      if (!note.completed) {
        if (diff < 0) {
          buffer.writeln(isGerman
              ? '> **${-diff} Tage überfällig**'
              : '> **${-diff} days overdue**');
        } else if (diff == 0) {
          buffer.writeln(
              isGerman ? '> **Heute fällig**' : '> **Due today**');
        } else {
          buffer.writeln(isGerman
              ? '> Fällig in $diff Tagen'
              : '> Due in $diff days');
        }
        buffer.writeln();
      }
    }

    if (note.description != null && note.description!.isNotEmpty) {
      buffer.writeln(isGerman ? '## Details' : '## Details');
      buffer.writeln();
      buffer.writeln(note.description);
      buffer.writeln();
    }
  }

  static void _writeTodoDetails(
      StringBuffer buffer, NoteItem note, bool isGerman) {
    if (note.description != null && note.description!.isNotEmpty) {
      buffer.writeln(
          isGerman ? '## Beschreibung' : '## Description');
      buffer.writeln();
      buffer.writeln(note.description);
      buffer.writeln();
    }
  }

  static void _writeGeneralNoteDetails(
      StringBuffer buffer, NoteItem note, bool isGerman) {
    if (note.description != null && note.description!.isNotEmpty) {
      buffer.writeln(isGerman ? '## Inhalt' : '## Content');
      buffer.writeln();
      buffer.writeln(note.description);
      buffer.writeln();
    }
  }

  static String _getStatusLabel(NoteItem note, bool isGerman) {
    if (note.archived) return isGerman ? 'Archiviert' : 'Archived';
    if (note.completed) return isGerman ? 'Erledigt' : 'Completed';
    return isGerman ? 'Aktiv' : 'Active';
  }

  static String _getTypeLabel(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return 'To-Do';
      case NoteType.companyLead:
        return 'Company Lead';
      case NoteType.generalNote:
        return 'General Note';
      case NoteType.reminder:
        return 'Reminder';
    }
  }

  static String _getTypeLabelDe(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return 'Aufgabe';
      case NoteType.companyLead:
        return 'Firmenkontakt';
      case NoteType.generalNote:
        return 'Allgemeine Notiz';
      case NoteType.reminder:
        return 'Erinnerung';
    }
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
        return 'Researching';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.applied:
        return 'Applied';
      case LeadStatus.interviewing:
        return 'Interviewing';
    }
  }

  static String _getLeadStatusLabelDe(LeadStatus status) {
    switch (status) {
      case LeadStatus.researching:
        return 'Recherche';
      case LeadStatus.contacted:
        return 'Kontaktiert';
      case LeadStatus.applied:
        return 'Beworben';
      case LeadStatus.interviewing:
        return 'Im Gespräch';
    }
  }
}
