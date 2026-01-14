import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pdf_font_family.dart';
import '../../models/pdf_document_type.dart';
import '../../models/pdf_preset.dart';
import '../../models/template_customization.dart';
import '../../providers/pdf_presets_provider.dart';
import 'pdf_editor_controller.dart';

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
    super.key,
  });

  final PdfEditorController controller;
  final List<PdfFontFamily> availableFonts;
  final List<Widget> additionalSections;
  final bool hideCvLayoutPresets;
  final bool hidePhotoOptions;
  final Widget? Function()? customPresetsBuilder;
  final PdfDocumentType documentType;

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
                      _buildLayoutPresetsSection(),
                      const SizedBox(height: 28),
                    ],
                  );
                }

                // No presets to show
                return const SizedBox.shrink();
              }(),

              // Color Selection
              _buildAccentColorSection(),
              const SizedBox(height: 28),

              // Font Selection
              _buildFontFamilySection(),
              const SizedBox(height: 28),

              // Dark Mode Toggle
              _buildDarkModeToggle(),
              const SizedBox(height: 28),

              // Language Toggle
              _buildLanguageToggle(),
              const SizedBox(height: 28),

              // Preset-specific adjustments
              _buildPresetAdjustmentsSection(),

              // Photo Options (only show when not hidden AND photo is enabled)
              if (!hidePhotoOptions &&
                  controller.customization.showProfilePhoto) ...[
                const SizedBox(height: 28),
                _buildPhotoOptionsSection(),
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

  Widget _buildDarkModeToggle() {
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
              controller.style.isDarkMode ? 'Dark Mode' : 'Light Mode',
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

  Widget _buildLanguageToggle() {
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
              controller.customization.language == CvLanguage.english
                  ? 'English'
                  : 'Deutsch',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<CvLanguage>(
            value: controller.customization.language,
            dropdownColor: const Color(0xFF1A1A1A),
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down,
                color: controller.style.accentColor),
            items: const [
              DropdownMenuItem(
                value: CvLanguage.english,
                child: Text('English', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: CvLanguage.german,
                child: Text('Deutsch', style: TextStyle(color: Colors.white)),
              ),
            ],
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

  Widget _buildAccentColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'ACCENT COLOR',
              style: TextStyle(
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

  Widget _buildFontFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.font_download,
                color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'FONT FAMILY',
              style: TextStyle(
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
              'No fonts available. Add TTF files to assets/fonts/',
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

  Widget _buildLayoutPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.style, color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'DESIGN PRESET',
              style: TextStyle(
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
          'Quick-switch between complete design styles',
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
                              preset.displayName,
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
                              preset.description,
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
  Widget _buildPresetAdjustmentsSection() {
    final preset = LayoutPreset.fromCustomization(controller.customization);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.tune, color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'ADJUSTMENTS',
              style: TextStyle(
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
          _getPresetAdjustmentHint(preset),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),

        // Show preset-specific controls
        ..._getControlsForPreset(preset),
      ],
    );
  }

  /// Get hint text for current preset
  String _getPresetAdjustmentHint(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return 'Timeline layout with visual accents';
      case LayoutPreset.compact:
        return 'Dense layout - fit more content';
      case LayoutPreset.traditional:
        return 'Classic professional formatting';
      case LayoutPreset.twoColumn:
        return 'Sidebar with main content area';
    }
  }

  /// Build photo options section
  Widget _buildPhotoOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.photo_camera,
                color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'PHOTO OPTIONS',
              style: TextStyle(
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
          'Shape',
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
          label: 'Image Size',
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
  List<Widget> _getControlsForPreset(LayoutPreset preset) {
    final widgets = <Widget>[];

    // Common controls for all presets
    widgets.addAll([
      _buildSliderControl(
        label: 'Spacing',
        value: controller.customization.spacingScale,
        min: 0.7,
        max: 1.3,
        onChanged: controller.setSpacingScale,
      ),
      const SizedBox(height: 12),
      _buildSliderControl(
        label: 'Font Size',
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
          _buildSubsectionHeader('Display Options'),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              'Show Profile Photo',
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              'Show Recipient Info',
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              'Show Subject Line',
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
          ],
        ]);
        break;

      case LayoutPreset.compact:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader('Display Options'),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              'Show Profile Photo',
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              'Show Recipient Info',
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              'Show Subject Line',
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
          ],
        ]);
        break;

      case LayoutPreset.traditional:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader('Display Options'),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              'Show Profile Photo',
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              'Show Recipient Info',
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              'Show Subject Line',
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
                ),
              ),
            ),
          ],
          _buildToggle(
            'Uppercase Headers',
            controller.customization.uppercaseHeaders,
            controller.toggleUppercaseHeaders,
          ),
        ]);
        break;

      case LayoutPreset.twoColumn:
        widgets.addAll([
          const SizedBox(height: 12),
          _buildSliderControl(
            label: 'Sidebar Width',
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
          _buildSubsectionHeader('Display Options'),
          const SizedBox(height: 8),
          if (!hidePhotoOptions)
            _buildToggle(
              'Show Profile Photo',
              controller.customization.showProfilePhoto,
              () => _toggleShowProfilePhoto(),
            ),
          if (documentType == PdfDocumentType.coverLetter) ...[
            _buildToggle(
              'Show Recipient Info',
              controller.customization.showRecipient,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showRecipient: !controller.customization.showRecipient,
                ),
              ),
            ),
            _buildToggle(
              'Show Subject Line',
              controller.customization.showSubject,
              () => controller.updateCustomization(
                controller.customization.copyWith(
                  showSubject: !controller.customization.showSubject,
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
                const Text(
                  'SAVED PRESETS',
                  style: TextStyle(
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
              tooltip: 'Save Current as Preset',
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
              'No saved presets yet. Click + to save current style.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          )
        else
          ...presets.map((preset) {
            // Check if current style matches preset
            final isStyleMatch = controller.style.type == preset.style.type &&
                controller.style.accentColor.toARGB32() ==
                    preset.style.accentColor.toARGB32() &&
                controller.style.fontFamily == preset.style.fontFamily;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    controller.updateStyle(preset.style);
                    controller.updateCustomization(preset.customization);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isStyleMatch
                          ? controller.style.accentColor.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isStyleMatch
                            ? controller.style.accentColor
                            : Colors.white.withValues(alpha: 0.05),
                        width: isStyleMatch ? 1.5 : 1,
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
                                  color: isStyleMatch
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isStyleMatch
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (preset.basedOnPresetName != null)
                                Text(
                                  preset.basedOnPresetName!,
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
                        if (isStyleMatch)
                          Icon(Icons.check,
                              color: controller.style.accentColor, size: 14),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.white38, size: 14),
                          onPressed: () =>
                              _showEditPresetDialog(context, preset),
                          tooltip: 'Edit Preset',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white38, size: 14),
                          onPressed: () =>
                              presetsProvider.deletePreset(preset.id),
                          tooltip: 'Delete Preset',
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
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Save Preset', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save current styling and layout settings for reuse.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Preset Name',
                labelStyle: TextStyle(color: this.controller.style.accentColor),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: this.controller.style.accentColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: this.controller.style.accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<PdfPresetsProvider>().savePreset(
                      name,
                      this.controller.style,
                      this.controller.customization,
                      type: documentType,
                      basedOnPresetName:
                          this.controller.currentLayoutPresetName,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preset "$name" saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
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
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Preset Name',
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
              'You can also update this preset with the current style settings from the editor.',
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
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Preset "$newName" updated with current style'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              'Update Style & Save',
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
            child: const Text('Rename Only'),
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
