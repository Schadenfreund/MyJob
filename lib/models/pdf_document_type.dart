/// Type of PDF document for preset categorization and workflow selection
enum PdfDocumentType {
  cv,
  coverLetter;

  /// Parse from string with safe fallback to CV
  static PdfDocumentType fromString(String? value) {
    if (value == 'coverLetter') return PdfDocumentType.coverLetter;
    return PdfDocumentType.cv;
  }

  /// User-friendly label
  String get label {
    switch (this) {
      case PdfDocumentType.cv:
        return 'Curriculum Vitae';
      case PdfDocumentType.coverLetter:
        return 'Cover Letter';
    }
  }
}
