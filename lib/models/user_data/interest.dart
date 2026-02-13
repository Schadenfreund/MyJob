import 'package:uuid/uuid.dart';

/// Interest level enum
enum InterestLevel {
  casual,
  moderate,
  passionate;

  String get displayName {
    switch (this) {
      case InterestLevel.casual:
        return 'Casual';
      case InterestLevel.moderate:
        return 'Moderate';
      case InterestLevel.passionate:
        return 'Passionate';
    }
  }

  String get localizationKey => 'interest_level_$name';
}

/// Interest/hobby model
class Interest {
  final String id;
  final String name;
  final String? category;
  final InterestLevel? level;
  final DateTime createdAt;
  final DateTime? lastModified;

  Interest({
    String? id,
    required this.name,
    this.category,
    this.level,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Interest copyWith({
    String? name,
    String? category,
    InterestLevel? level,
    DateTime? lastModified,
  }) {
    return Interest(
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
      'level': level?.name,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Interest.fromJson(Map<String, dynamic> json) {
    InterestLevel? level;
    if (json['level'] != null) {
      try {
        level = InterestLevel.values.firstWhere(
          (e) => e.name == json['level'],
        );
      } catch (_) {
        level = null;
      }
    }

    return Interest(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      level: level,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}
