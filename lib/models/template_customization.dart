// ===========================================================================
// PDF Template Customization Model
// ===========================================================================
//
// This file contains all customization options for CV and Cover Letter PDF
// templates. Options are organized into logical groups for easy understanding.
// ===========================================================================

import 'package:flutter/material.dart';

// ===========================================================================
// ENUMS - Layout and Style Options
// ===========================================================================

/// Profile photo shape options
enum ProfilePhotoShape {
  circle('Circle', Icons.circle_outlined),
  rounded('Rounded', Icons.rounded_corner),
  square('Square', Icons.crop_square);

  final String displayName;
  final IconData icon;
  const ProfilePhotoShape(this.displayName, this.icon);
}

/// Profile photo color style
enum ProfilePhotoStyle {
  color('Color', Icons.color_lens),
  grayscale('Black & White', Icons.filter_b_and_w);

  final String displayName;
  final IconData icon;
  const ProfilePhotoStyle(this.displayName, this.icon);
}

/// CV Layout modes for the professional template
enum CvLayoutMode {
  modern('Modern', 'Single column with timeline experience', Icons.view_agenda),
  sidebar(
      'Sidebar', 'Info bar at top with contact details', Icons.view_sidebar),
  traditional('Traditional', 'Classic single-column format', Icons.article),
  compact('Compact', 'Dense layout for extensive CVs', Icons.compress);

  final String displayName;
  final String description;
  final IconData icon;
  const CvLayoutMode(this.displayName, this.description, this.icon);
}

/// Experience rendering styles
enum ExperienceStyle {
  timeline('Timeline', 'Dots and connecting lines', Icons.timeline),
  list('List', 'Traditional bullet list', Icons.format_list_bulleted),
  cards('Cards', 'Card-based entries', Icons.credit_card),
  compact('Compact', 'Minimal spacing', Icons.density_small);

  final String displayName;
  final String description;
  final IconData icon;
  const ExperienceStyle(this.displayName, this.description, this.icon);
}

/// Header layout styles
enum HeaderStyle {
  modern('Modern', 'Full-width with accent bar', Icons.view_day),
  clean('Clean', 'Minimal centered design', Icons.center_focus_strong),
  sidebar('Sidebar', 'Name left, contact right', Icons.view_sidebar),
  compact('Compact', 'Single line, space-efficient', Icons.horizontal_rule);

  final String displayName;
  final String description;
  final IconData icon;
  const HeaderStyle(this.displayName, this.description, this.icon);
}

/// Section order presets
enum SectionOrderPreset {
  standard('Standard', 'Profile → Skills → Experience → Education'),
  educationFirst('Education First', 'Best for students and recent graduates'),
  skillsFirst('Skills First', 'Best for technical and specialized roles'),
  experienceFirst('Experience First', 'Best for senior professionals');

  final String displayName;
  final String description;
  const SectionOrderPreset(this.displayName, this.description);
}

/// Margin presets for PDF documents
enum MarginPreset {
  narrow('Narrow', 'Compact margins for more content', 36, 36, 36, 36),
  normal('Normal', 'Standard professional margins', 48, 48, 48, 48),
  wide('Wide', 'More whitespace for clarity', 60, 60, 60, 60),
  asymmetric('Binding', 'Extra left margin for binding', 48, 48, 72, 48);

  final String displayName;
  final String description;
  final double topMargin;
  final double bottomMargin;
  final double leftMargin;
  final double rightMargin;

  const MarginPreset(
    this.displayName,
    this.description,
    this.topMargin,
    this.bottomMargin,
    this.leftMargin,
    this.rightMargin,
  );
}

// ===========================================================================
// TEMPLATE CUSTOMIZATION CLASS
// ===========================================================================

/// Template customization parameters for PDF templates
///
/// Options are grouped into categories:
/// - **Global**: Affects overall document (spacing, fonts, margins)
/// - **Layout**: Structure and arrangement of content
/// - **Style**: Visual appearance (dividers, icons, headers)
/// - **Visibility**: Show/hide specific elements
class TemplateCustomization {
  // -------------------------------------------------------------------------
  // GLOBAL OPTIONS - Affect entire document
  // -------------------------------------------------------------------------

  /// Scale factor for spacing between elements
  /// Range: 0.8 (compact) to 1.2 (relaxed), default: 1.0
  final double spacingScale;

  /// Scale factor for font sizes
  /// Range: 0.9 (smaller) to 1.1 (larger), default: 1.0
  final double fontSizeScale;

  /// Line height multiplier for body text
  /// Range: 1.2 to 1.6, default: 1.4
  final double lineHeight;

  /// Margin preset for the document
  final MarginPreset marginPreset;

  // -------------------------------------------------------------------------
  // LAYOUT OPTIONS - Structure and arrangement
  // -------------------------------------------------------------------------

  /// Primary layout mode for the CV
  final CvLayoutMode layoutMode;

  /// Enable true two-column single-page layout
  /// When enabled, creates a sidebar (35%) + main content (65%) layout
  final bool useTwoColumnLayout;

  /// Ratio of sidebar width for two-column layouts
  /// Range: 0.25 to 0.40, default: 0.35
  final double sidebarWidthRatio;

  /// Predefined section order
  final SectionOrderPreset sectionOrderPreset;

  /// Custom section order (overrides preset if provided)
  final List<String>? sectionOrder;

  // -------------------------------------------------------------------------
  // STYLE OPTIONS - Visual appearance
  // -------------------------------------------------------------------------

  /// Header layout style
  final HeaderStyle headerStyle;

  /// Experience section rendering style
  final ExperienceStyle experienceStyle;

  /// Show divider lines between sections
  final bool showDividers;

  /// Render section headers in uppercase
  final bool uppercaseHeaders;

  // -------------------------------------------------------------------------
  // VISIBILITY OPTIONS - Show/hide elements
  // -------------------------------------------------------------------------

  /// Show profile photo if available
  final bool showProfilePhoto;

  /// Profile photo shape (circle, rounded, square)
  final ProfilePhotoShape profilePhotoShape;

  /// Profile photo color style (color or grayscale)
  final ProfilePhotoStyle profilePhotoStyle;

  /// Show icons next to contact information
  final bool showContactIcons;

  /// Show skill level indicators (beginner/intermediate/expert)
  final bool showSkillLevels;

  /// Show visual proficiency bars for skills
  final bool showProficiencyBars;

  // -------------------------------------------------------------------------
  // CONSTRUCTOR
  // -------------------------------------------------------------------------

  const TemplateCustomization({
    // Global
    this.spacingScale = 1.0,
    this.fontSizeScale = 1.0,
    this.lineHeight = 1.4,
    this.marginPreset = MarginPreset.normal,
    // Layout
    this.layoutMode = CvLayoutMode.modern,
    this.useTwoColumnLayout = false,
    this.sidebarWidthRatio = 0.35,
    this.sectionOrderPreset = SectionOrderPreset.standard,
    this.sectionOrder,
    // Style
    this.headerStyle = HeaderStyle.modern,
    this.experienceStyle = ExperienceStyle.timeline,
    this.showDividers = true,
    this.uppercaseHeaders = true,
    // Visibility
    this.showProfilePhoto = true,
    this.profilePhotoShape = ProfilePhotoShape.circle,
    this.profilePhotoStyle = ProfilePhotoStyle.color,
    this.showContactIcons = true,
    this.showSkillLevels = true,
    this.showProficiencyBars = true,
  });

  // -------------------------------------------------------------------------
  // FACTORY PRESETS
  // -------------------------------------------------------------------------

  /// Modern preset - Bold magazine-style with full features
  factory TemplateCustomization.modern() => const TemplateCustomization(
        layoutMode: CvLayoutMode.modern,
        headerStyle: HeaderStyle.modern,
        experienceStyle: ExperienceStyle.timeline,
      );

  /// Compact preset - Maximum content per page
  factory TemplateCustomization.compact() => const TemplateCustomization(
        layoutMode: CvLayoutMode.compact,
        headerStyle: HeaderStyle.compact,
        experienceStyle: ExperienceStyle.compact,
        spacingScale: 0.8,
        fontSizeScale: 0.9,
        lineHeight: 1.2,
        marginPreset: MarginPreset.narrow,
        showDividers: false,
        showContactIcons: false,
        showProficiencyBars: false,
      );

  /// Traditional preset - Classic professional style
  factory TemplateCustomization.traditional() => const TemplateCustomization(
        layoutMode: CvLayoutMode.traditional,
        headerStyle: HeaderStyle.clean,
        experienceStyle: ExperienceStyle.list,
        sectionOrderPreset: SectionOrderPreset.experienceFirst,
        showContactIcons: false,
        showSkillLevels: false,
        showProficiencyBars: false,
      );

  /// Two-column preset - Sidebar layout for visual separation
  factory TemplateCustomization.twoColumn() => const TemplateCustomization(
        layoutMode: CvLayoutMode.sidebar,
        headerStyle: HeaderStyle.sidebar,
        experienceStyle: ExperienceStyle.cards,
        useTwoColumnLayout: true,
      );

  // -------------------------------------------------------------------------
  // HELPER METHODS
  // -------------------------------------------------------------------------

  /// Get page margins from preset
  double get pageMarginTop => marginPreset.topMargin;
  double get pageMarginBottom => marginPreset.bottomMargin;
  double get pageMarginLeft => marginPreset.leftMargin;
  double get pageMarginRight => marginPreset.rightMargin;

  /// Check if an option is relevant for the current layout mode
  bool isOptionRelevant(String optionId) {
    switch (optionId) {
      // Two-column specific options
      case 'sidebarWidthRatio':
        return useTwoColumnLayout;

      // Experience style only relevant for non-compact layouts
      case 'experienceStyle':
        return layoutMode != CvLayoutMode.compact;

      // Proficiency bars not useful in compact/traditional
      case 'showProficiencyBars':
        return layoutMode == CvLayoutMode.modern ||
            layoutMode == CvLayoutMode.sidebar;

      // Section order not applicable in two-column (fixed layout)
      case 'sectionOrderPreset':
      case 'sectionOrder':
        return !useTwoColumnLayout;

      // All other options are always relevant
      default:
        return true;
    }
  }

  /// Get list of option IDs that are relevant for current configuration
  List<String> get relevantOptions {
    const allOptions = [
      'spacingScale',
      'fontSizeScale',
      'lineHeight',
      'marginPreset',
      'layoutMode',
      'useTwoColumnLayout',
      'sidebarWidthRatio',
      'sectionOrderPreset',
      'headerStyle',
      'experienceStyle',
      'showDividers',
      'uppercaseHeaders',
      'showProfilePhoto',
      'showContactIcons',
      'showSkillLevels',
      'showProficiencyBars',
    ];
    return allOptions.where(isOptionRelevant).toList();
  }

  // -------------------------------------------------------------------------
  // COPY WITH
  // -------------------------------------------------------------------------

  TemplateCustomization copyWith({
    double? spacingScale,
    double? fontSizeScale,
    double? lineHeight,
    MarginPreset? marginPreset,
    CvLayoutMode? layoutMode,
    bool? useTwoColumnLayout,
    double? sidebarWidthRatio,
    SectionOrderPreset? sectionOrderPreset,
    List<String>? sectionOrder,
    HeaderStyle? headerStyle,
    ExperienceStyle? experienceStyle,
    bool? showDividers,
    bool? uppercaseHeaders,
    bool? showProfilePhoto,
    ProfilePhotoShape? profilePhotoShape,
    ProfilePhotoStyle? profilePhotoStyle,
    bool? showContactIcons,
    bool? showSkillLevels,
    bool? showProficiencyBars,
  }) {
    return TemplateCustomization(
      spacingScale: spacingScale ?? this.spacingScale,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      lineHeight: lineHeight ?? this.lineHeight,
      marginPreset: marginPreset ?? this.marginPreset,
      layoutMode: layoutMode ?? this.layoutMode,
      useTwoColumnLayout: useTwoColumnLayout ?? this.useTwoColumnLayout,
      sidebarWidthRatio: sidebarWidthRatio ?? this.sidebarWidthRatio,
      sectionOrderPreset: sectionOrderPreset ?? this.sectionOrderPreset,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      headerStyle: headerStyle ?? this.headerStyle,
      experienceStyle: experienceStyle ?? this.experienceStyle,
      showDividers: showDividers ?? this.showDividers,
      uppercaseHeaders: uppercaseHeaders ?? this.uppercaseHeaders,
      showProfilePhoto: showProfilePhoto ?? this.showProfilePhoto,
      profilePhotoShape: profilePhotoShape ?? this.profilePhotoShape,
      profilePhotoStyle: profilePhotoStyle ?? this.profilePhotoStyle,
      showContactIcons: showContactIcons ?? this.showContactIcons,
      showSkillLevels: showSkillLevels ?? this.showSkillLevels,
      showProficiencyBars: showProficiencyBars ?? this.showProficiencyBars,
    );
  }
}

// ===========================================================================
// LAYOUT PRESET ENUM (for quick switching in UI)
// ===========================================================================

/// Layout presets for quick switching between configurations
enum LayoutPreset {
  modern(
    'Modern',
    'Bold header with timeline experience',
    Icons.view_agenda,
  ),
  compact(
    'Compact',
    'Dense layout, maximize content',
    Icons.compress,
  ),
  traditional(
    'Traditional',
    'Classic professional style',
    Icons.article,
  ),
  twoColumn(
    'Two-Column',
    'Sidebar layout with visual separation',
    Icons.view_sidebar,
  );

  final String displayName;
  final String description;
  final IconData icon;

  const LayoutPreset(this.displayName, this.description, this.icon);

  /// Convert preset to full TemplateCustomization
  TemplateCustomization toCustomization() {
    switch (this) {
      case LayoutPreset.modern:
        return TemplateCustomization.modern();
      case LayoutPreset.compact:
        return TemplateCustomization.compact();
      case LayoutPreset.traditional:
        return TemplateCustomization.traditional();
      case LayoutPreset.twoColumn:
        return TemplateCustomization.twoColumn();
    }
  }

  /// Get the preset that best matches a customization
  static LayoutPreset fromCustomization(TemplateCustomization c) {
    if (c.useTwoColumnLayout) return LayoutPreset.twoColumn;
    switch (c.layoutMode) {
      case CvLayoutMode.compact:
        return LayoutPreset.compact;
      case CvLayoutMode.traditional:
        return LayoutPreset.traditional;
      case CvLayoutMode.modern:
      case CvLayoutMode.sidebar:
        return LayoutPreset.modern;
    }
  }
}
