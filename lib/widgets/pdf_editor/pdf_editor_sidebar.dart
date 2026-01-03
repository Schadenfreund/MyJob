import 'package:flutter/material.dart';
import '../../models/pdf_font_family.dart';
import '../../models/template_customization.dart';
import 'pdf_editor_controller.dart';

/// Sidebar for PDF editor with styling and layout controls
class PdfEditorSidebar extends StatelessWidget {
  const PdfEditorSidebar({
    required this.controller,
    required this.availableFonts,
    this.additionalSections = const [],
    this.hideCvLayoutPresets = false,
    this.customPresetsBuilder,
    super.key,
  });

  final PdfEditorController controller;
  final List<PdfFontFamily> availableFonts;
  final List<Widget> additionalSections;
  final bool hideCvLayoutPresets;
  final Widget? Function()? customPresetsBuilder;

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

              // Photo Options (always show when photo is enabled - works on all presets)
              if (controller.customization.showProfilePhoto) ...[
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
                          _getIconForPreset(preset),
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
          _buildToggle(
            'Show Profile Photo',
            controller.customization.showProfilePhoto,
            () => _toggleShowProfilePhoto(),
          ),
        ]);
        break;

      case LayoutPreset.compact:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader('Display Options'),
          const SizedBox(height: 8),
          _buildToggle(
            'Show Profile Photo',
            controller.customization.showProfilePhoto,
            () => _toggleShowProfilePhoto(),
          ),
        ]);
        break;

      case LayoutPreset.traditional:
        widgets.addAll([
          const SizedBox(height: 16),
          _buildSubsectionHeader('Display Options'),
          const SizedBox(height: 8),
          _buildToggle(
            'Show Profile Photo',
            controller.customization.showProfilePhoto,
            () => _toggleShowProfilePhoto(),
          ),
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
          _buildToggle(
            'Show Profile Photo',
            controller.customization.showProfilePhoto,
            () => _toggleShowProfilePhoto(),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: controller.style.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: controller.style.accentColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: controller.style.accentColor,
            overlayColor: controller.style.accentColor.withValues(alpha: 0.2),
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
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

  IconData _getIconForPreset(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return Icons.view_agenda;
      case LayoutPreset.compact:
        return Icons.compress;
      case LayoutPreset.traditional:
        return Icons.article;
      case LayoutPreset.twoColumn:
        return Icons.view_sidebar;
    }
  }
}
