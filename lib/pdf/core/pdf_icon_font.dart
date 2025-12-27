import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Professional icon system for PDF templates using simple geometric shapes
/// These render reliably in all PDFs without requiring custom fonts
class PdfIconFont {
  /// Get Material Icons font (built into Flutter)
  /// This requires Flutter's bundled Material Icons font
  static Future<pw.Font?> materialIcons() async {
    try {
      // Try to load Material Icons from Flutter's assets
      final fontData = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // If not available, return null and fall back to simple shapes
      return null;
    }
  }
}

/// Material Icons icon codes (subset of commonly used icons)
class MaterialIcons {
  // Contact & Communication
  static const String email = '\ue0be'; // email icon
  static const String phone = '\ue0cd'; // phone icon
  static const String location = '\ue55f'; // location_on icon
  static const String web = '\ue051'; // language/web icon
  static const String link = '\ue157'; // link icon

  // Professional & Work
  static const String work = '\ue8f9'; // work icon
  static const String business = '\ue0af'; // business icon
  static const String badge = '\uea67'; // badge icon
  static const String school = '\ue80c'; // school icon
  static const String graduation = '\ue80c'; // school/graduation

  // Skills & Abilities
  static const String star = '\ue838'; // star icon
  static const String starHalf = '\ue839'; // star_half icon
  static const String starOutline = '\ue83a'; // star_outline icon
  static const String checkCircle = '\ue86c'; // check_circle icon
  static const String verified = '\uef76'; // verified icon

  // General Purpose
  static const String check = '\ue5ca'; // check icon
  static const String circle = '\uef4a'; // circle icon
  static const String square = '\ue5c3'; // crop_square icon
  static const String arrow = '\ue5c8'; // arrow_forward icon
  static const String chevron = '\ue5cc'; // chevron_right icon
  static const String dot = '\ue061'; // fiber_manual_record (dot)

  // Social & Contact
  static const String github = '\ue157'; // link (can be styled for GitHub)
  static const String linkedin = '\ue157'; // link (can be styled for LinkedIn)
  static const String portfolio = '\ue157'; // link (can be styled for portfolio)

  // Language & Interests
  static const String language = '\ue894'; // language icon
  static const String interests = '\ue87e'; // interests icon
  static const String favorite = '\ue87d'; // favorite icon

  // Timeline & Dates
  static const String calendar = '\ue878'; // event/calendar icon
  static const String timeline = '\ue922'; // timeline icon
  static const String today = '\ue8df'; // today icon
}

/// Font Awesome icon codes (Free Solid version)
/// These are Unicode codepoints for Font Awesome 6 Free Solid
class FontAwesomeIcons {
  // Contact & Communication
  static const String envelope = '\uf0e0'; // envelope (email)
  static const String phone = '\uf095'; // phone
  static const String locationDot = '\uf3c5'; // location-dot
  static const String globe = '\uf0ac'; // globe (web)
  static const String link = '\uf0c1'; // link

  // Professional & Work
  static const String briefcase = '\uf0b1'; // briefcase (work)
  static const String building = '\uf1ad'; // building
  static const String idBadge = '\uf2c1'; // id-badge
  static const String graduationCap = '\uf19d'; // graduation-cap
  static const String userGraduate = '\uf501'; // user-graduate

  // Skills & Abilities
  static const String star = '\uf005'; // star (filled)
  static const String starHalf = '\uf089'; // star-half
  static const String starHalfStroke = '\uf5c0'; // star-half-stroke
  static const String certificateSolid = '\uf0a3'; // certificate
  static const String award = '\uf559'; // award

  // General Purpose
  static const String check = '\uf00c'; // check
  static const String circle = '\uf111'; // circle
  static const String square = '\uf0c8'; // square
  static const String angleRight = '\uf105'; // angle-right
  static const String chevronRight = '\uf054'; // chevron-right
  static const String circleDot = '\uf192'; // circle-dot

  // Language & Interests
  static const String language = '\uf1ab'; // language
  static const String heart = '\uf004'; // heart
  static const String bookOpen = '\uf518'; // book-open

  // Timeline & Dates
  static const String calendar = '\uf133'; // calendar
  static const String calendarDays = '\uf073'; // calendar-days
  static const String clock = '\uf017'; // clock

  // Tech & Tools
  static const String code = '\uf121'; // code
  static const String laptop = '\uf109'; // laptop
  static const String tools = '\uf7d9'; // tools
  static const String chartLine = '\uf201'; // chart-line
}

/// Font Awesome Brands icon codes
class FontAwesomeBrands {
  static const String github = '\uf09b'; // github
  static const String linkedin = '\uf08c'; // linkedin
  static const String twitter = '\uf099'; // twitter (x)
  static const String facebook = '\uf09a'; // facebook
  static const String instagram = '\uf16d'; // instagram
  static const String youtube = '\uf167'; // youtube
  static const String medium = '\uf23a'; // medium
  static const String stackoverflow = '\uf16c'; // stack-overflow
  static const String gitlab = '\uf296'; // gitlab
  static const String codepen = '\uf1cb'; // codepen
  static const String dev = '\uf6cc'; // dev.to
  static const String discord = '\uf392'; // discord
  static const String slack = '\uf198'; // slack
  static const String npm = '\uf3d4'; // npm
  static const String python = '\uf3e2'; // python
  static const String js = '\uf3b8'; // js-square
  static const String react = '\uf41b'; // react
  static const String angular = '\uf420'; // angular
  static const String vuejs = '\uf41f'; // vuejs
  static const String docker = '\uf395'; // docker
  static const String aws = '\uf375'; // aws
  static const String google = '\uf1a0'; // google
  static const String apple = '\uf179'; // apple
  static const String microsoft = '\uf3ca'; // microsoft
}

/// Helper to create icon text widgets with proper styling
class PdfIconHelper {
  /// Create an icon text widget
  static pw.Widget icon({
    required String iconCode,
    required pw.Font iconFont,
    required PdfColor color,
    double size = 16,
  }) {
    return pw.Text(
      iconCode,
      style: pw.TextStyle(
        font: iconFont,
        fontSize: size,
        color: color,
      ),
    );
  }

  /// Create an icon with text label (horizontal layout)
  static pw.Widget iconWithText({
    required String iconCode,
    required pw.Font iconFont,
    required String text,
    required pw.Font textFont,
    required PdfColor iconColor,
    required PdfColor textColor,
    double iconSize = 14,
    double textSize = 11,
    double spacing = 8,
    pw.CrossAxisAlignment alignment = pw.CrossAxisAlignment.center,
  }) {
    return pw.Row(
      crossAxisAlignment: alignment,
      children: [
        icon(
          iconCode: iconCode,
          iconFont: iconFont,
          color: iconColor,
          size: iconSize,
        ),
        pw.SizedBox(width: spacing),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: textFont,
              fontSize: textSize,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Create a circular icon container (for hero sections)
  static pw.Widget circularIcon({
    required String iconCode,
    required pw.Font iconFont,
    required PdfColor backgroundColor,
    required PdfColor iconColor,
    double containerSize = 40,
    double iconSize = 20,
  }) {
    return pw.Container(
      width: containerSize,
      height: containerSize,
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: icon(
          iconCode: iconCode,
          iconFont: iconFont,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  /// Create a skill rating with star icons
  static pw.Widget starRating({
    required pw.Font iconFont,
    required PdfColor activeColor,
    required PdfColor inactiveColor,
    required double rating, // 0.0 to 5.0
    double iconSize = 12,
    double spacing = 4,
  }) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return pw.Row(
      children: [
        // Full stars
        ...List.generate(
          fullStars,
          (_) => pw.Padding(
            padding: pw.EdgeInsets.only(right: spacing),
            child: icon(
              iconCode: FontAwesomeIcons.star,
              iconFont: iconFont,
              color: activeColor,
              size: iconSize,
            ),
          ),
        ),
        // Half star
        if (hasHalfStar)
          pw.Padding(
            padding: pw.EdgeInsets.only(right: spacing),
            child: icon(
              iconCode: FontAwesomeIcons.starHalf,
              iconFont: iconFont,
              color: activeColor,
              size: iconSize,
            ),
          ),
        // Empty stars
        ...List.generate(
          emptyStars,
          (_) => pw.Padding(
            padding: pw.EdgeInsets.only(right: spacing),
            child: icon(
              iconCode: MaterialIcons.starOutline,
              iconFont: iconFont,
              color: inactiveColor,
              size: iconSize,
            ),
          ),
        ),
      ],
    );
  }

  /// Create a bullet point with custom icon
  static pw.Widget bulletIcon({
    required String iconCode,
    required pw.Font iconFont,
    required PdfColor color,
    double size = 10,
  }) {
    return icon(
      iconCode: iconCode,
      iconFont: iconFont,
      color: color,
      size: size,
    );
  }
}

/// Icon sets configuration for different template styles
class IconSets {
  /// Electric template icon set (Font Awesome based)
  static const electric = IconSetConfig(
    email: FontAwesomeIcons.envelope,
    phone: FontAwesomeIcons.phone,
    location: FontAwesomeIcons.locationDot,
    web: FontAwesomeIcons.globe,
    work: FontAwesomeIcons.briefcase,
    education: FontAwesomeIcons.graduationCap,
    skills: FontAwesomeIcons.tools,
    languages: FontAwesomeIcons.language,
    interests: FontAwesomeIcons.heart,
    bullet: FontAwesomeIcons.chevronRight,
    star: FontAwesomeIcons.star,
    calendar: FontAwesomeIcons.calendar,
  );

  /// Material design icon set
  static const material = IconSetConfig(
    email: MaterialIcons.email,
    phone: MaterialIcons.phone,
    location: MaterialIcons.location,
    web: MaterialIcons.web,
    work: MaterialIcons.work,
    education: MaterialIcons.graduation,
    skills: MaterialIcons.star,
    languages: MaterialIcons.language,
    interests: MaterialIcons.interests,
    bullet: MaterialIcons.chevron,
    star: MaterialIcons.star,
    calendar: MaterialIcons.calendar,
  );
}

/// Configuration for an icon set
class IconSetConfig {
  const IconSetConfig({
    required this.email,
    required this.phone,
    required this.location,
    required this.web,
    required this.work,
    required this.education,
    required this.skills,
    required this.languages,
    required this.interests,
    required this.bullet,
    required this.star,
    required this.calendar,
  });

  final String email;
  final String phone;
  final String location;
  final String web;
  final String work;
  final String education;
  final String skills;
  final String languages;
  final String interests;
  final String bullet;
  final String star;
  final String calendar;
}
