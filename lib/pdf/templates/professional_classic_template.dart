import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../core/base_template.dart';
import '../core/template_metadata.dart';
import '../cv_templates/professional_cv_template.dart';
import '../cover_letter_templates/professional_cover_letter_template.dart';

/// Professional Classic CV Template
///
/// Traditional single-column layout with elegant typography and timeless design.
/// Perfect for conservative industries and formal applications.
class ProfessionalClassicCvTemplate implements CvTemplate {
  const ProfessionalClassicCvTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'professional_classic',
        displayName: 'Professional Classic',
        description: 'Traditional single-column layout with elegant typography and formal structure',
        category: TemplateCategory.traditional,
        primaryColor: Color(0xFF1E3A5F), // Navy blue
        accentColor: Color(0xFF2563EB), // Bright blue
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Single-column layout',
          'Traditional typography',
          'Clean section dividers',
          'Professional formatting',
        ],
        tags: ['professional', 'traditional', 'classic', 'formal', 'business'],
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
    ProfessionalCvTemplate.build(pdf, cvData, style, profileImageBytes: profileImageBytes);
  }

  @override
  bool canHandle(CvData cvData) {
    // Professional template can handle any valid CV data
    return cvData.contactDetails != null;
  }

  @override
  TemplateStyle get recommendedStyle => TemplateStyle.professional;
}

/// Professional Classic Cover Letter Template
class ProfessionalClassicCoverLetterTemplate implements CoverLetterTemplate {
  const ProfessionalClassicCoverLetterTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'professional_classic',
        displayName: 'Professional Classic',
        description: 'Formal business letter format with traditional structure',
        category: TemplateCategory.traditional,
        primaryColor: Color(0xFF1E3A5F),
        accentColor: Color(0xFF2563EB),
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Formal letter structure',
          'Traditional typography',
          'Professional header',
        ],
        tags: ['professional', 'traditional', 'formal', 'business'],
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
    ProfessionalCoverLetterTemplate.build(
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
  TemplateStyle get recommendedStyle => TemplateStyle.professional;
}
