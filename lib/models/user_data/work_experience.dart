import 'package:uuid/uuid.dart';

/// Work experience model
class WorkExperience {
  final String id;
  final String company;
  final String position;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? location;
  final List<String> responsibilities;
  final String? description;
  final DateTime createdAt;
  final DateTime? lastModified;

  WorkExperience({
    String? id,
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.location,
    List<String>? responsibilities,
    this.description,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        responsibilities = responsibilities ?? [],
        createdAt = createdAt ?? DateTime.now();

  WorkExperience copyWith({
    String? company,
    String? position,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? location,
    List<String>? responsibilities,
    String? description,
    DateTime? lastModified,
  }) {
    return WorkExperience(
      id: id,
      company: company ?? this.company,
      position: position ?? this.position,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      location: location ?? this.location,
      responsibilities: responsibilities ?? this.responsibilities,
      description: description ?? this.description,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
      'location': location,
      'responsibilities': responsibilities,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'] as String,
      company: json['company'] as String,
      position: json['position'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isCurrent: json['isCurrent'] as bool? ?? false,
      location: json['location'] as String?,
      responsibilities: (json['responsibilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  /// Get formatted date range string
  String get dateRange {
    final startYear = startDate.year;
    if (isCurrent) {
      return '$startYear–present';
    }
    final endYear = endDate?.year ?? DateTime.now().year;
    return '$startYear–$endYear';
  }
}
