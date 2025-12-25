import '../constants/app_constants.dart';

/// Model representing a job application
class JobApplication {
  JobApplication({
    required this.id,
    required this.company,
    required this.position,
    this.status = ApplicationStatus.draft,
    this.applicationDate,
    this.lastUpdated,
    this.location,
    this.jobUrl,
    this.contactPerson,
    this.contactEmail,
    this.cvInstanceId,
    this.coverLetterInstanceId,
    this.notes,
    this.salary,
    this.reminders = const [],
  });

  /// Create from JSON
  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as String,
      company: json['company'] as String,
      position: json['position'] as String,
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ApplicationStatus.draft,
      ),
      applicationDate: json['applicationDate'] != null
          ? DateTime.parse(json['applicationDate'] as String)
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      location: json['location'] as String?,
      jobUrl: json['jobUrl'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactEmail: json['contactEmail'] as String?,
      cvInstanceId: (json['cvInstanceId'] ?? json['cvId']) as String?,
      coverLetterInstanceId:
          (json['coverLetterInstanceId'] ?? json['coverLetterId']) as String?,
      notes: json['notes'] as String?,
      salary: json['salary'] as String?,
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((r) => Reminder.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String id;
  final String company;
  final String position;
  final ApplicationStatus status;
  final DateTime? applicationDate;
  final DateTime? lastUpdated;
  final String? location;
  final String? jobUrl;
  final String? contactPerson;
  final String? contactEmail;
  final String? cvInstanceId;
  final String? coverLetterInstanceId;
  final String? notes;
  final String? salary;
  final List<Reminder> reminders;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'position': position,
        'status': status.name,
        'applicationDate': applicationDate?.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
        'location': location,
        'jobUrl': jobUrl,
        'contactPerson': contactPerson,
        'contactEmail': contactEmail,
        'cvInstanceId': cvInstanceId,
        'coverLetterInstanceId': coverLetterInstanceId,
        'notes': notes,
        'salary': salary,
        'reminders': reminders.map((r) => r.toJson()).toList(),
      };

  /// Create a copy with updated fields
  JobApplication copyWith({
    String? id,
    String? company,
    String? position,
    ApplicationStatus? status,
    DateTime? applicationDate,
    DateTime? lastUpdated,
    String? location,
    String? jobUrl,
    String? contactPerson,
    String? contactEmail,
    String? cvInstanceId,
    String? coverLetterInstanceId,
    String? notes,
    String? salary,
    List<Reminder>? reminders,
  }) {
    return JobApplication(
      id: id ?? this.id,
      company: company ?? this.company,
      position: position ?? this.position,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      location: location ?? this.location,
      jobUrl: jobUrl ?? this.jobUrl,
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      cvInstanceId: cvInstanceId ?? this.cvInstanceId,
      coverLetterInstanceId:
          coverLetterInstanceId ?? this.coverLetterInstanceId,
      notes: notes ?? this.notes,
      salary: salary ?? this.salary,
      reminders: reminders ?? this.reminders,
    );
  }
}

/// Model for application reminders
class Reminder {
  Reminder({
    required this.id,
    required this.date,
    required this.message,
    this.isCompleted = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      message: json['message'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  final String id;
  final DateTime date;
  final String message;
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'message': message,
        'isCompleted': isCompleted,
      };

  Reminder copyWith({
    String? id,
    DateTime? date,
    String? message,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id ?? this.id,
      date: date ?? this.date,
      message: message ?? this.message,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
