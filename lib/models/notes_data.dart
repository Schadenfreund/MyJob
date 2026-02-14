import 'package:uuid/uuid.dart';

/// Represents a single note or todo item
class NoteItem {
  final String id;
  final String title;
  final String? description;
  final NoteType type;
  final NotePriority priority;
  final bool completed;
  final bool archived;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final List<String> tags;
  final int sortOrder;

  // Company Lead fields
  final String? url;
  final String? contactPerson;
  final String? contactEmail;
  final String? location;
  final LeadStatus? leadStatus;

  NoteItem({
    String? id,
    required this.title,
    this.description,
    this.type = NoteType.todo,
    this.priority = NotePriority.medium,
    this.completed = false,
    this.archived = false,
    DateTime? createdAt,
    this.completedAt,
    this.dueDate,
    List<String>? tags,
    this.sortOrder = 0,
    this.url,
    this.contactPerson,
    this.contactEmail,
    this.location,
    this.leadStatus,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  NoteItem copyWith({
    String? title,
    String? description,
    NoteType? type,
    NotePriority? priority,
    bool? completed,
    bool? archived,
    DateTime? completedAt,
    DateTime? dueDate,
    List<String>? tags,
    int? sortOrder,
    String? url,
    String? contactPerson,
    String? contactEmail,
    String? location,
    LeadStatus? leadStatus,
  }) {
    return NoteItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      url: url ?? this.url,
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      location: location ?? this.location,
      leadStatus: leadStatus ?? this.leadStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'completed': completed,
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags,
      'sortOrder': sortOrder,
      'url': url,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'location': location,
      'leadStatus': leadStatus?.name,
    };
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: NoteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NoteType.todo,
      ),
      priority: NotePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotePriority.medium,
      ),
      completed: json['completed'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      sortOrder: json['sortOrder'] as int? ?? 0,
      url: json['url'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactEmail: json['contactEmail'] as String?,
      location: json['location'] as String?,
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.values.firstWhere(
              (e) => e.name == json['leadStatus'],
              orElse: () => LeadStatus.researching,
            )
          : null,
    );
  }
}

/// Type of note
enum NoteType {
  todo,
  companyLead,
  generalNote,
  reminder,
}

/// Priority level
enum NotePriority {
  low,
  medium,
  high,
  urgent,
}

/// Extension for NoteType display
extension NoteTypeExtension on NoteType {
  String get displayName {
    switch (this) {
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

  String get localizationKey => 'note_type_$name';
}

/// Extension for NotePriority display
extension NotePriorityExtension on NotePriority {
  String get displayName {
    switch (this) {
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

  String get localizationKey => 'note_priority_$name';
}

/// Lead status for company leads
enum LeadStatus {
  researching,
  contacted,
  applied,
  interviewing,
}

/// Extension for LeadStatus display
extension LeadStatusExtension on LeadStatus {
  String get displayName {
    switch (this) {
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

  String get localizationKey => 'lead_status_$name';

  String get icon {
    switch (this) {
      case LeadStatus.researching:
        return '🔍';
      case LeadStatus.contacted:
        return '💬';
      case LeadStatus.applied:
        return '📤';
      case LeadStatus.interviewing:
        return '🎯';
    }
  }
}
