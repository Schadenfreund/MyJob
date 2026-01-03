import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../shared/pdf_styling.dart';
import '../shared/base_pdf_template.dart';
import '../shared/cv_translations.dart';
import '../components/components.dart';

/// Professional CV Template - Unified flexible template with multiple layout modes
///
/// Features:
/// - Multiple layout modes (modern, sidebar, traditional, compact)
/// - Component-based architecture
/// - Fully customizable through TemplateCustomization
/// - Professional typography and spacing
/// - Beautiful iconography
class ProfessionalCvTemplate extends BasePdfTemplate<CvData>
    with PdfTemplateHelpers {
  ProfessionalCvTemplate._();
  static final instance = ProfessionalCvTemplate._();

  @override
  TemplateInfo get info => const TemplateInfo(
        id: 'professional_cv',
        name: 'Professional',
        description:
            'Flexible professional template with multiple layout modes',
        category: 'cv',
        previewTags: ['modern', 'professional', 'flexible'],
      );

  @override
  Future<Uint8List> build(
    CvData cv,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
  }) async {
    final pdf = createDocument();
    final fonts = await loadFonts(style);
    final profileImage = getProfileImage(profileImageBytes);
    final showProfile = customization?.showProfilePhoto ?? true;

    final layoutMode = customization?.layoutMode ?? CvLayoutMode.modern;
    final headerStyle =
        _mapHeaderStyle(customization?.headerStyle ?? HeaderStyle.modern);
    final experienceStyle = _mapExperienceStyle(
        customization?.experienceStyle ?? ExperienceStyle.timeline);

    // Check if user wants TRUE two-column layout (single page)
    final useTwoColumn = customization?.useTwoColumnLayout ?? false;

    if (useTwoColumn) {
      // TRUE TWO-COLUMN: Single page with sidebar layout
      // Use the user's customization settings - don't override them
      final s = PdfStyling(style: style, customization: customization);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // Full bleed - handle margins in content
          theme: pw.ThemeData.withFont(
            base: fonts.regular,
            bold: fonts.bold,
            fontFallback: [fonts.regular, fonts.bold, fonts.medium],
          ),
          build: (context) => _buildTwoColumnSinglePageLayout(
            cv,
            s,
            showProfile ? profileImage : null,
            experienceStyle, // Add experience style
          ),
        ),
      );
    } else {
      // STANDARD: Multi-page with selected layout mode
      final s = PdfStyling(style: style, customization: customization);

      pdf.addPage(
        pw.MultiPage(
          pageTheme: PdfPageThemes.standard(
            regularFont: fonts.regular,
            boldFont: fonts.bold,
            mediumFont: fonts.medium,
            styling: s,
          ),
          build: (context) {
            switch (layoutMode) {
              case CvLayoutMode.modern:
                return _buildModernLayout(
                  cv,
                  s,
                  showProfile ? profileImage : null,
                  headerStyle,
                  experienceStyle,
                );

              case CvLayoutMode.sidebar:
                return _buildSidebarLayout(
                  cv,
                  s,
                  showProfile ? profileImage : null,
                  headerStyle,
                  experienceStyle,
                );

              case CvLayoutMode.traditional:
                return _buildTraditionalLayout(
                  cv,
                  s,
                  showProfile ? profileImage : null,
                  headerStyle,
                  experienceStyle,
                );

              case CvLayoutMode.compact:
                return _buildCompactLayout(
                  cv,
                  s,
                  showProfile ? profileImage : null,
                  headerStyle,
                  experienceStyle,
                );
            }
          },
        ),
      );
    }

    return pdf.save();
  }

  // ===========================================================================
  // LAYOUT MODES
  // ===========================================================================

  /// TRUE Two-Column Single-Page Layout
  ///
  /// Creates a professional two-column CV that fills the FULL page:
  /// - Sidebar: Photo, Contact, Skills, Languages, Interests
  /// - Main: Name/Title, Summary, Experience, Education
  ///
  /// Uses Row for reliable two-column rendering with full height.
  pw.Widget _buildTwoColumnSinglePageLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    ExperienceLayout experienceLayout, // Add experience layout parameter
  ) {
    final sidebarRatio = s.customization.sidebarWidthRatio;

    // Full-page container with centered content
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: s.background,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sidebar column - accent background, no padding (photo will be full width)
          pw.Container(
            width: PdfPageFormat.a4.width * sidebarRatio,
            color: s.accent, // Accent background
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.center, // Center sidebar content
              mainAxisSize: pw.MainAxisSize.max,
              children: [
                _buildSidebarColumn(cv, s, profileImage),
              ],
            ),
          ),
          // Accent divider
          pw.Container(
            width: 3,
            color: s.accent,
          ),
          // Main content column - increased top margin
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.only(
                left: s.space4,
                right: s.space4,
                top: s.space6, // Increased top margin
                bottom: s.space4,
              ),
              child: _buildMainColumn(cv, s, experienceLayout),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the sidebar column for two-column layout
  pw.Widget _buildSidebarColumn(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.center, // Center all sidebar content
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Profile photo - FULL WIDTH for all shapes
        if (profileImage != null) ...[
          pw.Container(
            width: double.infinity,
            height: 250, // Increased height
            child: pw.Image(profileImage, fit: pw.BoxFit.cover),
          ),
          pw.SizedBox(height: s.space4),
        ],

        // Add padding for text content
        pw.Padding(
          padding: pw.EdgeInsets.all(s.space3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Contact info - full width
              if (cv.contactDetails != null) ...[
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSidebarSectionHeader('Contact', s),
                      pw.SizedBox(height: s.space2),
                      _buildSidebarContactInfo(cv.contactDetails!, s),
                    ],
                  ),
                ),
                pw.SizedBox(height: s.space4),
              ],

              // Skills - full width
              if (cv.skills.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSidebarSectionHeader('Skills', s),
                      pw.SizedBox(height: s.space2),
                      _buildSidebarSkills(cv.skills, s),
                    ],
                  ),
                ),
                pw.SizedBox(height: s.space4),
              ],

              // Languages - full width
              if (cv.languages.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSidebarSectionHeader('Languages', s),
                      pw.SizedBox(height: s.space2),
                      _buildSidebarLanguages(cv.languages, s),
                    ],
                  ),
                ),
                pw.SizedBox(height: s.space4),
              ],

              // Interests - full width
              if (cv.interests.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSidebarSectionHeader('Interests', s),
                      pw.SizedBox(height: s.space2),
                      _buildSidebarInterests(cv.interests, s),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build sidebar section header
  pw.Widget _buildSidebarSectionHeader(String title, PdfStyling s) {
    // Translate the title
    final translatedTitle =
        CvTranslations.getSectionHeader(title, s.customization.language);
    final displayTitle = s.customization.uppercaseHeaders
        ? translatedTitle.toUpperCase()
        : translatedTitle;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          displayTitle,
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black, // Black for contrast on accent
            letterSpacing: s.letterSpacingWide,
          ),
        ),
        pw.SizedBox(height: s.space1),
        pw.Container(
          width: 30,
          height: 2,
          color: PdfColors.black, // Black underline
        ),
      ],
    );
  }

  /// Build sidebar contact info
  pw.Widget _buildSidebarContactInfo(ContactDetails contact, PdfStyling s) {
    final items = <pw.Widget>[];

    if (contact.email != null && contact.email!.isNotEmpty) {
      items.add(_buildSidebarContactItem(contact.email!, s));
    }
    if (contact.phone != null && contact.phone!.isNotEmpty) {
      items.add(_buildSidebarContactItem(contact.phone!, s));
    }
    if (contact.address != null && contact.address!.isNotEmpty) {
      items.add(_buildSidebarContactItem(contact.address!, s));
    }
    if (contact.website != null && contact.website!.isNotEmpty) {
      items.add(_buildSidebarContactItem(contact.website!, s));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  /// Build a single contact item for sidebar
  pw.Widget _buildSidebarContactItem(String text, PdfStyling s) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: s.space2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: s.fontSizeTiny,
          color: PdfColors.black,
        ),
      ),
    );
  }

  /// Build sidebar skills as compact tags
  pw.Widget _buildSidebarSkills(List<String> skills, PdfStyling s) {
    return pw.Wrap(
      spacing: s.space1,
      runSpacing: s.space1,
      children: skills.take(10).map((skill) {
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: s.space2,
            vertical: s.space1,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            skill,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: PdfColors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build sidebar languages
  pw.Widget _buildSidebarLanguages(
      List<LanguageSkill> languages, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: languages.map((lang) {
        return pw.Padding(
          padding: pw.EdgeInsets.only(bottom: s.space1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                lang.language,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                lang.level,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build sidebar interests
  pw.Widget _buildSidebarInterests(List<String> interests, PdfStyling s) {
    return pw.Wrap(
      spacing: s.space1,
      runSpacing: s.space1,
      children: interests.take(6).map((interest) {
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: s.space2,
            vertical: s.space1,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: PdfColors.black, width: 0.5), // Match skills
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            interest,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: PdfColors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build the main column for two-column layout
  pw.Widget _buildMainColumn(
      CvData cv, PdfStyling s, ExperienceLayout experienceLayout) {
    final contact = cv.contactDetails;
    final language = s.customization.language; // Get language setting

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Name and title header - consistent sizing
        pw.Text(
          (contact?.fullName ?? 'YOUR NAME').toUpperCase(),
          style: pw.TextStyle(
            fontSize: s.fontSizeH2, // Consistent H2 size
            fontWeight: pw.FontWeight.bold,
            color: s.textPrimary,
            letterSpacing: 2,
          ),
        ),
        if (contact?.jobTitle != null) ...[
          pw.SizedBox(height: s.space1),
          pw.Text(
            contact!.jobTitle!,
            style: pw.TextStyle(
              fontSize: s.fontSizeBody, // Consistent body size
              color: s.accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        pw.SizedBox(height: s.space2),
        pw.Container(height: 2, width: 60, color: s.accent),
        pw.SizedBox(height: s.space3),

        // Profile/Summary - consistent sizing
        if (cv.profile.isNotEmpty) ...[
          pw.Text(
            CvTranslations.getSectionHeader('PROFILE', language),
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              fontWeight: pw.FontWeight.bold,
              color: s.accent,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: s.space2),
          pw.Text(
            cv.profile.replaceAll(RegExp(r'[\r\n]+'), ' ').trim(),
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              color: s.textSecondary,
              lineSpacing: 1.3,
            ),
          ),
          pw.SizedBox(height: s.space3),
        ],

        // Experience - Clean, compact, ALL content visible
        if (cv.experiences.isNotEmpty) ...[
          pw.Text(
            CvTranslations.getSectionHeader('EXPERIENCE', language),
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              fontWeight: pw.FontWeight.bold,
              color: s.accent,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: s.space2),
          ...cv.experiences.map((exp) {
            return pw.Container(
              margin: pw.EdgeInsets.only(bottom: s.space2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Title (bold, primary color)
                  pw.Text(
                    exp.title,
                    style: pw.TextStyle(
                      fontSize: s.fontSizeSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: s.textPrimary,
                    ),
                  ),
                  // Company & Date
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        exp.company,
                        style: pw.TextStyle(
                          fontSize: s.fontSizeSmall,
                          color: s.accent,
                        ),
                      ),
                      pw.Text(
                        exp.dateRange,
                        style: pw.TextStyle(
                          fontSize: s.fontSizeSmall,
                          color: s.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Bullets - ALL bullets, compact format
                  if (exp.bullets.isNotEmpty) ...[
                    pw.SizedBox(height: s.space1),
                    ...exp.bullets.map((bullet) {
                      return pw.Padding(
                        padding: pw.EdgeInsets.only(
                          left: s.space2,
                          bottom: s.space1 * 0.5,
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              margin: pw.EdgeInsets.only(top: 3),
                              width: 3,
                              height: 3,
                              decoration: pw.BoxDecoration(
                                color: s.accent,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.SizedBox(width: s.space1),
                            pw.Expanded(
                              child: pw.Text(
                                bullet,
                                style: pw.TextStyle(
                                  fontSize: s.fontSizeTiny,
                                  color: s.textSecondary,
                                  lineSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          }).toList(),
          pw.SizedBox(height: s.space3),
        ],

        // Education - Clean, consistent format
        if (cv.education.isNotEmpty) ...[
          pw.Text(
            CvTranslations.getSectionHeader('EDUCATION', language),
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              fontWeight: pw.FontWeight.bold,
              color: s.accent,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: s.space2),
          ...cv.education.map((edu) {
            return pw.Container(
              margin: pw.EdgeInsets.only(bottom: s.space2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    edu.degree,
                    style: pw.TextStyle(
                      fontSize: s.fontSizeSmall,
                      fontWeight: pw.FontWeight.bold,
                      color: s.textPrimary,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          edu.institution,
                          style: pw.TextStyle(
                            fontSize: s.fontSizeSmall,
                            color: s.textSecondary,
                          ),
                        ),
                      ),
                      pw.Text(
                        edu.dateRange,
                        style: pw.TextStyle(
                          fontSize: s.fontSizeSmall,
                          color: s.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  /// Build main column section header
  pw.Widget _buildMainSectionHeader(String title, PdfStyling s) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 14,
          decoration: pw.BoxDecoration(
            color: s.accent,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: s.space2),
        pw.Text(
          s.customization.uppercaseHeaders ? title.toUpperCase() : title,
          style: pw.TextStyle(
            fontSize: s.fontSizeH3,
            fontWeight: pw.FontWeight.bold,
            color: s.textPrimary,
            letterSpacing: s.letterSpacingWide,
          ),
        ),
      ],
    );
  }

  /// Build compact experience entry for two-column layout
  pw.Widget _buildCompactExperienceEntry(Experience exp, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Title and date on same row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                exp.title,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny,
                  fontWeight: pw.FontWeight.bold,
                  color: s.textPrimary,
                ),
              ),
            ),
            pw.SizedBox(width: s.space2),
            pw.Text(
              exp.dateRange,
              style: pw.TextStyle(
                fontSize: s.fontSizeTiny * 0.9,
                color: s.textSecondary,
              ),
            ),
          ],
        ),
        // Company
        pw.Text(
          exp.company,
          style: pw.TextStyle(
            fontSize: s.fontSizeTiny * 0.9,
            color: s.accent,
          ),
        ),
        // Bullets (max 2, very compact)
        if (exp.bullets.isNotEmpty) ...[
          pw.SizedBox(height: s.space1 * 0.5),
          ...exp.bullets.take(2).map((bullet) {
            return pw.Padding(
              padding: pw.EdgeInsets.only(bottom: s.space1 * 0.5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: pw.EdgeInsets.only(top: 2),
                    width: 3,
                    height: 3,
                    decoration: pw.BoxDecoration(
                      color: s.accent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: s.space1),
                  pw.Expanded(
                    child: pw.Text(
                      bullet,
                      style: pw.TextStyle(
                        fontSize: s.fontSizeTiny * 0.85,
                        color: s.textSecondary,
                        lineSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Build compact education entry for two-column layout
  pw.Widget _buildCompactEducationEntry(Education edu, PdfStyling s) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                edu.degree,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny,
                  fontWeight: pw.FontWeight.bold,
                  color: s.textPrimary,
                ),
              ),
              pw.Text(
                edu.institution,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny * 0.9,
                  color: s.textSecondary,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: s.space2),
        pw.Text(
          edu.dateRange,
          style: pw.TextStyle(
            fontSize: s.fontSizeTiny * 0.9,
            color: s.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Modern layout - Optimized single column with side-by-side skills/interests
  List<pw.Widget> _buildModernLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    HeaderLayout headerLayout,
    ExperienceLayout experienceLayout,
  ) {
    final widgets = <pw.Widget>[];

    // Header with profile rendering based on shape
    widgets.add(
      _buildCustomHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage, // Pass raw image, header will style it
        layout: headerLayout,
      ),
    );

    widgets.add(pw.SizedBox(height: s.sectionGapMinor));

    // Profile section
    if (cv.profile.isNotEmpty) {
      widgets.add(_buildProfileSection(cv, s));
    }

    // Skills and Interests side by side (if both exist)
    if (cv.skills.isNotEmpty && cv.interests.isNotEmpty) {
      widgets.add(_buildSkillsAndInterestsSideBySide(cv, s));
    } else {
      // Skills alone
      if (cv.skills.isNotEmpty) {
        widgets.add(_buildSkillsSection(cv, s, false));
      }
      // Interests alone
      if (cv.interests.isNotEmpty) {
        widgets.add(_buildInterestsSection(cv, s));
      }
    }

    // Languages (before Experience - usually shorter)
    if (cv.languages.isNotEmpty) {
      widgets.add(_buildLanguagesSection(cv, s));
    }

    // Experience
    if (cv.experiences.isNotEmpty) {
      // Only add bottom margin if education follows
      final hasEducation = cv.education.isNotEmpty;
      widgets.add(_buildExperienceSection(cv, s, experienceLayout,
          addBottomMargin: hasEducation));
    }

    // Education (last section - no bottom margin)
    if (cv.education.isNotEmpty) {
      widgets.add(_buildEducationSection(cv, s, false, addBottomMargin: false));
    }

    return widgets;
  }

  /// Compact layout - Maximum information density
  List<pw.Widget> _buildCompactLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    HeaderLayout headerLayout,
    ExperienceLayout experienceLayout,
  ) {
    final widgets = <pw.Widget>[];

    // Header with profile
    widgets.add(
      _buildCustomHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage,
        layout: HeaderLayout.compact,
      ),
    );

    widgets.add(pw.SizedBox(height: s.sectionGapMinor));

    // Profile (if exists)
    if (cv.profile.isNotEmpty) {
      widgets.add(_buildProfileSection(cv, s));
    }

    // Skills, languages, interests in sections
    if (cv.skills.isNotEmpty) {
      widgets.add(_buildSkillsSection(cv, s, true));
    }
    if (cv.languages.isNotEmpty) {
      widgets.add(_buildLanguagesSection(cv, s));
    }
    if (cv.interests.isNotEmpty) {
      widgets.add(_buildInterestsSection(cv, s));
    }

    // Experience
    if (cv.experiences.isNotEmpty) {
      widgets.add(_buildExperienceSection(cv, s, experienceLayout));
    }

    // Education (last section - no bottom margin to prevent blank page)
    if (cv.education.isNotEmpty) {
      widgets.add(_buildEducationSection(cv, s, false, addBottomMargin: false));
    }

    return widgets;
  }

  /// Build custom header with styled profile photo
  pw.Widget _buildCustomHeader({
    required String name,
    String? title,
    required ContactDetails? contact,
    required PdfStyling styling,
    pw.ImageProvider? profileImage,
    required HeaderLayout layout,
  }) {
    // Use HeaderComponent but with our styled profile widget
    // For now, if we have a custom profile photo, we'll build a custom header
    // Otherwise use the standard HeaderComponent

    if (profileImage != null && layout == HeaderLayout.modern) {
      final margins = styling.pageMargins;
      final shape = styling.customization.profilePhotoShape;

      // SQUARE PHOTOS: Magazine-style, flush left corner, full header height
      if (shape == ProfilePhotoShape.square) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              margin: pw.EdgeInsets.only(
                left: -margins.left,
                right: -margins.right,
                top: -margins.top,
              ),
              decoration: pw.BoxDecoration(color: styling.accent),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Square photo - flush left, full height, no border
                  pw.Container(
                    width: 120,
                    height: 120,
                    child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                  ),

                  // Name and title - vertically centered
                  pw.Expanded(
                    child: pw.Padding(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: styling.space5,
                        vertical: styling.space6,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            name.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: styling.fontSizeH1 * 1.3,
                              fontWeight: pw.FontWeight.bold,
                              color: styling.textOnAccent,
                              letterSpacing: 3,
                            ),
                          ),
                          if (title != null && title.isNotEmpty) ...[
                            pw.SizedBox(height: styling.space2),
                            pw.Text(
                              title,
                              style: pw.TextStyle(
                                fontSize: styling.fontSizeH3,
                                color: styling.textOnAccent.flatten(),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: styling.space4),
            if (contact != null) _buildContactRow(contact, styling),
          ],
        );
      }

      // CIRCLE/ROUNDED: Styled with accent border, centered in header
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            margin: pw.EdgeInsets.only(
              left: -margins.left,
              right: -margins.right,
              top: -margins.top,
            ),
            padding: pw.EdgeInsets.symmetric(
              horizontal: margins.left + styling.space4,
              vertical: styling.space6,
            ),
            decoration: pw.BoxDecoration(color: styling.accent),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Styled profile photo with border
                _buildProfilePhoto(profileImage, styling, size: 85),
                pw.SizedBox(width: styling.space5),

                // Name and title
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: styling.fontSizeH1 * 1.3,
                          fontWeight: pw.FontWeight.bold,
                          color: styling.textOnAccent,
                          letterSpacing: 3,
                        ),
                      ),
                      if (title != null && title.isNotEmpty) ...[
                        pw.SizedBox(height: styling.space3),
                        pw.Text(
                          title,
                          style: pw.TextStyle(
                            fontSize: styling.fontSizeH3,
                            color: styling.textOnAccent.flatten(),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: styling.space4),

          // Contact info row
          if (contact != null) _buildContactRow(contact, styling),
        ],
      );
    }

    // CLEAN LAYOUT (Traditional): Right-aligned photo, classic professional look
    if (layout == HeaderLayout.clean && profileImage != null) {
      final photoWidget = _buildProfilePhoto(profileImage, styling, size: 70);

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Name and title on left
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: styling.fontSizeH1,
                        fontWeight: pw.FontWeight.bold,
                        color: styling.textPrimary,
                        letterSpacing: styling.letterSpacingWide,
                      ),
                    ),
                    if (title != null && title.isNotEmpty) ...[
                      pw.SizedBox(height: styling.space2),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: styling.fontSizeH3,
                          color: styling.accent,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: styling.space4),
              // Photo on right
              photoWidget,
            ],
          ),
          pw.SizedBox(height: styling.space3),
          pw.Container(height: 2, width: 80, color: styling.accent),
          if (contact != null) ...[
            pw.SizedBox(height: styling.space3),
            _buildContactRow(contact, styling),
          ],
        ],
      );
    }

    // COMPACT LAYOUT: Top-right photo, maximum space efficiency
    if (layout == HeaderLayout.compact && profileImage != null) {
      final photoWidget = _buildProfilePhoto(profileImage, styling, size: 60);

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Name and title - compact
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: styling.fontSizeH2,
                        fontWeight: pw.FontWeight.bold,
                        color: styling.textPrimary,
                        letterSpacing: styling.letterSpacingWide,
                      ),
                    ),
                    if (title != null && title.isNotEmpty) ...[
                      pw.SizedBox(height: styling.space1),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: styling.fontSizeSmall,
                          color: styling.accent,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: styling.space3),
              // Small photo top-right
              photoWidget,
            ],
          ),
          if (contact != null) ...[
            pw.SizedBox(height: styling.space2),
            _buildContactRow(contact, styling),
          ],
        ],
      );
    }

    // OTHER LAYOUTS (Sidebar, etc) with photo: Centered
    if (profileImage != null) {
      final photoWidget = _buildProfilePhoto(profileImage, styling, size: 80);

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: photoWidget),
          pw.SizedBox(height: styling.space3),
          HeaderComponent.cvHeader(
            name: name,
            title: title,
            contact: contact,
            styling: styling,
            profileImage: null,
            layout: layout,
          ),
        ],
      );
    }

    // No custom photo - use standard HeaderComponent
    return HeaderComponent.cvHeader(
      name: name,
      title: title,
      contact: contact,
      styling: styling,
      profileImage: null,
      layout: layout,
    );
  }

  /// Build contact info row (copied from HeaderComponent for custom header)
  pw.Widget _buildContactRow(ContactDetails contact, PdfStyling styling) {
    final items = <pw.Widget>[];

    if (contact.email != null && contact.email!.isNotEmpty) {
      items.add(
        IconComponent.contact(
          type: 'email',
          text: contact.email!,
          styling: styling,
          size: IconSize.small,
        ),
      );
    }

    if (contact.phone != null && contact.phone!.isNotEmpty) {
      items.add(
        IconComponent.contact(
          type: 'phone',
          text: contact.phone!,
          styling: styling,
          size: IconSize.small,
        ),
      );
    }

    if (contact.address != null && contact.address!.isNotEmpty) {
      items.add(
        IconComponent.contact(
          type: 'location',
          text: contact.address!,
          styling: styling,
          size: IconSize.small,
        ),
      );
    }

    if (contact.website != null && contact.website!.isNotEmpty) {
      items.add(
        IconComponent.contact(
          type: 'web',
          text: contact.website!,
          styling: styling,
          size: IconSize.small,
        ),
      );
    }

    if (contact.linkedin != null && contact.linkedin!.isNotEmpty) {
      items.add(
        IconComponent.contact(
          type: 'linkedin',
          text: contact.linkedin!,
          styling: styling,
          size: IconSize.small,
        ),
      );
    }

    return pw.Wrap(
      alignment: pw.WrapAlignment.start,
      spacing: styling.space4,
      runSpacing: styling.space2,
      children: items,
    );
  }

  /// Sidebar layout - Enhanced single column with sidebar content at top
  ///
  /// Note: True two-column layouts with pw.Table/pw.Row cannot work with
  /// MultiPage as they can't be split across pages (causes TooManyPagesException).
  /// This "sidebar" layout is actually a single column that puts sidebar content
  /// (skills, languages) prominently at the top in a compact horizontal format,
  /// while maintaining MultiPage compatibility.
  List<pw.Widget> _buildSidebarLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    HeaderLayout headerLayout,
    ExperienceLayout experienceLayout,
  ) {
    final widgets = <pw.Widget>[];

    // Header with profile
    widgets.add(
      _buildCustomHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage,
        layout: headerLayout,
      ),
    );

    widgets.add(pw.SizedBox(height: s.sectionGapMinor));

    // Compact info bar with skills, languages, etc.
    widgets.add(_buildSidebarInfoBar(cv, s));

    widgets.add(pw.SizedBox(height: s.sectionGapMajor));

    // Main content sections
    widgets.addAll(_buildMainContentSections(cv, s, experienceLayout));

    return widgets;
  }

  /// Build a compact info bar containing sidebar content (skills, languages, etc.)
  pw.Widget _buildSidebarInfoBar(CvData cv, PdfStyling s) {
    final sections = <pw.Widget>[];

    // Skills as compact tags
    if (cv.skills.isNotEmpty) {
      sections.add(
        _buildCompactSkillsSection(cv.skills, s),
      );
    }

    // Languages as compact list
    if (cv.languages.isNotEmpty) {
      sections.add(
        _buildCompactLanguagesSection(cv.languages, s),
      );
    }

    // Interests as tags
    if (cv.interests.isNotEmpty) {
      sections.add(
        _buildCompactInterestsSection(cv.interests, s),
      );
    }

    if (sections.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(s.space4),
      decoration: pw.BoxDecoration(
        color: s.cardBackground,
        border: pw.Border(
          left: pw.BorderSide(color: s.accent, width: 3),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: _intersperse(sections, pw.SizedBox(height: s.space4)),
      ),
    );
  }

  /// Build compact skills section for sidebar info bar
  pw.Widget _buildCompactSkillsSection(List<String> skills, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          s.customization.uppercaseHeaders ? 'SKILLS' : 'Skills',
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            fontWeight: pw.FontWeight.bold,
            color: s.accent,
          ),
        ),
        pw.SizedBox(height: s.space2),
        pw.Wrap(
          spacing: s.space2,
          runSpacing: s.space2,
          children: skills
              .take(10)
              .map((skill) => pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                        horizontal: s.space2, vertical: s.space1),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: s.accent, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      skill,
                      style: pw.TextStyle(
                          fontSize: s.fontSizeTiny, color: s.textPrimary),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build compact languages section for sidebar info bar
  pw.Widget _buildCompactLanguagesSection(
      List<LanguageSkill> languages, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          s.customization.uppercaseHeaders ? 'LANGUAGES' : 'Languages',
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            fontWeight: pw.FontWeight.bold,
            color: s.accent,
          ),
        ),
        pw.SizedBox(height: s.space2),
        pw.Wrap(
          spacing: s.space4,
          children: languages
              .map((lang) => pw.Text(
                    '${lang.language} (${lang.level})',
                    style: pw.TextStyle(
                        fontSize: s.fontSizeSmall, color: s.textPrimary),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build compact interests section for sidebar info bar
  pw.Widget _buildCompactInterestsSection(
      List<String> interests, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          s.customization.uppercaseHeaders ? 'INTERESTS' : 'Interests',
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            fontWeight: pw.FontWeight.bold,
            color: s.accent,
          ),
        ),
        pw.SizedBox(height: s.space2),
        pw.Wrap(
          spacing: s.space2,
          runSpacing: s.space2,
          children: interests
              .take(8)
              .map((interest) => pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                        horizontal: s.space2, vertical: s.space1),
                    decoration: pw.BoxDecoration(
                      color: s.accent.flatten(),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      interest,
                      style: pw.TextStyle(
                          fontSize: s.fontSizeTiny, color: s.textOnAccent),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build main content sections (experience, education) for sidebar layout
  List<pw.Widget> _buildMainContentSections(
    CvData cv,
    PdfStyling s,
    ExperienceLayout experienceLayout,
  ) {
    final List<pw.Widget> sections = [];

    // Professional Summary (uses 'profile' field from CvData)
    if (cv.profile.isNotEmpty) {
      sections.add(
        SectionComponent.section(
          title: 'Professional Summary',
          styling: s,
          content: pw.Text(
            cv.profile,
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              color: s.textSecondary,
              lineSpacing: s.lineHeightNormal,
            ),
          ),
        ),
      );
    }

    // Experience
    if (cv.experiences.isNotEmpty) {
      sections.add(
        SectionComponent.section(
          title: 'Experience',
          styling: s,
          content: ExperienceComponent.section(
            experiences: cv.experiences,
            styling: s,
            layout: experienceLayout,
          ),
        ),
      );
    }

    // Education
    if (cv.education.isNotEmpty) {
      sections.add(
        SectionComponent.section(
          title: 'Education',
          styling: s,
          content: EducationComponent.section(
            education: cv.education,
            styling: s,
          ),
        ),
      );
    }

    return sections;
  }

  /// Helper to intersperse widgets with separators
  List<pw.Widget> _intersperse(List<pw.Widget> widgets, pw.Widget separator) {
    if (widgets.isEmpty) return widgets;
    final result = <pw.Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }

  /// Traditional layout - Classic single column
  List<pw.Widget> _buildTraditionalLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    HeaderLayout headerLayout,
    ExperienceLayout experienceLayout,
  ) {
    final widgets = <pw.Widget>[];

    // Header with profile
    widgets.add(
      _buildCustomHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage,
        layout: headerLayout == HeaderLayout.modern
            ? HeaderLayout.clean
            : headerLayout,
      ),
    );

    widgets.add(pw.SizedBox(height: s.sectionGapMajor));

    // Sections with list-style experience (no timeline)
    widgets.addAll(
      _buildSectionsInOrder(
        cv,
        s,
        experienceLayout == ExperienceLayout.timeline
            ? ExperienceLayout.list
            : experienceLayout,
      ),
    );

    return widgets;
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  /// Build sections in the order specified by customization
  List<pw.Widget> _buildSectionsInOrder(
    CvData cv,
    PdfStyling s,
    ExperienceLayout experienceLayout, {
    bool isCompact = false,
  }) {
    final sections = <pw.Widget>[];
    final order = _getSectionOrder(s.customization.sectionOrderPreset);

    for (final sectionName in order) {
      switch (sectionName) {
        case 'profile':
          if (cv.profile.isNotEmpty) {
            sections.add(_buildProfileSection(cv, s));
          }
          break;

        case 'skills':
          if (cv.skills.isNotEmpty) {
            sections.add(_buildSkillsSection(cv, s, isCompact));
          }
          break;

        case 'experience':
          if (cv.experiences.isNotEmpty) {
            sections.add(_buildExperienceSection(cv, s, experienceLayout));
          }
          break;

        case 'education':
          if (cv.education.isNotEmpty) {
            sections.add(_buildEducationSection(cv, s, isCompact));
          }
          break;

        case 'languages':
          if (cv.languages.isNotEmpty) {
            sections.add(_buildLanguagesSection(cv, s));
          }
          break;

        case 'interests':
          if (cv.interests.isNotEmpty) {
            sections.add(_buildInterestsSection(cv, s));
          }
          break;
      }
    }

    return sections;
  }

  /// Get section order based on preset
  List<String> _getSectionOrder(SectionOrderPreset preset) {
    switch (preset) {
      case SectionOrderPreset.standard:
        return [
          'profile',
          'skills',
          'experience',
          'education',
          'languages',
          'interests'
        ];

      case SectionOrderPreset.educationFirst:
        return [
          'profile',
          'education',
          'experience',
          'skills',
          'languages',
          'interests'
        ];

      case SectionOrderPreset.skillsFirst:
        return [
          'profile',
          'skills',
          'experience',
          'education',
          'languages',
          'interests'
        ];

      case SectionOrderPreset.experienceFirst:
        return [
          'profile',
          'experience',
          'skills',
          'education',
          'languages',
          'interests'
        ];
    }
  }

  /// Build profile/summary section with improved text spacing
  pw.Widget _buildProfileSection(CvData cv, PdfStyling s) {
    // Normalize whitespace: replace line breaks and multiple spaces with single space
    final normalizedProfile = cv.profile
        .replaceAll(RegExp(r'[\r\n]+'), ' ') // Replace line breaks with space
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single
        .trim();

    return SectionComponent.section(
      title: 'Profile',
      styling: s,
      iconType: 'profile',
      content: pw.Text(
        normalizedProfile,
        style: pw.TextStyle(
          fontSize: s.fontSizeBody,
          color: s.textSecondary,
          lineSpacing: s.lineHeightRelaxed * 1.3, // Relaxed line height
        ),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  /// Build Skills and Interests side by side (50/50 split)
  pw.Widget _buildSkillsAndInterestsSideBySide(CvData cv, PdfStyling s) {
    final sideBySide = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Skills column (50%)
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.only(right: s.space3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                SectionComponent.header(
                  title: 'Skills',
                  styling: s,
                  iconType: 'skills',
                ),
                pw.SizedBox(height: s.space3),
                SkillsComponent.tags(
                  skills: cv.skills,
                  styling: s,
                ),
              ],
            ),
          ),
        ),
        // Interests column (50%)
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.only(left: s.space3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                SectionComponent.header(
                  title: 'Interests',
                  styling: s,
                  iconType: 'star',
                ),
                pw.SizedBox(height: s.space3),
                pw.Wrap(
                  spacing: s.space2,
                  runSpacing: s.space2,
                  children: cv.interests.map((interest) {
                    return pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: s.space3,
                        vertical: s.space2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: s.cardBackground,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        interest,
                        style: pw.TextStyle(
                          fontSize: s.fontSizeSmall,
                          color: s.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // Wrap in Column to add bottom margin
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        sideBySide,
        pw.SizedBox(height: s.sectionGapMajor),
      ],
    );
  }

  /// Build skills section
  pw.Widget _buildSkillsSection(CvData cv, PdfStyling s, bool isCompact) {
    final showProficiency =
        s.customization.showProficiencyBars && s.customization.showSkillLevels;

    pw.Widget skillsContent;
    if (showProficiency && !isCompact) {
      skillsContent = SkillsComponent.bars(
        skills: cv.skills,
        styling: s,
      );
    } else if (isCompact) {
      skillsContent = SkillsComponent.grid(
        skills: cv.skills,
        styling: s,
        columns: 3,
      );
    } else {
      skillsContent = SkillsComponent.tags(
        skills: cv.skills,
        styling: s,
      );
    }

    return SectionComponent.section(
      title: 'Skills',
      styling: s,
      iconType: 'skills',
      content: skillsContent,
    );
  }

  /// Build experience section - header stays with first entry
  pw.Widget _buildExperienceSection(
    CvData cv,
    PdfStyling s,
    ExperienceLayout experienceLayout, {
    bool addBottomMargin = true,
  }) {
    if (cv.experiences.isEmpty) {
      return pw.SizedBox();
    }

    final experiences = cv.experiences;
    final firstExperience = experiences.first;
    final remainingExperiences = experiences.skip(1).toList();

    // Header + first entry together (prevents orphaned header)
    final headerWithFirstEntry = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        SectionComponent.header(
          title: 'Experience',
          styling: s,
          iconType: 'work',
        ),
        pw.SizedBox(height: s.space4),
        ExperienceComponent.entry(
          experience: firstExperience,
          styling: s,
          index: 0,
          total: experiences.length,
          layout: experienceLayout,
        ),
        if (remainingExperiences.isNotEmpty) pw.SizedBox(height: s.itemGap),
      ],
    );

    // Remaining entries
    final remainingEntries = remainingExperiences.asMap().entries.map((entry) {
      final index = entry.key;
      final experience = entry.value;
      final isLast = index == remainingExperiences.length - 1;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          ExperienceComponent.entry(
            experience: experience,
            styling: s,
            index: index + 1, // +1 because we already rendered first
            total: experiences.length,
            layout: experienceLayout,
          ),
          if (!isLast) pw.SizedBox(height: s.itemGap),
        ],
      );
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerWithFirstEntry,
        ...remainingEntries,
        // Only add bottom margin if requested
        if (addBottomMargin) pw.SizedBox(height: s.sectionGapMajor),
      ],
    );
  }

  /// Build education section
  pw.Widget _buildEducationSection(
    CvData cv,
    PdfStyling s,
    bool isCompact, {
    bool addBottomMargin = true,
  }) {
    return SectionComponent.section(
      title: 'Education',
      styling: s,
      iconType: 'school',
      addBottomMargin: addBottomMargin,
      content: EducationComponent.section(
        education: cv.education,
        styling: s,
        style: isCompact ? EducationStyle.compact : EducationStyle.standard,
      ),
    );
  }

  /// Build languages section
  pw.Widget _buildLanguagesSection(CvData cv, PdfStyling s) {
    return SectionComponent.section(
      title: 'Languages',
      styling: s,
      iconType: 'language',
      content: pw.Wrap(
        spacing: s.space3,
        runSpacing: s.space2,
        children: cv.languages.map((lang) {
          return IconComponent.badge(
            iconType: 'language',
            text: '${lang.language} - ${lang.level}',
            styling: s,
            style: BadgeStyle.outlined,
          );
        }).toList(),
      ),
    );
  }

  /// Build interests section
  pw.Widget _buildInterestsSection(CvData cv, PdfStyling s) {
    return SectionComponent.section(
      title: 'Interests',
      styling: s,
      iconType: 'star',
      content: pw.Wrap(
        spacing: s.space2,
        runSpacing: s.space2,
        children: cv.interests.map((interest) {
          return pw.Container(
            padding: pw.EdgeInsets.symmetric(
              horizontal: s.space3,
              vertical: s.space2,
            ),
            decoration: pw.BoxDecoration(
              color: s.cardBackground,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              interest,
              style: pw.TextStyle(
                fontSize: s.fontSizeSmall,
                color: s.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // ENUM MAPPING HELPERS
  // ===========================================================================

  /// Map HeaderStyle (template_customization) to HeaderLayout (component)
  HeaderLayout _mapHeaderStyle(HeaderStyle style) {
    switch (style) {
      case HeaderStyle.modern:
        return HeaderLayout.modern;
      case HeaderStyle.clean:
        return HeaderLayout.clean;
      case HeaderStyle.sidebar:
        return HeaderLayout.sidebar;
      case HeaderStyle.compact:
        return HeaderLayout.compact;
    }
  }

  /// Map ExperienceStyle (template_customization) to ExperienceLayout (component)
  ExperienceLayout _mapExperienceStyle(ExperienceStyle style) {
    switch (style) {
      case ExperienceStyle.timeline:
        return ExperienceLayout.timeline;
      case ExperienceStyle.list:
        return ExperienceLayout.list;
      case ExperienceStyle.cards:
        return ExperienceLayout.cards;
      case ExperienceStyle.compact:
        return ExperienceLayout.compact;
    }
  }

  /// Build profile photo with customizable shape and style
  pw.Widget _buildProfilePhoto(
    pw.ImageProvider image,
    PdfStyling s, {
    double size = 80,
  }) {
    final shape = s.customization.profilePhotoShape;

    // Determine border radius based on shape
    double borderRadius;
    pw.BoxShape? boxShape;
    switch (shape) {
      case ProfilePhotoShape.circle:
        boxShape = pw.BoxShape.circle;
        borderRadius = size / 2;
        break;
      case ProfilePhotoShape.rounded:
        boxShape = pw.BoxShape.rectangle;
        borderRadius = 12;
        break;
      case ProfilePhotoShape.square:
        boxShape = pw.BoxShape.rectangle;
        borderRadius = 0;
        break;
    }

    // Build the image widget
    pw.Widget imageWidget = pw.Image(image, fit: pw.BoxFit.cover);

    // Build container with appropriate shape
    if (boxShape == pw.BoxShape.circle) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: s.accent, width: 2),
        ),
        child: pw.ClipOval(
          child: imageWidget,
        ),
      );
    } else {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          borderRadius:
              borderRadius > 0 ? pw.BorderRadius.circular(borderRadius) : null,
          border: pw.Border.all(color: s.accent, width: 2),
        ),
        child: pw.ClipRRect(
          horizontalRadius: borderRadius,
          verticalRadius: borderRadius,
          child: imageWidget,
        ),
      );
    }
  }
}
