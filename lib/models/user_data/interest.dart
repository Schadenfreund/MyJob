import 'package:uuid/uuid.dart';

/// Interest/hobby model
class Interest {
  final String id;
  final String name;
  final String? category;
  final DateTime createdAt;
  final DateTime? lastModified;

  Interest({
    String? id,
    required this.name,
    this.category,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Interest copyWith({
    String? name,
    String? category,
    DateTime? lastModified,
  }) {
    return Interest(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}
