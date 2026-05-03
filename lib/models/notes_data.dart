import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Sentinel used by NoteItem.copyWith to distinguish "not provided" from null.
const _unset = Object();

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

  // Interview Cheat Sheet fields
  final String? linkedApplicationId;
  final String? salaryExpectation;
  final String? companyBackground;
  final String? whyGoodFit;
  final String? questionsToAsk;
  final String? strengths;
  final String? researchNotes;
  final DateTime? interviewDate;

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
    this.linkedApplicationId,
    this.salaryExpectation,
    this.companyBackground,
    this.whyGoodFit,
    this.questionsToAsk,
    this.strengths,
    this.researchNotes,
    this.interviewDate,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  NoteItem copyWith({
    String? title,
    Object? description = _unset,
    NoteType? type,
    NotePriority? priority,
    bool? completed,
    bool? archived,
    Object? completedAt = _unset,
    Object? dueDate = _unset,
    List<String>? tags,
    int? sortOrder,
    Object? url = _unset,
    Object? contactPerson = _unset,
    Object? contactEmail = _unset,
    Object? location = _unset,
    LeadStatus? leadStatus,
    Object? linkedApplicationId = _unset,
    Object? salaryExpectation = _unset,
    Object? companyBackground = _unset,
    Object? whyGoodFit = _unset,
    Object? questionsToAsk = _unset,
    Object? strengths = _unset,
    Object? researchNotes = _unset,
    Object? interviewDate = _unset,
  }) {
    return NoteItem(
      id: id,
      title: title ?? this.title,
      description: description == _unset ? this.description : description as String?,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      completedAt: completedAt == _unset ? this.completedAt : completedAt as DateTime?,
      dueDate: dueDate == _unset ? this.dueDate : dueDate as DateTime?,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      url: url == _unset ? this.url : url as String?,
      contactPerson: contactPerson == _unset ? this.contactPerson : contactPerson as String?,
      contactEmail: contactEmail == _unset ? this.contactEmail : contactEmail as String?,
      location: location == _unset ? this.location : location as String?,
      leadStatus: leadStatus ?? this.leadStatus,
      linkedApplicationId: linkedApplicationId == _unset ? this.linkedApplicationId : linkedApplicationId as String?,
      salaryExpectation: salaryExpectation == _unset ? this.salaryExpectation : salaryExpectation as String?,
      companyBackground: companyBackground == _unset ? this.companyBackground : companyBackground as String?,
      whyGoodFit: whyGoodFit == _unset ? this.whyGoodFit : whyGoodFit as String?,
      questionsToAsk: questionsToAsk == _unset ? this.questionsToAsk : questionsToAsk as String?,
      strengths: strengths == _unset ? this.strengths : strengths as String?,
      researchNotes: researchNotes == _unset ? this.researchNotes : researchNotes as String?,
      interviewDate: interviewDate == _unset ? this.interviewDate : interviewDate as DateTime?,
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
      'linkedApplicationId': linkedApplicationId,
      'salaryExpectation': salaryExpectation,
      'companyBackground': companyBackground,
      'whyGoodFit': whyGoodFit,
      'questionsToAsk': questionsToAsk,
      'strengths': strengths,
      'researchNotes': researchNotes,
      'interviewDate': interviewDate?.toIso8601String(),
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
      linkedApplicationId: json['linkedApplicationId'] as String?,
      salaryExpectation: json['salaryExpectation'] as String?,
      companyBackground: json['companyBackground'] as String?,
      whyGoodFit: json['whyGoodFit'] as String?,
      questionsToAsk: json['questionsToAsk'] as String?,
      strengths: json['strengths'] as String?,
      researchNotes: json['researchNotes'] as String?,
      interviewDate: json['interviewDate'] != null
          ? DateTime.parse(json['interviewDate'] as String)
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
  interviewCheatSheet,
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
      case NoteType.interviewCheatSheet:
        return 'Interview Cheat Sheet';
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

  IconData get icon {
    switch (this) {
      case LeadStatus.researching:
        return Icons.search;
      case LeadStatus.contacted:
        return Icons.chat_bubble_outline;
      case LeadStatus.applied:
        return Icons.send;
      case LeadStatus.interviewing:
        return Icons.person_search;
    }
  }
}
