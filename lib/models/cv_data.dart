import '../constants/app_constants.dart';

/// Model representing CV/Resume data
class CvData {
  CvData({
    required this.id,
    required this.name,
    this.language = DocumentLanguage.en,
    this.profile = '',
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.contactDetails,
    this.experiences = const [],
    this.education = const [],
    this.lastModified,
  });

  factory CvData.fromJson(Map<String, dynamic> json) {
    return CvData(
      id: json['id'] as String,
      name: json['name'] as String,
      language: DocumentLanguage.values.firstWhere(
        (l) => l.code == json['language'],
        orElse: () => DocumentLanguage.en,
      ),
      profile: json['profile'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((l) => LanguageSkill.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      contactDetails: json['contactDetails'] != null
          ? ContactDetails.fromJson(
              json['contactDetails'] as Map<String, dynamic>)
          : null,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  final String id;
  final String name;
  final DocumentLanguage language;
  final String profile;
  final List<String> skills;
  final List<LanguageSkill> languages;
  final List<String> interests;
  final ContactDetails? contactDetails;
  final List<Experience> experiences;
  final List<Education> education;
  final DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language.code,
        'profile': profile,
        'skills': skills,
        'languages': languages.map((l) => l.toJson()).toList(),
        'interests': interests,
        'contactDetails': contactDetails?.toJson(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'lastModified': lastModified?.toIso8601String(),
      };

  CvData copyWith({
    String? id,
    String? name,
    DocumentLanguage? language,
    String? profile,
    List<String>? skills,
    List<LanguageSkill>? languages,
    List<String>? interests,
    ContactDetails? contactDetails,
    List<Experience>? experiences,
    List<Education>? education,
    DateTime? lastModified,
  }) {
    return CvData(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      profile: profile ?? this.profile,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      contactDetails: contactDetails ?? this.contactDetails,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Create a sample CV for testing/preview
  static CvData createSample() {
    return CvData(
      id: 'sample',
      name: 'Sample CV',
      language: DocumentLanguage.en,
      profile:
          'Experienced professional with over 10 years in the industry. Strong background in project management, team leadership, and strategic planning.',
      skills: [
        'Project Management',
        'Team Leadership',
        'Strategic Planning',
        'Communication',
        'Problem Solving',
      ],
      languages: [
        LanguageSkill(language: 'English', level: 'Native'),
        LanguageSkill(language: 'German', level: 'Fluent'),
        LanguageSkill(language: 'French', level: 'Basic'),
      ],
      interests: ['Technology', 'Innovation', 'Travel', 'Photography'],
      contactDetails: ContactDetails(
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+1 234 567 890',
        address: '123 Main Street, City, Country',
        linkedin: 'linkedin.com/in/johndoe',
      ),
      experiences: [
        Experience(
          company: 'Tech Corp',
          title: 'Senior Manager',
          startDate: 'Jan 2020',
          endDate: 'Present',
          description: 'Leading a team of 15 professionals',
          bullets: [
            'Increased team productivity by 40%',
            'Implemented new project management systems',
            'Managed annual budget of \$2M',
          ],
        ),
        Experience(
          company: 'StartUp Inc',
          title: 'Project Lead',
          startDate: 'Jun 2017',
          endDate: 'Dec 2019',
          description: 'Led product development initiatives',
          bullets: [
            'Launched 3 successful products',
            'Built and managed cross-functional teams',
          ],
        ),
      ],
      education: [
        Education(
          institution: 'University of Technology',
          degree: 'Master of Business Administration',
          startDate: '2015',
          endDate: '2017',
        ),
        Education(
          institution: 'State University',
          degree: 'Bachelor of Science in Computer Science',
          startDate: '2011',
          endDate: '2015',
        ),
      ],
      lastModified: DateTime.now(),
    );
  }
}

/// Contact details for CV
class ContactDetails {
  ContactDetails({
    required this.fullName,
    this.email,
    this.phone,
    this.address,
    this.linkedin,
    this.website,
  });

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      linkedin: json['linkedin'] as String?,
      website: json['website'] as String?,
    );
  }

  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? linkedin;
  final String? website;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'linkedin': linkedin,
        'website': website,
      };

  ContactDetails copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? linkedin,
    String? website,
  }) {
    return ContactDetails(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
    );
  }
}

/// Language skill entry
class LanguageSkill {
  LanguageSkill({
    required this.language,
    required this.level,
  });

  factory LanguageSkill.fromJson(Map<String, dynamic> json) {
    return LanguageSkill(
      language: json['language'] as String,
      level: json['level'] as String,
    );
  }

  final String language;
  final String level;

  Map<String, dynamic> toJson() => {
        'language': language,
        'level': level,
      };
}

/// Work experience entry
class Experience {
  Experience({
    required this.company,
    required this.title,
    required this.startDate,
    this.endDate,
    this.description,
    this.bullets = const [],
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      company: json['company'] as String,
      title: json['title'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      description: json['description'] as String?,
      bullets: (json['bullets'] as List<dynamic>?)
              ?.map((b) => b as String)
              .toList() ??
          [],
    );
  }

  final String company;
  final String title;
  final String startDate;
  final String? endDate;
  final String? description;
  final List<String> bullets;

  Map<String, dynamic> toJson() => {
        'company': company,
        'title': title,
        'startDate': startDate,
        'endDate': endDate,
        'description': description,
        'bullets': bullets,
      };

  String get dateRange => endDate != null ? '$startDate - $endDate' : startDate;
}

/// Education entry
class Education {
  Education({
    required this.institution,
    required this.degree,
    required this.startDate,
    this.endDate,
    this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] as String,
      degree: json['degree'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      description: json['description'] as String?,
    );
  }

  final String institution;
  final String degree;
  final String startDate;
  final String? endDate;
  final String? description;

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degree': degree,
        'startDate': startDate,
        'endDate': endDate,
        'description': description,
      };

  String get dateRange => endDate != null ? '$startDate - $endDate' : startDate;
}
