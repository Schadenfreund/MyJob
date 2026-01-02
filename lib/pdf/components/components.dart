/// PDF Components - Reusable component library for PDF templates
///
/// This library provides a comprehensive set of components for building
/// professional PDF documents (CVs, cover letters, etc.) with consistent
/// styling and flexible layouts.
///
/// ## Components Overview
///
/// ### Icon Component
/// - Wrapper for icon rendering with preset sizes and themes
/// - Contact icons, bullets, badges, and section icons
/// - Multiple icon styles: inline, badge, icon-only
///
/// ### Header Component
/// - Professional headers for CV and Cover Letters
/// - Multiple layouts: modern, clean, sidebar, compact
/// - Support for profile images and contact info
///
/// ### Section Component
/// - Consistent section headers across all layouts
/// - Multiple styles: accent, minimal, underline, boxed
/// - Dividers and section containers
///
/// ### Experience Component
/// - Flexible experience rendering
/// - Multiple layouts: timeline, list, cards, compact
/// - Timeline visualization with connecting lines
///
/// ### Education Component
/// - Professional education rendering
/// - Standard, compact, and card layouts
/// - Clean formatting with icons
///
/// ### Skills Component
/// - Beautiful skill visualization
/// - Tags, proficiency bars, and grid layouts
/// - Support for categorized skills
///
/// ### Contact Component
/// - Contact information with icons
/// - Multiple layouts: wrap, row, column, grid
/// - Sidebar and compact modes
///
/// ### Layout Component
/// - Page layout helpers
/// - Two-column and three-column layouts
/// - Responsive grids and card containers
///
/// ## Usage Example
///
/// ```dart
/// import 'package:mylife/pdf/components/components.dart';
///
/// // Build a CV header
/// HeaderComponent.cvHeader(
///   name: 'John Doe',
///   title: 'Software Engineer',
///   contact: contactDetails,
///   styling: styling,
///   layout: HeaderLayout.modern,
/// )
///
/// // Build a section with experiences
/// SectionComponent.section(
///   title: 'Experience',
///   content: ExperienceComponent.section(
///     experiences: experiences,
///     styling: styling,
///     layout: ExperienceLayout.timeline,
///   ),
///   styling: styling,
///   iconType: 'work',
/// )
/// ```

library;

// Export all components
export 'icon_component.dart';
export 'header_component.dart';
export 'section_component.dart';
export 'experience_component.dart';
export 'education_component.dart';
export 'skills_component.dart';
export 'contact_component.dart';
export 'layout_component.dart';
