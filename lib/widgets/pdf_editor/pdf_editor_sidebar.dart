import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../models/pdf_font_family.dart';
import '../../models/pdf_document_type.dart';
import '../../models/pdf_preset.dart';
import '../../models/template_customization.dart';
import '../../providers/pdf_presets_provider.dart';
import 'pdf_editor_controller.dart';

// =============================================================================
// CV SECTION AVAILABILITY
// =============================================================================

/// Tracks which CV sections have content for context-sensitive UI
///
/// Used to show/hide page break toggles based on what sections
/// actually exist in the CV data.
class CvSectionAvailability {
  final bool hasExperience;
  final bool hasEducation;
  final bool hasLanguages;
  final bool hasSkills;
  final bool hasInterests;

  const CvSectionAvailability({
    this.hasExperience = false,
    this.hasEducation = false,
    this.hasLanguages = false,
    this.hasSkills = false,
    this.hasInterests = false,
  });

  /// Default: all sections available (for backwards compatibility)
  static const CvSectionAvailability all = CvSectionAvailability(
    hasExperience: true,
    hasEducation: true,
    hasLanguages: true,
    hasSkills: true,
    hasInterests: true,
  );

  /// No sections available
  static const CvSectionAvailability none = CvSectionAvailability();

  /// Check if any section with a GUI toggle is available
  bool get hasAnyToggleableSections =>
      hasExperience || hasEducation || hasLanguages;
}

// =============================================================================
// PDF EDITOR SIDEBAR
// =============================================================================

/// Sidebar for PDF editor with styling and layout controls
class PdfEditorSidebar extends StatelessWidget {
  const PdfEditorSidebar({
    required this.controller,
    required this.availableFonts,
    this.additionalSections = const [],
    this.hideCvLayoutPresets = false,
    this.hidePhotoOptions = false,
    this.customPresetsBuilder,
    required this.documentType,
    this.cvSectionAvailability,
    super.key,
  });

  final PdfEditorController controller;
  final List<PdfFontFamily> availableFonts;
  final List<Widget> additionalSections;
  final bool hideCvLayoutPresets;
  final bool hidePhotoOptions;
  final Widget? Function()? customPresetsBuilder;
  final PdfDocumentType documentType;

  /// CV section availability for context-sensitive page break toggles
  /// Only relevant when documentType is CV
  final CvSectionAvailability? cvSectionAvailability;

  // Accent color presets (matching PDF styling presets)
  static const List<Color> _accentColorPresets = [
    Color(0xFFFFFF00), // Electric Yellow (default)
    Color(0xFFFFC107), // Amber Professional (WCAG-compliant)
    Color(0xFF2196F3), // Professional Blue
    Color(0xFF009688), // Modern Teal
    Color(0xFFE91E63), // Vibrant Magenta
    Color(0xFF8BC34A), // Fresh Lime
    Color(0xFF00FFFF), // Electric Cyan
    Color(0xFFFF6600), // Electric Orange
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User-Saved Presets
              _buildSavedPresetsSection(context),
              const SizedBox(height: 28),

              // Design Presets - Custom or CV layout presets
              () {
                // Try custom presets first
                final customPresets = customPresetsBuilder?.call();
                if (customPresets != null) {
                  return Column(
                    children: [
                      customPresets,
                      const SizedBox(height: 28),
                    ],
                  );
                }

                // Fall back to CV layout presets if not hidden
                if (!hideCvLayoutPresets) {
                  return Column(
                    children: [
                      _buildLayoutPresetsSection(context),
                      const SizedBox(height: 28),
                    ],
                  );
                }

                // No presets to show
                return const SizedBox.shrink();
              }(),

              // Color Selection
              _buildAccentColorSection(context),
              const SizedBox(height: 28),

              // Font Selection
              _buildFontFamilySection(context),
              const SizedBox(height: 28),

              // Dark Mode Toggle
              _buildDarkModeToggle(context),
              const SizedBox(height: 28),

              // Language Toggle
              _buildLanguageToggle(context),
              const SizedBox(height: 28),

              // Preset-specific adjustments
              _buildPresetAdjustmentsSection(context),

              // Page Breaks section (only for CVs, not Two-Column/Compact)
              if (_shouldShowPageBreakSection()) ...[
                const SizedBox(height: 28),
                _buildPageBreakSection(context),
              ],

              // Photo Options (only show when not hidden AND photo is enabled)
              if (!hidePhotoOptions &&
                  controller.customization.showProfilePhoto) ...[
                const SizedBox(height: 28),
                _buildPhotoOptionsSection(context),
              ],

              // Additional sections from parent (like info sections)
              if (additionalSections.isNotEmpty) ...[
                const SizedBox(height: 24),
                ...additionalSections,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            controller.style.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: controller.style.accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.style.isDarkMode
                  ? context.tr('sidebar_dark_mode')
                  : context.tr('sidebar_light_mode'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: controller.style.isDarkMode,
            onChanged: (_) => controller.toggleDarkMode(),
            activeTrackColor:
                controller.style.accentColor.withValues(alpha: 0.5),
            activeThumbColor: controller.style.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context) {
    final languages =
        Provider.of<AppLocalizations>(context, listen: false).availableLanguages;
    final currentCode = controller.customization.language;
    // Guard: if the stored code is not in the available list, fall back gracefully
    final validCode = languages.any((l) => l.code == currentCode)
        ? currentCode
        : (languages.isNotEmpty ? languages.first.code : 'en');
    final currentName = languages
        .firstWhere(
          (l) => l.code == validCode,
          orElse: () => LanguageInfo(
              code: validCode, name: validCode.toUpperCase(), flag: ''),
        )
        .name;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.language,
            color: controller.style.accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: validCode,
            dropdownColor: const Color(0xFF1A1A1A),
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down,
                color: controller.style.accentColor),
            items: languages
                .map((lang) => DropdownMenuItem(
                      value: lang.code,
                      child: Text(lang.name,
                          style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateCustomization(
                  controller.customization.copyWith(language: value),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('sidebar_accent_color').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _accentColorPresets.map((color) {
            final isSelected =
                controller.style.accentColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => controller.setAccentColor(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.black, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontFamilySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.font_download,
                color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('sidebar_font_family').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (availableFonts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              context.tr('no_fonts_available'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          )
        else
          ...availableFonts.map((font) {
            final isSelected = controller.style.fontFamily == font;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? controller.style.accentColor.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? controller.style.accentColor
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.setFontFamily(font),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? controller.style.accentColor
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                font.displayName[0],
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  font.characteristicsLabel,
                                  style: TextStyle(
                                    color: isSelected
                                        ? controller.style.accentColor
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: controller.style.accentColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLayoutPresetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.style, color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('sidebar_design_preset').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('sidebar_design_preset_desc'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        ...LayoutPreset.values.map((preset) {
          // Check if this preset matches current customization
          final isSelected = controller.customization.layoutMode ==
              preset.toCustomization().layoutMode;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.setLayoutPreset(preset),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? controller.style.accentColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? controller.style.accentColor
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? controller.style.accentColor
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          preset.icon,
                          color: isSelected ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _presetDisplayName(context, preset),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _presetDescription(context, preset),
                              style: TextStyle(
                                color: isSelected
                                    ? controller.style.accentColor
                                    : Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: controller.style.accentColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Build preset-specific adjustments section - shows only relevant controls
  Widget _buildPresetAdjustmentsSection(BuildContext context) {
    final preset = LayoutPreset.fromCustomization(controller.customization);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.tune, color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('sidebar_adjustments').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _getPresetAdjustmentHint(context, preset),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),

        // Show preset-specific controls
        ..._getControlsForPreset(context, preset),
      ],
    );
  }

  String _presetDisplayName(BuildContext context, LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return context.tr('layout_preset_modern');
      case LayoutPreset.compact:
        return context.tr('layout_preset_compact');
      case LayoutPreset.traditional:
        return context.tr('layout_preset_traditional');
      case LayoutPreset.twoColumn:
        return context.tr('layout_preset_two_column');
    }
  }

  String _presetDescription(BuildContext context, LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return context.tr('layout_preset_modern_desc');
      case LayoutPreset.compact:
        return context.tr('layout_preset_compact_desc');
      case LayoutPreset.traditional:
        return context.tr('layout_preset_traditional_desc');
      case LayoutPreset.twoColumn:
        return context.tr('layout_preset_two_column_desc');
    }
  }

  /// Get hint text for current preset
  String _getPresetAdjustmentHint(BuildContext context, LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return context.tr('sidebar_adjustments_desc_modern');
      case LayoutPreset.compact:
        return context.tr('sidebar_adjustments_desc_compact');
      case LayoutPreset.traditional:
        return context.tr('sidebar_adjustments_desc_traditional');
      case LayoutPreset.twoColumn:
        return context.tr('sidebar_adjustments_desc_two_column');
    }
  }

  // ===========================================================================
  // PAGE BREAK SECTION
  // ===========================================================================

  /// Check if the page break section should be shown
  ///
  /// Page breaks are only relevant for:
  /// - CV documents (not cover letters)
  /// - Multi-page layouts (not Two-Column - single page layout)
  /// - When at least one toggleable section exists
  bool _shouldShowPageBreakSection() {
    // Only show for CV documents
    if (documentType != PdfDocumentType.cv) return false;

    // Don't show for Two-Column preset (single-page layout where page breaks don't apply)
    final preset = LayoutPreset.fromCustomization(controller.customization);
    if (preset == LayoutPreset.twoColumn) {
      return false;
    }

    // Check if any toggleable sections exist
    final availability = cvSectionAvailability ?? CvSectionAvailability.all;
    return availability.hasAnyToggleableSections;
  }

  /// Build the PAGE BREAKS section with context-sensitive toggles
  Widget _buildPageBreakSection(BuildContext context) {
    final availability = cvSectionAvailability ?? CvSectionAvailability.all;
    final pageBreaks = controller.customization.sectionPageBreaks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.insert_page_break_outlined,
              color: controller.style.accentColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('sidebar_page_breaks').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('sidebar_page_breaks_desc'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),

        // Experience toggle (if section exists)
        if (availability.hasExperience)
          _buildPageBreakToggle(
            label: context.tr('sidebar_before_experience'),
            value: pageBreaks.beforeExperience,
            onToggle: () => _togglePageBreak('experience'),
          ),

        // Education toggle (if section exists)
        if (availability.hasEducation)
          _buildPageBreakToggle(
            label: context.tr('sidebar_before_education'),
            value: pageBreaks.beforeEducation,
            onToggle: () => _togglePageBreak('education'),
          ),

        // Languages toggle (if section exists)
        if (availability.hasLanguages)
          _buildPageBreakToggle(
            label: context.tr('sidebar_before_languages'),
            value: pageBreaks.beforeLanguages,
            onToggle: () => _togglePageBreak('languages'),
          ),
      ],
    );
  }

  /// Build a single page break toggle
  Widget _buildPageBreakToggle({
    required String label,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: controller.style.accentColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Toggle a specific page break setting
  void _togglePageBreak(String section) {
    final current = controller.customization.sectionPageBreaks;
    SectionPageBreaks updated;

    switch (section) {
      case 'experience':
        updated = current.copyWith(beforeExperience: !current.beforeExperience);
        break;
      case 'education':
        updated = current.copyWith(beforeEducation: !current.beforeEducation);
        break;
      case 'languages':
        updated = current.copyWith(beforeLanguages: !current.beforeLanguages);
        break;
      default:
        return;
    }

    controller.updateCustomization(
      controller.customization.copyWith(sectionPageBreaks: updated),
    );
  }

  // ===========================================================================
  // PHOTO OPTIONS SECTION
  // ===========================================================================

  /// Build photo options section
  Widget _buildPhotoOptionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.photo_camera,
                color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('sidebar_photo_options').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Shape selector (icon buttons)
        Text(
          context.tr('sidebar_shape'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ProfilePhotoShape.values.map((shape) {
            final isSelected =
                controller.customization.profilePhotoShape == shape;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  controller.updateCustomization(
                    controller.customization.copyWith(profilePhotoShape: shape),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? controller.style.accentColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? controller.style.accentColor
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    shape.icon,
                    color: isSelected
                        ? controller.style.accentColor
                        : Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSliderControl(
          label: context.tr('sidebar_image_size'),
          value: controller.customization.profilePhotoSize,
          min: 0.8,
          max: 1.2,
          onChanged: (value) {
            controller.updateCustomization(
              controller.customization.copyWith(profilePhotoSize: value),
            );
          },
        ),
        // Style selector removed - only one option (color) exists, so no need to show UI
      ],
    );
  }

  /// Get the controls relevant for each preset
  ///
  /// Only shows controls that actually affect the PDF output.
  List<Widget> _getControlsForPreset(
      BuildContext context, LayoutPreset preset) {
    final widgets = <Widget>[];

    // Common controls for all presets
    widgets.addAll([
      _buildSliderControl(
        label: context.tr('sidebar_spacing'),
        value: controller.customization.spacingScale,
        min: 0.7,
        max: 1.3,
        onChanged: controller.setSpacingScale,
      ),
      const SizedBox(height: 12),
      _buildSliderControl(
        label: context.tr('sidebar_font_size'),
        value: controller.customization.fontSizeScale,
        min: 0.8,
        max: 1.2,
        onChanged: controller.setFontSizeScale,
      ),
    ]);

    // Preset-specific controls
    switch (preset) {
      case LayoutPreset.modern:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader(context.tr('sidebar_display_options')),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              context.tr('sidebar_show_photo'),
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              context.tr('sidebar_show_recipient'),
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_subject'),
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_greeting'),
              controller.customization.showGreeting,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showGreeting: !controller.customization.showGreeting,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_closing'),
              controller.customization.showClosing,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showClosing: !controller.customization.showClosing,
                ),
              ),
            ),
          ],
        ]);
        break;

      case LayoutPreset.compact:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader(context.tr('sidebar_display_options')),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              context.tr('sidebar_show_photo'),
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              context.tr('sidebar_show_recipient'),
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_subject'),
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_greeting'),
              controller.customization.showGreeting,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showGreeting: !controller.customization.showGreeting,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_closing'),
              controller.customization.showClosing,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showClosing: !controller.customization.showClosing,
                ),
              ),
            ),
          ],
        ]);
        break;

      case LayoutPreset.traditional:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader(context.tr('sidebar_display_options')),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              context.tr('sidebar_show_photo'),
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              context.tr('sidebar_show_recipient'),
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_subject'),
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_greeting'),
              controller.customization.showGreeting,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showGreeting: !controller.customization.showGreeting,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_closing'),
              controller.customization.showClosing,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showClosing: !controller.customization.showClosing,
                ),
              ),
            ),
          ],
          _buildToggle(
            context.tr('sidebar_uppercase_headers'),
            controller.customization.uppercaseHeaders,
            controller.toggleUppercaseHeaders,
          ),
        ]);
        break;

      case LayoutPreset.twoColumn:
        widgets.addAll([
          const SizedBox(height: 12),
          _buildSliderControl(
            label: context.tr('sidebar_sidebar_width'),
            value: controller.customization.sidebarWidthRatio,
            min: 0.25,
            max: 0.45,
            onChanged: (value) {
              controller.updateCustomization(
                controller.customization.copyWith(sidebarWidthRatio: value),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSubsectionHeader(context.tr('sidebar_display_options')),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              context.tr('sidebar_show_photo'),
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              context.tr('sidebar_show_recipient'),
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_subject'),
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_greeting'),
              controller.customization.showGreeting,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showGreeting: !controller.customization.showGreeting,
                ),
              ),
            ),
            _buildToggle(
              context.tr('sidebar_show_closing'),
              controller.customization.showClosing,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showClosing: !controller.customization.showClosing,
                ),
              ),
            ),
          ],
        ]);
        break;
    }

    return widgets;
  }

  /// Toggle show profile photo with proper state update
  void _toggleShowProfilePhoto() {
    controller.updateCustomization(
      controller.customization.copyWith(
        showProfilePhoto: !controller.customization.showProfilePhoto,
      ),
    );
  }

  /// Build a subsection header
  Widget _buildSubsectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return _PdfSlider(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      accentColor: controller.style.accentColor,
    );
  }

  Widget _buildToggle(String label, bool value, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: controller.style.accentColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPresetsSection(BuildContext context) {
    final presetsProvider = context.watch<PdfPresetsProvider>();
    final presets = presetsProvider.getPresetsByType(documentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.bookmarks,
                    color: controller.style.accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  context.tr('sidebar_saved_presets').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: controller.style.accentColor, size: 20),
              onPressed: () => _showSavePresetDialog(context),
              tooltip: context.tr('sidebar_save_as_preset'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (presets.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              context.tr('sidebar_no_presets'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          )
        else
          ...presets.map((preset) {
            final isSelected = controller.activePresetId == preset.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    controller.setActivePresetId(preset.id);
                    controller.updateStyle(preset.style);
                    controller.updateCustomization(preset.customization);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? controller.style.accentColor.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? controller.style.accentColor
                            : Colors.white.withValues(alpha: 0.05),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                preset.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                preset.basedOnPresetName != null
                                    ? context.tr(preset.basedOnPresetName!)
                                    : '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check,
                              color: controller.style.accentColor, size: 14),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.white38, size: 14),
                          onPressed: () =>
                              _showEditPresetDialog(context, preset),
                          tooltip: context.tr('sidebar_edit_preset_title'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white38, size: 14),
                          onPressed: () =>
                              presetsProvider.deletePreset(preset.id),
                          tooltip: context.tr('sidebar_delete_preset'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showSavePresetDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(context.tr('sidebar_save_preset_title'),
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('sidebar_save_preset_desc'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr('sidebar_preset_name'),
                labelStyle: TextStyle(color: controller.style.accentColor),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: controller.style.accentColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'),
                style: const TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: controller.style.accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newPreset =
                    await context.read<PdfPresetsProvider>().savePreset(
                          name,
                          controller.style,
                          controller.customization,
                          type: documentType,
                          basedOnPresetName: controller.currentLayoutPresetName,
                        );
                controller.setActivePresetId(newPreset.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.tr('sidebar_preset_saved', {'name': name})),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showEditPresetDialog(BuildContext context, PdfPreset preset) {
    final nameController = TextEditingController(text: preset.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(context.tr('sidebar_edit_preset_title'),
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr('sidebar_preset_name'),
                labelStyle: TextStyle(color: controller.style.accentColor),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: controller.style.accentColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('sidebar_update_preset_desc'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final updatedPreset = PdfPreset(
                  id: preset.id,
                  name: newName,
                  basedOnPresetName: controller.currentLayoutPresetName,
                  style: controller.style,
                  customization: controller.customization,
                  createdAt: preset.createdAt,
                );
                context.read<PdfPresetsProvider>().updatePreset(updatedPreset);
                controller.setActivePresetId(preset.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr(
                        'sidebar_preset_updated', {'name': newName})),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              context.tr('sidebar_update_style_save'),
              style: TextStyle(color: controller.style.accentColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: controller.style.accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final updatedPreset = PdfPreset(
                  id: preset.id,
                  name: newName,
                  basedOnPresetName: preset.basedOnPresetName,
                  style: preset.style,
                  customization: preset.customization,
                  createdAt: preset.createdAt,
                );
                context.read<PdfPresetsProvider>().updatePreset(updatedPreset);
                Navigator.pop(context);
              }
            },
            child: Text(context.tr('sidebar_rename_only')),
          ),
        ],
      ),
    );
  }
}

class _PdfSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color accentColor;

  const _PdfSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<_PdfSlider> createState() => _PdfSliderState();
}

class _PdfSliderState extends State<_PdfSlider> {
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(_PdfSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _localValue.toStringAsFixed(2),
              style: TextStyle(
                color: widget.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: widget.accentColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: widget.accentColor,
            overlayColor: widget.accentColor.withValues(alpha: 0.2),
            trackHeight: 2,
          ),
          child: Slider(
            value: _localValue,
            min: widget.min,
            max: widget.max,
            onChanged: (val) {
              setState(() => _localValue = val);
            },
            onChangeEnd: (val) {
              widget.onChanged(val);
            },
          ),
        ),
      ],
    );
  }
}
