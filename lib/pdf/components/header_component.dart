import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../shared/pdf_styling.dart';
import 'icon_component.dart';

/// Header Component - Professional headers for CV and Cover Letters
///
/// Provides flexible header layouts with consistent styling across all templates.
class HeaderComponent {
  HeaderComponent._();

  /// Build a CV header with flexible layout modes
  ///
  /// Supports different layout styles:
  /// - Modern: Full-width with subtle accent (default)
  /// - Clean: Minimal, centered
  /// - Sidebar: Name left, contact right
  /// - Compact: Single line, space-efficient
  static pw.Widget cvHeader({
    required String name,
    String? title,
    required ContactDetails? contact,
    required PdfStyling styling,
    pw.ImageProvider? profileImage,
    HeaderLayout layout = HeaderLayout.modern,
  }) {
    switch (layout) {
      case HeaderLayout.modern:
        return _buildModernHeader(
          name: name,
          title: title,
          contact: contact,
          styling: styling,
          profileImage: profileImage,
        );

      case HeaderLayout.clean:
        return _buildCleanHeader(
          name: name,
          title: title,
          contact: contact,
          styling: styling,
          profileImage: profileImage,
        );

      case HeaderLayout.sidebar:
        return _buildSidebarHeader(
          name: name,
          title: title,
          contact: contact,
          styling: styling,
          profileImage: profileImage,
        );

      case HeaderLayout.compact:
        return _buildCompactHeader(
          name: name,
          title: title,
          contact: contact,
          styling: styling,
        );
    }
  }

  /// Build a cover letter header
  ///
  /// Simpler than CV header, focuses on name and contact info.
  static pw.Widget coverLetterHeader({
    required String name,
    required ContactDetails? contact,
    required PdfStyling styling,
    HeaderLayout layout = HeaderLayout.clean,
  }) {
    // Modern layout - accent bar header
    if (layout == HeaderLayout.modern) {
      return _buildModernHeader(
        name: name,
        title: null,
        contact: contact,
        styling: styling,
        profileImage: null,
      );
    }

    // Compact layout
    if (layout == HeaderLayout.compact) {
      return _buildCompactHeader(
        name: name,
        title: null,
        contact: contact,
        styling: styling,
      );
    }

    // Default: Clean layout
    return _buildCleanHeader(
      name: name,
      title: null,
      contact: contact,
      styling: styling,
      profileImage: null,
    );
  }

  // ===========================================================================
  // PRIVATE LAYOUT BUILDERS
  // ===========================================================================

  /// Modern layout - Bold accent header with dramatic visual impact
  static pw.Widget _buildModernHeader({
    required String name,
    String? title,
    required ContactDetails? contact,
    required PdfStyling styling,
    pw.ImageProvider? profileImage,
  }) {
    // Use negative margins to extend header edge-to-edge beyond page margins
    final margins = styling.pageMargins;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Full-width accent header bar (extends beyond page margins)
        pw.Container(
          width: double.infinity,
          // Negative margin to extend to page edges
          margin: pw.EdgeInsets.only(
            left: -margins.left,
            right: -margins.right,
            top: -margins.top,
          ),
          padding: pw.EdgeInsets.symmetric(
            horizontal: margins.left + styling.space4,
            vertical: styling.space6,
          ),
          decoration: pw.BoxDecoration(
            color: styling.accent,
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Profile image (if provided)
              if (profileImage != null) ...[
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.white, width: 3),
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                  ),
                ),
                pw.SizedBox(width: styling.space5),
              ],

              // Name and title
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name - bold on accent
                    pw.Text(
                      name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: styling.fontSizeH1 * 1.3,
                        fontWeight: pw.FontWeight.bold,
                        color: styling.textOnAccent,
                        letterSpacing: 3,
                      ),
                    ),

                    // Job title
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

        // Contact info row below header
        if (contact != null) _buildContactRow(contact, styling),
      ],
    );
  }

  /// Clean layout - Minimal, centered
  static pw.Widget _buildCleanHeader({
    required String name,
    String? title,
    required ContactDetails? contact,
    required PdfStyling styling,
    pw.ImageProvider? profileImage,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Profile image (if provided)
        if (profileImage != null) ...[
          pw.Container(
            width: 70,
            height: 70,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: styling.accent, width: 2),
            ),
            child: pw.ClipOval(
              child: pw.Image(profileImage, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(height: styling.space4),
        ],

        // Name
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: styling.fontSizeH1,
            fontWeight: pw.FontWeight.bold,
            color: styling.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: pw.TextAlign.center,
        ),

        // Job title
        if (title != null && title.isNotEmpty) ...[
          pw.SizedBox(height: styling.space2),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: styling.fontSizeH3,
              color: styling.textSecondary,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],

        // Accent divider
        pw.SizedBox(height: styling.space4),
        pw.Container(
          width: 60,
          height: 3,
          color: styling.accent,
        ),

        // Contact info
        if (contact != null) ...[
          pw.SizedBox(height: styling.space4),
          _buildContactRow(contact, styling, centered: true),
        ],
      ],
    );
  }

  /// Sidebar layout - Name left, contact right
  static pw.Widget _buildSidebarHeader({
    required String name,
    String? title,
    required ContactDetails? contact,
    required PdfStyling styling,
    pw.ImageProvider? profileImage,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left side - Name and title
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Profile image (if provided)
              if (profileImage != null) ...[
                pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: styling.accent, width: 2),
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                  ),
                ),
                pw.SizedBox(height: styling.space4),
              ],

              // Name
              pw.Text(
                name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: styling.fontSizeH1,
                  fontWeight: pw.FontWeight.bold,
                  color: styling.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),

              // Job title
              if (title != null && title.isNotEmpty) ...[
                pw.SizedBox(height: styling.space2),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: styling.space3,
                    vertical: styling.space2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: styling.accent.flatten(),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeBody,
                      color: styling.textOnAccent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(width: styling.space6),

        // Right side - Contact info
        if (contact != null)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: _buildContactColumn(contact, styling),
            ),
          ),
      ],
    );
  }

  /// Compact layout - Single line, space-efficient
  static pw.Widget _buildCompactHeader({
    required String name,
    String? title,
    required ContactDetails? contact,
    required PdfStyling styling,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(styling.space4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: styling.accent, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Left side - Name and title
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: styling.fontSizeH2,
                  fontWeight: pw.FontWeight.bold,
                  color: styling.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              if (title != null && title.isNotEmpty) ...[
                pw.SizedBox(height: styling.space1),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeBody,
                    color: styling.textSecondary,
                  ),
                ),
              ],
            ],
          ),

          // Right side - Contact (just email and phone)
          if (contact != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (contact.email != null && contact.email!.isNotEmpty)
                  pw.Text(
                    contact.email!,
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeSmall,
                      color: styling.textSecondary,
                    ),
                  ),
                if (contact.phone != null && contact.phone!.isNotEmpty) ...[
                  pw.SizedBox(height: styling.space1),
                  pw.Text(
                    contact.phone!,
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeSmall,
                      color: styling.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CONTACT INFO HELPERS
  // ===========================================================================

  /// Build contact info as a wrapped row
  static pw.Widget _buildContactRow(
    ContactDetails contact,
    PdfStyling styling, {
    bool centered = false,
  }) {
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
          text: contact.address!, // Show full address
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
      alignment: centered ? pw.WrapAlignment.center : pw.WrapAlignment.start,
      spacing: styling.space4,
      runSpacing: styling.space2,
      children: items,
    );
  }

  /// Build contact info as a column
  static List<pw.Widget> _buildContactColumn(
    ContactDetails contact,
    PdfStyling styling,
  ) {
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
      items.add(pw.SizedBox(height: styling.space2));
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
      items.add(pw.SizedBox(height: styling.space2));
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
      items.add(pw.SizedBox(height: styling.space2));
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
      items.add(pw.SizedBox(height: styling.space2));
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

    return items;
  }
}

/// Header layout styles
enum HeaderLayout {
  modern, // Full-width with subtle accent (default)
  clean, // Minimal, centered
  sidebar, // Name left, contact right
  compact, // Single line, space-efficient
}
