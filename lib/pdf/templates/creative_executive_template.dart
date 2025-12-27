import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../core/base_template.dart';
import '../core/template_metadata.dart';
import '../cv_templates/executive_cv_template.dart';
import '../cover_letter_templates/modern_cover_letter_template.dart';

/// Creative Executive CV Template
///
/// Bold creative design with unique visual elements and timeline graphics.
/// Ideal for creative industries and portfolio-style CVs.
class CreativeExecutiveCvTemplate implements CvTemplate {
  const CreativeExecutiveCvTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'creative_executive',
        displayName: 'Creative Executive',
        description: 'Bold creative design with timeline graphics and unique visual elements',
        category: TemplateCategory.creative,
        primaryColor: Color(0xFF7C3AED), // Purple
        accentColor: Color(0xFFEC4899), // Pink
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Timeline visualization',
          'Creative graphics',
          'Bold color palette',
          'Unique layout',
        ],
        tags: ['creative', 'bold', 'colorful', 'unique', 'artistic'],
        supportsProfilePhoto: false,
        twoColumnLayout: false,
      );

  @override
  void build(
    pw.Document pdf,
    CvData cvData,
    TemplateStyle style, {
    Uint8List? profileImageBytes,
  }) {
    ExecutiveCvTemplate.build(pdf, cvData, style, profileImageBytes: profileImageBytes);
  }

  @override
  bool canHandle(CvData cvData) {
    return cvData.contactDetails != null;
  }

  @override
  TemplateStyle get recommendedStyle => TemplateStyle.creative;
}

/// Creative Executive Cover Letter Template
class CreativeExecutiveCoverLetterTemplate implements CoverLetterTemplate {
  const CreativeExecutiveCoverLetterTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'creative_executive',
        displayName: 'Creative Executive',
        description: 'Creative cover letter with bold styling',
        category: TemplateCategory.creative,
        primaryColor: Color(0xFF7C3AED),
        accentColor: Color(0xFFEC4899),
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Creative header',
          'Bold colors',
          'Modern styling',
        ],
        tags: ['creative', 'bold', 'colorful'],
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
    // Creative uses modern cover letter template
    ModernCoverLetterTemplate.build(
      pdf,
      coverLetter,
      style,
      senderAddress: contactDetails?.address,
      senderPhone: contactDetails?.phone,
      senderEmail: contactDetails?.email,
    );
  }

  @override
  bool canHandle(CoverLetter coverLetter) {
    return coverLetter.greeting.isNotEmpty && coverLetter.body.isNotEmpty;
  }

  @override
  TemplateStyle get recommendedStyle => TemplateStyle.creative;
}
