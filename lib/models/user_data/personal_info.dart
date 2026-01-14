import 'package:uuid/uuid.dart';

/// Personal information model for user profile
class PersonalInfo {
  final String id;
  final String fullName;
  final String? jobTitle;
  final String? profilePicturePath;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? linkedin;
  final String? website;
  final DateTime createdAt;
  final DateTime? lastModified;

  PersonalInfo({
    String? id,
    required this.fullName,
    this.jobTitle,
    this.profilePicturePath,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.linkedin,
    this.website,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Check if profile picture exists
  bool get hasProfilePicture =>
      profilePicturePath != null && profilePicturePath!.isNotEmpty;

  PersonalInfo copyWith({
    String? fullName,
    String? jobTitle,
    String? profilePicturePath,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? linkedin,
    String? website,
    DateTime? lastModified,
  }) {
    return PersonalInfo(
      id: id,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'jobTitle': jobTitle,
      'profilePicturePath': profilePicturePath,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'linkedin': linkedin,
      'website': website,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      jobTitle: json['jobTitle'] as String?,
      profilePicturePath: json['profilePicturePath'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      linkedin: json['linkedin'] as String?,
      website: json['website'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}
