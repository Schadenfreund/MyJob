import 'package:uuid/uuid.dart';

/// Language proficiency model
class Language {
  final String id;
  final String name;
  final LanguageProficiency proficiency;
  final DateTime createdAt;
  final DateTime? lastModified;

  Language({
    String? id,
    required this.name,
    required this.proficiency,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Language copyWith({
    String? name,
    LanguageProficiency? proficiency,
    DateTime? lastModified,
  }) {
    return Language(
      id: id,
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'proficiency': proficiency.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as String,
      name: json['name'] as String,
      proficiency: LanguageProficiency.values.firstWhere(
        (e) => e.toString() == json['proficiency'],
        orElse: () => LanguageProficiency.intermediate,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}

/// Language proficiency levels
enum LanguageProficiency {
  native,
  fluent,
  advanced,
  intermediate,
  basic;

  String get displayName {
    switch (this) {
      case LanguageProficiency.native:
        return 'Native';
      case LanguageProficiency.fluent:
        return 'Fluent';
      case LanguageProficiency.advanced:
        return 'Advanced';
      case LanguageProficiency.intermediate:
        return 'Intermediate';
      case LanguageProficiency.basic:
        return 'Basic';
    }
  }

  String get localizationKey => 'lang_proficiency_$name';
}
