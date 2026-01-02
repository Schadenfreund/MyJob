import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../shared/pdf_styling.dart';
import '../shared/base_pdf_template.dart';
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
  /// Uses Table for reliable two-column rendering with full height.
  pw.Widget _buildTwoColumnSinglePageLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
  ) {
    final sidebarRatio = s.customization.sidebarWidthRatio;

    // Full-page container with background color for dark mode
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: s.background, // Respect dark/light mode
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Sidebar column
          pw.Container(
            width: PdfPageFormat.a4.width * sidebarRatio,
            color: s.cardBackground, // Sidebar has card background
            padding: pw.EdgeInsets.all(s.space4),
            child: _buildSidebarColumn(cv, s, profileImage),
          ),
          // Accent divider
          pw.Container(
            width: 3,
            color: s.accent,
          ),
          // Main content column
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.all(s.space4),
              child: _buildMainColumn(cv, s),
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
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Profile photo with customizable shape
        if (profileImage != null) ...[
          pw.Center(
            child: _buildProfilePhoto(profileImage, s, size: 80),
          ),
          pw.SizedBox(height: s.space4),
        ],

        // Contact info
        if (cv.contactDetails != null) ...[
          _buildSidebarSectionHeader('Contact', s),
          pw.SizedBox(height: s.space2),
          _buildSidebarContactInfo(cv.contactDetails!, s),
          pw.SizedBox(height: s.space4),
        ],

        // Skills
        if (cv.skills.isNotEmpty) ...[
          _buildSidebarSectionHeader('Skills', s),
          pw.SizedBox(height: s.space2),
          _buildSidebarSkills(cv.skills, s),
          pw.SizedBox(height: s.space4),
        ],

        // Languages
        if (cv.languages.isNotEmpty) ...[
          _buildSidebarSectionHeader('Languages', s),
          pw.SizedBox(height: s.space2),
          _buildSidebarLanguages(cv.languages, s),
          pw.SizedBox(height: s.space4),
        ],

        // Interests
        if (cv.interests.isNotEmpty) ...[
          _buildSidebarSectionHeader('Interests', s),
          pw.SizedBox(height: s.space2),
          _buildSidebarInterests(cv.interests, s),
        ],
      ],
    );
  }

  /// Build sidebar section header
  pw.Widget _buildSidebarSectionHeader(String title, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          s.customization.uppercaseHeaders ? title.toUpperCase() : title,
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            fontWeight: pw.FontWeight.bold,
            color: s.accent,
            letterSpacing: s.letterSpacingWide,
          ),
        ),
        pw.SizedBox(height: s.space1),
        pw.Container(
          width: 30,
          height: 2,
          color: s.accent,
        ),
      ],
    );
  }

  /// Build sidebar contact info
  pw.Widget _buildSidebarContactInfo(ContactDetails contact, PdfStyling s) {
    final items = <pw.Widget>[];

    if (contact.email != null && contact.email!.isNotEmpty) {
      items.add(_buildSidebarContactItem('✉', contact.email!, s));
    }
    if (contact.phone != null && contact.phone!.isNotEmpty) {
      items.add(_buildSidebarContactItem('☎', contact.phone!, s));
    }
    if (contact.address != null && contact.address!.isNotEmpty) {
      items.add(_buildSidebarContactItem('⌂', contact.address!, s));
    }
    if (contact.website != null && contact.website!.isNotEmpty) {
      items.add(_buildSidebarContactItem('⊕', contact.website!, s));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  /// Build a single contact item for sidebar
  pw.Widget _buildSidebarContactItem(String icon, String text, PdfStyling s) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: s.space2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            icon,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: s.accent,
            ),
          ),
          pw.SizedBox(width: s.space2),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: s.fontSizeTiny,
                color: s.textPrimary,
              ),
            ),
          ),
        ],
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
            border: pw.Border.all(color: s.accent, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            skill,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: s.textPrimary,
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
                  color: s.textPrimary,
                ),
              ),
              pw.Text(
                lang.level,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny,
                  color: s.textSecondary,
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
            color: s.accentPale,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            interest,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: s.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build the main column for two-column layout
  pw.Widget _buildMainColumn(CvData cv, PdfStyling s) {
    final contact = cv.contactDetails;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name and title header
        pw.Text(
          (contact?.fullName ?? 'YOUR NAME').toUpperCase(),
          style: pw.TextStyle(
            fontSize: s.fontSizeH1,
            fontWeight: pw.FontWeight.bold,
            color: s.textPrimary,
            letterSpacing: s.letterSpacingExtraWide,
          ),
        ),
        if (contact?.jobTitle != null) ...[
          pw.SizedBox(height: s.space1),
          pw.Text(
            contact!.jobTitle!,
            style: pw.TextStyle(
              fontSize: s.fontSizeH4,
              color: s.accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        pw.SizedBox(height: s.space3),
        pw.Container(height: 2, width: 60, color: s.accent),
        pw.SizedBox(height: s.space4),

        // Profile/Summary
        if (cv.profile.isNotEmpty) ...[
          _buildMainSectionHeader('Profile', s),
          pw.SizedBox(height: s.space2),
          pw.Text(
            cv.profile.replaceAll(RegExp(r'[\r\n]+'), ' ').trim(),
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              color: s.textSecondary,
              lineSpacing: s.lineHeightNormal,
            ),
          ),
          pw.SizedBox(height: s.space4),
        ],

        // Experience
        if (cv.experiences.isNotEmpty) ...[
          _buildMainSectionHeader('Experience', s),
          pw.SizedBox(height: s.space2),
          ...cv.experiences
              .take(3)
              .map((exp) => _buildCompactExperienceEntry(exp, s)),
        ],

        // Education
        if (cv.education.isNotEmpty) ...[
          _buildMainSectionHeader('Education', s),
          pw.SizedBox(height: s.space2),
          ...cv.education
              .take(2)
              .map((edu) => _buildCompactEducationEntry(edu, s)),
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
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: s.space3),
      child: pw.Column(
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
                    fontSize: s.fontSizeSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: s.textPrimary,
                  ),
                ),
              ),
              pw.Text(
                exp.dateRange,
                style: pw.TextStyle(
                  fontSize: s.fontSizeTiny,
                  color: s.textSecondary,
                ),
              ),
            ],
          ),
          // Company
          pw.Text(
            exp.company,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: s.accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          // Bullets (max 2)
          if (exp.bullets.isNotEmpty) ...[
            pw.SizedBox(height: s.space1),
            ...exp.bullets.take(2).map((bullet) {
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: s.space1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: pw.EdgeInsets.only(top: 3),
                      width: 4,
                      height: 4,
                      decoration: pw.BoxDecoration(
                        color: s.accent,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: s.space2),
                    pw.Expanded(
                      child: pw.Text(
                        bullet,
                        style: pw.TextStyle(
                          fontSize: s.fontSizeTiny,
                          color: s.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Build compact education entry for two-column layout
  pw.Widget _buildCompactEducationEntry(Education edu, PdfStyling s) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: s.space2),
      child: pw.Row(
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
                    fontSize: s.fontSizeSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: s.textPrimary,
                  ),
                ),
                pw.Text(
                  edu.institution,
                  style: pw.TextStyle(
                    fontSize: s.fontSizeTiny,
                    color: s.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            edu.dateRange,
            style: pw.TextStyle(
              fontSize: s.fontSizeTiny,
              color: s.textSecondary,
            ),
          ),
        ],
      ),
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

    // Header (full width)
    widgets.add(
      HeaderComponent.cvHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage,
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
      widgets.add(_buildExperienceSection(cv, s, experienceLayout));
    }

    // Education (last section - no bottom margin to prevent blank page)
    if (cv.education.isNotEmpty) {
      widgets.add(_buildEducationSection(cv, s, false, addBottomMargin: false));
    }

    return widgets;
  }

  /// Sidebar layout - Enhanced single column with sidebar content at top
  ///
  /// Note: True two-column layouts with pw.Table/pw.Row cannot work with
  /// MultiPage as they can't be split across pages (causes TooManyPagesException).
  /// Instead, we render sidebar content in a compact format at the top,
  /// then the main content below. This gives a visually distinct layout
  /// while maintaining MultiPage compatibility.
  List<pw.Widget> _buildSidebarLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    HeaderLayout headerLayout,
    ExperienceLayout experienceLayout,
  ) {
    return [
      // Header with sidebar style
      HeaderComponent.cvHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage,
        layout: headerLayout,
      ),

      pw.SizedBox(height: s.sectionGapMinor),

      // Sidebar content rendered as a compact info bar
      _buildSidebarInfoBar(cv, s),

      pw.SizedBox(height: s.sectionGapMajor),

      // Main content sections
      ..._buildMainContentSections(cv, s, experienceLayout),
    ];
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
    return [
      // Header (use clean or traditional style)
      HeaderComponent.cvHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        profileImage: profileImage,
        layout: headerLayout == HeaderLayout.modern
            ? HeaderLayout.clean
            : headerLayout,
      ),

      pw.SizedBox(height: s.sectionGapMajor),

      // Sections with list-style experience (no timeline)
      ..._buildSectionsInOrder(
        cv,
        s,
        experienceLayout == ExperienceLayout.timeline
            ? ExperienceLayout.list
            : experienceLayout,
      ),
    ];
  }

  /// Compact layout - Dense layout for extensive CVs
  List<pw.Widget> _buildCompactLayout(
    CvData cv,
    PdfStyling s,
    pw.ImageProvider? profileImage,
    HeaderLayout headerLayout,
    ExperienceLayout experienceLayout,
  ) {
    return [
      // Compact header
      HeaderComponent.cvHeader(
        name: cv.contactDetails?.fullName ?? 'Your Name',
        title: cv.contactDetails?.jobTitle,
        contact: cv.contactDetails,
        styling: s,
        layout: HeaderLayout.compact,
      ),

      pw.SizedBox(height: s.sectionGapMinor),

      // Sections with compact styles
      ..._buildSectionsInOrder(
        cv,
        s,
        ExperienceLayout.compact,
        isCompact: true,
      ),
    ];
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
    ExperienceLayout experienceLayout,
  ) {
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
        pw.SizedBox(height: s.sectionGapMajor),
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
    final photoStyle = s.customization.profilePhotoStyle;

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

    // Build the image widget (apply grayscale filter if needed)
    pw.Widget imageWidget = pw.Image(image, fit: pw.BoxFit.cover);

    // Apply grayscale using ColorFiltered if needed
    if (photoStyle == ProfilePhotoStyle.grayscale) {
      // Note: pdf package doesn't have ColorFilter, so we just render the image as-is
      // The grayscale effect should be applied during image processing before PDF generation
      // For now, we show a visual indicator by desaturating the border
      imageWidget = pw.Image(image, fit: pw.BoxFit.cover);
    }

    // Build container with appropriate shape
    if (boxShape == pw.BoxShape.circle) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(
            color: photoStyle == ProfilePhotoStyle.grayscale
                ? PdfColors.grey600
                : s.accent,
            width: 2,
          ),
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
          border: pw.Border.all(
            color: photoStyle == ProfilePhotoStyle.grayscale
                ? PdfColors.grey600
                : s.accent,
            width: 2,
          ),
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
