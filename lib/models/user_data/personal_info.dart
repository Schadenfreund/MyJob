import 'package:uuid/uuid.dart';

/// Personal information model for user profile
class PersonalInfo {
  final String id;
  final String fullName;
  final String? profileSummary;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final DateTime? lastModified;

  PersonalInfo({
    String? id,
    required this.fullName,
    this.profileSummary,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PersonalInfo copyWith({
    String? fullName,
    String? profileSummary,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    DateTime? lastModified,
  }) {
    return PersonalInfo(
      id: id,
      fullName: fullName ?? this.fullName,
      profileSummary: profileSummary ?? this.profileSummary,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'profileSummary': profileSummary,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      profileSummary: json['profileSummary'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}
