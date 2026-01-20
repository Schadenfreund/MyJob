import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/template_customization.dart';
import '../../models/template_style.dart';
import '../../models/pdf_font_family.dart';
import '../../services/customization_persistence.dart';

/// Centralized controller for PDF preview/editor functionality
///
/// This controller manages all aspects of the PDF editor:
/// - View modes (side-by-side, single page, fit width)
/// - Zoom levels with smooth transitions
/// - Template styling (colors, fonts, dark mode)
/// - Layout customization (margins, spacing, presets)
/// - Inline editing state
/// - PDF generation debouncing
///
/// ## Example Usage
/// ```dart
/// final controller = PdfEditorController(
///   initialStyle: TemplateStyle.electric,
///   initialCustomization: const TemplateCustomization(),
/// );
///
/// // Listen for changes
/// controller.addListener(() {
///   if (controller.needsRegeneration) {
///     generatePdf();
///   }
/// });
///
/// // Update style
/// controller.setAccentColor(Colors.cyan);
/// ```
class PdfEditorController extends ChangeNotifier {
  PdfEditorController({
    TemplateStyle? initialStyle,
    TemplateCustomization? initialCustomization,
    this.regenerationDelay = const Duration(milliseconds: 150),
  })  : _style = initialStyle ?? TemplateStyle.electric,
        _customization = initialCustomization ?? const TemplateCustomization() {
    // Load saved customization asynchronously
    _loadSavedCustomization();
  }

  /// Delay before triggering PDF regeneration after style changes
  final Duration regenerationDelay;

  /// Load saved customization from persistence
  Future<void> _loadSavedCustomization() async {
    final saved = await CustomizationPersistence.load();
    if (saved != null) {
      _customization = saved;
      notifyListeners();
    }
  }

  // ============================================================================
  // STATE
  // ============================================================================

  TemplateStyle _style;
  TemplateCustomization _customization;
  PdfViewMode _viewMode =
      PdfViewMode.singlePage; // Default to single page for stability
  double _zoom = 1.5; // Default zoom to 150%
  bool _isGenerating = false;
  bool _isEditMode = false;
  int _pdfVersion = 0;
  Timer? _debounceTimer;
  Timer? _saveTimer;
  bool _needsRegeneration = false;
  LayoutPreset? _lastAppliedPreset;

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Current template style
  TemplateStyle get style => _style;

  /// Current layout customization
  TemplateCustomization get customization => _customization;

  /// Current view mode
  PdfViewMode get viewMode => _viewMode;

  /// Current zoom level (0.5 to 2.5)
  double get zoom => _zoom;

  /// Whether PDF is currently being generated
  bool get isGenerating => _isGenerating;

  /// Whether inline edit mode is active
  bool get isEditMode => _isEditMode;

  /// Version counter that increments on each change requiring PDF regeneration
  int get pdfVersion => _pdfVersion;

  /// Whether the PDF needs to be regenerated
  bool get needsRegeneration => _needsRegeneration;

  /// The name of the last applied layout preset
  String? get currentLayoutPresetName {
    if (_lastAppliedPreset != null) {
      switch (_lastAppliedPreset!) {
        case LayoutPreset.modern:
          return 'Modern';
        case LayoutPreset.compact:
          return 'Compact';
        case LayoutPreset.traditional:
          return 'Traditional';
        case LayoutPreset.twoColumn:
          return 'Two Column';
      }
    }
    return null;
  }

  // ============================================================================
  // VIEW MODE
  // ============================================================================

  /// Set the view mode
  void setViewMode(PdfViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// Cycle through view modes
  void cycleViewMode() {
    final modes = PdfViewMode.values;
    final nextIndex = (modes.indexOf(_viewMode) + 1) % modes.length;
    setViewMode(modes[nextIndex]);
  }

  // ============================================================================
  // ZOOM
  // ============================================================================

  /// Minimum zoom level
  static const double minZoom = 0.5;

  /// Maximum zoom level
  static const double maxZoom = 2.5;

  /// Zoom step for keyboard/button controls
  static const double zoomStep = 0.1;

  /// Set zoom level (clamped to min/max)
  void setZoom(double value) {
    final clamped = value.clamp(minZoom, maxZoom);
    if (_zoom != clamped) {
      _zoom = clamped;
      notifyListeners();
    }
  }

  /// Zoom in by one step
  void zoomIn() => setZoom(_zoom + zoomStep);

  /// Zoom out by one step
  void zoomOut() => setZoom(_zoom - zoomStep);

  /// Reset zoom to 100%
  void resetZoom() => setZoom(1.0);

  /// Fit content to available width
  void fitWidth() {
    setZoom(1.0);
    setViewMode(PdfViewMode.fitWidth);
  }

  // ============================================================================
  // STYLE
  // ============================================================================

  /// Update the entire template style
  void updateStyle(TemplateStyle newStyle) {
    if (_style != newStyle) {
      _style = newStyle;
      _scheduleRegeneration();
    }
  }

  /// Set the accent color
  void setAccentColor(Color color) {
    if (_style.accentColor != color) {
      _style = _style.copyWith(accentColor: color);
      _scheduleRegeneration();
    }
  }

  /// Set the font family
  void setFontFamily(PdfFontFamily font) {
    if (_style.fontFamily != font) {
      _style = _style.copyWith(fontFamily: font);
      _scheduleRegeneration();
    }
  }

  /// Toggle dark/light mode
  void toggleDarkMode() {
    _style = _style.copyWith(isDarkMode: !_style.isDarkMode);
    _scheduleRegeneration();
  }

  /// Set dark mode explicitly
  void setDarkMode(bool isDark) {
    if (_style.isDarkMode != isDark) {
      _style = _style.copyWith(isDarkMode: isDark);
      _scheduleRegeneration();
    }
  }

  // ============================================================================
  // CUSTOMIZATION
  // ============================================================================

  void updateCustomization(TemplateCustomization newCustomization) {
    _customization = newCustomization;
    _scheduleRegeneration();
    _scheduleSave();
  }

  /// Internal helper to schedule a debounced save to disk
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      CustomizationPersistence.save(_customization);
    });
  }

  // ============================================================================
  // STYLE MANAGEMENT
  // ============================================================================

  /// Set template style (triggers PDF regeneration)
  void setStyle(TemplateStyle newStyle) {
    if (_style.type != newStyle.type ||
        _style.accentColor != newStyle.accentColor ||
        _style.fontFamily != newStyle.fontFamily) {
      _style = newStyle;
      regenerate();
    }
  }

  // ============================================================================
  // LAYOUT MANAGEMENT
  // ============================================================================

  /// Apply a layout preset
  void setLayoutPreset(LayoutPreset preset) {
    _lastAppliedPreset = preset;
    _customization = preset.toCustomization();
    _scheduleRegeneration();
  }

  /// Set margin preset
  void setMarginPreset(MarginPreset preset) {
    if (_customization.marginPreset != preset) {
      _customization = _customization.copyWith(marginPreset: preset);
      _scheduleRegeneration();
    }
  }

  /// Set spacing scale (0.7 to 1.3)
  void setSpacingScale(double scale) {
    final clamped = scale.clamp(0.7, 1.3);
    if (_customization.spacingScale != clamped) {
      _customization = _customization.copyWith(spacingScale: clamped);
      _scheduleRegeneration();
      _scheduleSave();
    }
  }

  /// Set font size scale (0.8 to 1.2)
  void setFontSizeScale(double scale) {
    final clamped = scale.clamp(0.8, 1.2);
    if (_customization.fontSizeScale != clamped) {
      _customization = _customization.copyWith(fontSizeScale: clamped);
      _scheduleRegeneration();
      _scheduleSave();
    }
  }

  /// Set line height (1.2 to 1.8)
  void setLineHeight(double height) {
    final clamped = height.clamp(1.2, 1.8);
    if (_customization.lineHeight != clamped) {
      _customization = _customization.copyWith(lineHeight: clamped);
      _scheduleRegeneration();
      _scheduleSave();
    }
  }

  /// Toggle section dividers visibility
  void toggleDividers() {
    _customization = _customization.copyWith(
      showDividers: !_customization.showDividers,
    );
    _scheduleRegeneration();
  }

  /// Toggle contact icons visibility
  void toggleContactIcons() {
    _customization = _customization.copyWith(
      showContactIcons: !_customization.showContactIcons,
    );
    _scheduleRegeneration();
  }

  /// Toggle skill level indicators visibility
  void toggleSkillLevels() {
    _customization = _customization.copyWith(
      showSkillLevels: !_customization.showSkillLevels,
    );
    _scheduleRegeneration();
  }

  /// Toggle uppercase section headers
  void toggleUppercaseHeaders() {
    _customization = _customization.copyWith(
      uppercaseHeaders: !_customization.uppercaseHeaders,
    );
    _scheduleRegeneration();
  }

  /// Set CV layout mode (modern, sidebar, traditional, compact)
  void setLayoutMode(CvLayoutMode mode) {
    if (_customization.layoutMode != mode) {
      _customization = _customization.copyWith(layoutMode: mode);
      _scheduleRegeneration();
    }
  }

  /// Set experience rendering style (timeline, list, cards, compact)
  void setExperienceStyle(ExperienceStyle style) {
    if (_customization.experienceStyle != style) {
      _customization = _customization.copyWith(experienceStyle: style);
      _scheduleRegeneration();
    }
  }

  /// Set header layout style (modern, clean, sidebar, compact)
  void setHeaderStyle(HeaderStyle style) {
    if (_customization.headerStyle != style) {
      _customization = _customization.copyWith(headerStyle: style);
      _scheduleRegeneration();
    }
  }

  /// Set section order preset
  void setSectionOrderPreset(SectionOrderPreset preset) {
    if (_customization.sectionOrderPreset != preset) {
      _customization = _customization.copyWith(sectionOrderPreset: preset);
      _scheduleRegeneration();
    }
  }

  /// Toggle proficiency bars for skills
  void toggleProficiencyBars() {
    _customization = _customization.copyWith(
      showProficiencyBars: !_customization.showProficiencyBars,
    );
    _scheduleRegeneration();
  }

  /// Set proficiency bars explicitly
  void setShowProficiencyBars(bool show) {
    if (_customization.showProficiencyBars != show) {
      _customization = _customization.copyWith(showProficiencyBars: show);
      _scheduleRegeneration();
    }
  }

  // ============================================================================
  // EDIT MODE
  // ============================================================================

  /// Toggle inline edit mode
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  /// Set edit mode explicitly
  void setEditMode(bool enabled) {
    if (_isEditMode != enabled) {
      _isEditMode = enabled;
      notifyListeners();
    }
  }

  // ============================================================================
  // GENERATION STATE
  // ============================================================================

  /// Set whether PDF is currently being generated
  void setGenerating(bool generating) {
    if (_isGenerating != generating) {
      _isGenerating = generating;
      if (generating) {
        _needsRegeneration = false;
      }
      notifyListeners();
    }
  }

  /// Mark regeneration as complete
  void markRegenerationComplete() {
    _needsRegeneration = false;
  }

  /// Schedule PDF regeneration with debouncing
  ///
  /// Notifies listeners immediately for UI updates, then debounces
  /// PDF regeneration to prevent excessive generation during rapid changes.
  void _scheduleRegeneration() {
    _debounceTimer?.cancel();
    _pdfVersion++;
    _needsRegeneration = true;

    // Notify immediately so UI reflects changes instantly
    notifyListeners();

    // Debounce actual PDF regeneration with shorter delay for better responsiveness
    _debounceTimer = Timer(regenerationDelay, () {
      // Re-notify after debounce to trigger PDF generation if still needed
      if (_needsRegeneration && !_isGenerating) {
        notifyListeners();
      }
    });
  }

  /// Force immediate regeneration of PDF (bypasses debounce)
  void regenerate() {
    _debounceTimer?.cancel();
    _pdfVersion++;
    _needsRegeneration = true;
    notifyListeners();
  }

  // ============================================================================
  // SERIALIZATION
  // ============================================================================

  /// Export current state as a map (for persistence)
  Map<String, dynamic> toJson() => {
        'style': _style.toJson(),
        'viewMode': _viewMode.name,
        'zoom': _zoom,
        'isEditMode': _isEditMode,
      };

  /// Restore state from a map
  void fromJson(Map<String, dynamic> json) {
    if (json['style'] != null) {
      _style = TemplateStyle.fromJson(json['style'] as Map<String, dynamic>);
    }
    if (json['viewMode'] != null) {
      _viewMode = PdfViewMode.values.firstWhere(
        (m) => m.name == json['viewMode'],
        orElse: () => PdfViewMode.sideBySide,
      );
    }
    if (json['zoom'] != null) {
      _zoom = (json['zoom'] as num).toDouble().clamp(minZoom, maxZoom);
    }
    if (json['isEditMode'] != null) {
      _isEditMode = json['isEditMode'] as bool;
    }
    notifyListeners();
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}

/// PDF viewing modes
enum PdfViewMode {
  /// Single page view (scrollable vertical list)
  singlePage('Single Page', Icons.view_agenda),

  /// Side-by-side two-page spread view
  sideBySide('Side by Side', Icons.view_week),

  /// Fit content to available width
  fitWidth('Fit Width', Icons.fit_screen);

  const PdfViewMode(this.label, this.icon);

  /// Display label for the mode
  final String label;

  /// Icon representing the mode
  final IconData icon;
}
