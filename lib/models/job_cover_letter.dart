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

  /// Create from default cover letter body with greeting and closing
  factory JobCoverLetter.fromDefault({
    required String defaultBody,
    String? companyName,
    String? subject,
    String defaultGreeting = 'Dear Hiring Manager,',
    String defaultClosing = 'Kind regards,',
  }) {
    return JobCoverLetter(
      companyName: companyName ?? '',
      subject: subject ?? '',
      greeting: defaultGreeting,
      body: defaultBody,
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
