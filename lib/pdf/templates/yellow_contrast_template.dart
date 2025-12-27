import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../core/base_template.dart';
import '../core/template_metadata.dart';
import '../cv_templates/yellow_cv_template.dart';
import '../cover_letter_templates/yellow_cover_letter_template.dart';

/// Yellow Contrast CV Template - Wrapper for new template system
///
/// This class adapts the existing YellowCvTemplate to the new template interface.
class YellowContrastCvTemplate implements CvTemplate {
  const YellowContrastCvTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'yellow_contrast',
        displayName: 'Yellow Contrast',
        description: 'Bold high-contrast magazine-style layout with electric yellow accents and modern brutalist aesthetic',
        category: TemplateCategory.bold,
        primaryColor: Color(0xFF000000), // Black
        accentColor: Color(0xFFFFFF00), // Electric Yellow
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Magazine-style layout',
          'Overlapping photo banner',
          'Checkbox bullets',
          'Black skill bars with yellow fill',
          'Yellow square bullets',
          'Hexagonal logo',
        ],
        tags: ['bold', 'modern', 'high-contrast', 'yellow', 'magazine', 'creative'],
        supportsProfilePhoto: true,
        twoColumnLayout: true,
      );

  @override
  void build(
    pw.Document pdf,
    CvData cvData,
    TemplateStyle style, {
    Uint8List? profileImageBytes,
  }) {
    // Delegate to existing implementation
    YellowCvTemplate.build(pdf, cvData, style, profileImageBytes: profileImageBytes);
  }

  @override
  bool canHandle(CvData cvData) {
    // Yellow template requires at least basic contact info
    return cvData.contactDetails != null &&
        (cvData.contactDetails!.fullName.isNotEmpty);
  }

  @override
  TemplateStyle get recommendedStyle => TemplateStyle.yellow;
}

/// Yellow Contrast Cover Letter Template - Wrapper for new template system
class YellowContrastCoverLetterTemplate implements CoverLetterTemplate {
  const YellowContrastCoverLetterTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'yellow_contrast',
        displayName: 'Yellow Contrast',
        description: 'Matching cover letter with yellow accents and modern typography',
        category: TemplateCategory.bold,
        primaryColor: Color(0xFF000000),
        accentColor: Color(0xFFFFFF00),
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Yellow circle logo',
          'Yellow square bullets',
          'Accent bars',
          'Professional letter format',
        ],
        tags: ['bold', 'modern', 'yellow', 'professional'],
        supportsProfilePhoto: false,
        twoColumnLayout: false,
      );

  @override
  void build(
    pw.Document pdf,
    CoverLetter coverLetter,
    TemplateStyle style,
    ContactDetails? contactDetails,
  ) {
    // Delegate to existing implementation
    YellowCoverLetterTemplate.build(pdf, coverLetter, style, contactDetails);
  }

  @override
  bool canHandle(CoverLetter coverLetter) {
    // Yellow template requires basic letter fields
    return coverLetter.greeting.isNotEmpty && coverLetter.body.isNotEmpty;
  }

  @override
  TemplateStyle get recommendedStyle => TemplateStyle.yellow;
}
