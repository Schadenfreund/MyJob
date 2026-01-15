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
}
