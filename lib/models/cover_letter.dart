import '../constants/app_constants.dart';

/// Model representing a cover letter
class CoverLetter {
  CoverLetter({
    required this.id,
    required this.name,
    this.language = DocumentLanguage.en,
    this.recipientName,
    this.recipientTitle,
    this.companyName,
    this.jobTitle,
    this.greeting = 'Dear Hiring Manager,',
    this.body = '',
    this.closing = 'Kind regards,',
    this.senderName,
    this.placeholders = const {},
    this.lastModified,
  });

  factory CoverLetter.fromJson(Map<String, dynamic> json) {
    return CoverLetter(
      id: json['id'] as String,
      name: json['name'] as String,
      language: DocumentLanguage.values.firstWhere(
        (l) => l.code == json['language'],
        orElse: () => DocumentLanguage.en,
      ),
      recipientName: json['recipientName'] as String?,
      recipientTitle: json['recipientTitle'] as String?,
      companyName: json['companyName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      greeting: json['greeting'] as String? ?? 'Dear Hiring Manager,',
      body: json['body'] as String? ?? '',
      closing: json['closing'] as String? ?? 'Kind regards,',
      senderName: json['senderName'] as String?,
      placeholders: (json['placeholders'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  final String id;
  final String name;
  final DocumentLanguage language;
  final String? recipientName;
  final String? recipientTitle;
  final String? companyName;
  final String? jobTitle;
  final String greeting;
  final String body;
  final String closing;
  final String? senderName;
  final Map<String, String> placeholders;
  final DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language.code,
        'recipientName': recipientName,
        'recipientTitle': recipientTitle,
        'companyName': companyName,
        'jobTitle': jobTitle,
        'greeting': greeting,
        'body': body,
        'closing': closing,
        'senderName': senderName,
        'placeholders': placeholders,
        'lastModified': lastModified?.toIso8601String(),
      };

  CoverLetter copyWith({
    String? id,
    String? name,
    DocumentLanguage? language,
    String? recipientName,
    String? recipientTitle,
    String? companyName,
    String? jobTitle,
    String? greeting,
    String? body,
    String? closing,
    String? senderName,
    Map<String, String>? placeholders,
    DateTime? lastModified,
  }) {
    return CoverLetter(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      recipientName: recipientName ?? this.recipientName,
      recipientTitle: recipientTitle ?? this.recipientTitle,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      greeting: greeting ?? this.greeting,
      body: body ?? this.body,
      closing: closing ?? this.closing,
      senderName: senderName ?? this.senderName,
      placeholders: placeholders ?? this.placeholders,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Process the body text by replacing placeholders with actual values
  /// Placeholders use the format ==PLACEHOLDER_NAME==
  String get processedBody {
    var result = body;
    for (final entry in placeholders.entries) {
      result = result.replaceAll('==${entry.key}==', entry.value);
    }
    return result;
  }

  /// Extract placeholder names from the body text
  List<String> get extractedPlaceholders {
    final regex = RegExp(r'==([A-Za-z0-9_]+)==');
    return regex.allMatches(body).map((m) => m.group(1)!).toSet().toList();
  }

  /// Create a sample cover letter for testing/preview
  static CoverLetter createSample() {
    return CoverLetter(
      id: 'sample',
      name: 'Sample Cover Letter',
      language: DocumentLanguage.en,
      recipientName: 'Hiring Manager',
      companyName: 'Tech Corp',
      jobTitle: 'Senior Developer',
      greeting: 'Dear Hiring Manager,',
      body:
          '''I am writing to express my strong interest in the ==POSITION== position at ==COMPANY==. With over 10 years of experience in software development and a proven track record of delivering high-quality solutions, I am confident that I would be a valuable addition to your team.

In my current role, I have led multiple projects from conception to deployment, consistently meeting deadlines and exceeding expectations. My expertise in modern technologies and methodologies aligns well with the requirements outlined in your job posting.

I am particularly drawn to ==COMPANY== because of your commitment to innovation and your impact on the industry. I believe my skills and experience would enable me to contribute meaningfully to your continued success.

I would welcome the opportunity to discuss how my background, skills, and enthusiasm can benefit your organization.''',
      closing: 'Kind regards,',
      senderName: 'John Doe',
      placeholders: {
        'POSITION': 'Senior Developer',
        'COMPANY': 'Tech Corp',
      },
      lastModified: DateTime.now(),
    );
  }
}
