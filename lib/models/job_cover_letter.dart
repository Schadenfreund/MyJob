/// Cover letter tailored for a specific job application
class JobCoverLetter {
  JobCoverLetter({
    this.recipientName = '',
    this.recipientTitle = '',
    this.companyName = '',
    this.subject = '',
    this.greeting = '',
    this.body = '',
    this.closing = '',
    this.signature = '',
  });

  /// Create from JSON
  factory JobCoverLetter.fromJson(Map<String, dynamic> json) {
    return JobCoverLetter(
      recipientName: json['recipientName'] as String? ?? '',
      recipientTitle: json['recipientTitle'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      greeting: json['greeting'] as String? ?? '',
      body: json['body'] as String? ?? '',
      closing: json['closing'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
    );
  }

  /// Create from default cover letter body with greeting and closing.
  /// Replaces ==PLACEHOLDER== markers with application data.
  factory JobCoverLetter.fromDefault({
    required String defaultBody,
    String? companyName,
    String? position,
    String? contactFirstName,
    String? contactLastName,
    String? location,
    String? salary,
    String? subject,
    String defaultGreeting = 'Dear Hiring Manager,',
    String defaultClosing = 'Kind regards,',
  }) {
    final contactPerson = [contactFirstName, contactLastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    var body = defaultBody;
    var greeting = defaultGreeting;
    final replacements = {
      'COMPANY': companyName,
      'POSITION': position,
      'RECIPIENT_NAME': contactPerson.isEmpty ? null : contactPerson,
      'CONTACT_FIRST_NAME': contactFirstName,
      'CONTACT_LAST_NAME': contactLastName,
      'LOCATION': location,
      'SALARY': salary,
    };
    for (final entry in replacements.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        body = body.replaceAll('==${entry.key}==', entry.value!);
        greeting = greeting.replaceAll('==${entry.key}==', entry.value!);
      }
    }

    return JobCoverLetter(
      companyName: companyName ?? '',
      subject: subject ?? '',
      greeting: greeting,
      body: body,
      closing: defaultClosing,
      signature: '',
    );
  }

  final String recipientName;
  final String recipientTitle;
  final String companyName;
  final String subject;
  final String greeting;
  final String body;
  final String closing;
  final String signature;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'recipientName': recipientName,
        'recipientTitle': recipientTitle,
        'companyName': companyName,
        'subject': subject,
        'greeting': greeting,
        'body': body,
        'closing': closing,
        'signature': signature,
      };

  /// Create a copy with updated fields
  JobCoverLetter copyWith({
    String? recipientName,
    String? recipientTitle,
    String? companyName,
    String? subject,
    String? greeting,
    String? body,
    String? closing,
    String? signature,
  }) {
    return JobCoverLetter(
      recipientName: recipientName ?? this.recipientName,
      recipientTitle: recipientTitle ?? this.recipientTitle,
      companyName: companyName ?? this.companyName,
      subject: subject ?? this.subject,
      greeting: greeting ?? this.greeting,
      body: body ?? this.body,
      closing: closing ?? this.closing,
      signature: signature ?? this.signature,
    );
  }
}
