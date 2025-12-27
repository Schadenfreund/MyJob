import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../core/base_template.dart';
import '../core/template_metadata.dart';
import '../cv_templates/modern_cv_template.dart';
import '../cover_letter_templates/modern_cover_letter_template.dart';

/// Modern Sidebar CV Template
///
/// Contemporary two-column layout with colored sidebar for contact and skills.
/// Features skill bars, profile photo support, and modern design elements.
class ModernSidebarCvTemplate implements CvTemplate {
  const ModernSidebarCvTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'modern_sidebar',
        displayName: 'Modern Sidebar',
        description: 'Contemporary two-column layout with colored sidebar and skill visualization',
        category: TemplateCategory.modern,
        primaryColor: Color(0xFF0F766E), // Teal
        accentColor: Color(0xFF14B8A6), // Bright teal
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Two-column layout',
          'Colored sidebar',
          'Skill bars with proficiency',
          'Profile photo support',
          'Timeline dots',
          'Modern typography',
        ],
        tags: ['modern', 'sidebar', 'two-column', 'colorful', 'contemporary'],
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
    ModernCvTemplate.build(pdf, cvData, style, profileImageBytes: profileImageBytes);
  }

  @override
  bool canHandle(CvData cvData) {
    return cvData.contactDetails != null;
  }

  @override
  TemplateStyle get recommendedStyle => TemplateStyle.modern;
}

/// Modern Sidebar Cover Letter Template
class ModernSidebarCoverLetterTemplate implements CoverLetterTemplate {
  const ModernSidebarCoverLetterTemplate();

  @override
  TemplateMetadata get metadata => const TemplateMetadata(
        id: 'modern_sidebar',
        displayName: 'Modern Sidebar',
        description: 'Contemporary business letter with modern styling',
        category: TemplateCategory.modern,
        primaryColor: Color(0xFF0F766E),
        accentColor: Color(0xFF14B8A6),
        author: 'MyLife',
        version: '1.0.0',
        features: [
          'Modern header',
          'Clean typography',
          'Accent dividers',
        ],
        tags: ['modern', 'contemporary', 'professional'],
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
  TemplateStyle get recommendedStyle => TemplateStyle.modern;
}
