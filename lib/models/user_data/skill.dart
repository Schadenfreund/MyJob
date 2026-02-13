import 'package:uuid/uuid.dart';

/// Skill model for user capabilities
class Skill {
  final String id;
  final String name;
  final String? category;
  final SkillLevel? level;
  final DateTime createdAt;
  final DateTime? lastModified;

  Skill({
    String? id,
    required this.name,
    this.category,
    this.level,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Skill copyWith({
    String? name,
    String? category,
    SkillLevel? level,
    DateTime? lastModified,
  }) {
    return Skill(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      level: level ?? this.level,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'level': level?.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      level: json['level'] != null
          ? SkillLevel.values.firstWhere(
              (e) => e.toString() == json['level'],
              orElse: () => SkillLevel.intermediate,
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}

/// Skill proficiency levels
enum SkillLevel {
  beginner,
  intermediate,
  advanced,
  expert;

  String get displayName {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.expert:
        return 'Expert';
    }
  }

  String get localizationKey => 'skill_level_$name';
}
