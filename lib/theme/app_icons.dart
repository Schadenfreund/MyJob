import 'package:flutter/material.dart';

/// Centralized icon references for MyJob.
/// Match MyTemplate design guide while maintaining job-specific icons.
class AppIcons {
  // System / Tab Navigation
  static const IconData profile = Icons.person_outline_rounded;
  static const IconData applications = Icons.work_outline_rounded;
  static const IconData documents = Icons.description_outlined;
  static const IconData analytics = Icons.bar_chart_rounded;
  static const IconData settings = Icons.settings_outlined;

  // Common UI Actions
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData save = Icons.save_outlined;
  static const IconData search = Icons.search_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData folder = Icons.folder_outlined;
  static const IconData pdf = Icons.picture_as_pdf_outlined;
  static const IconData email = Icons.email_outlined;
  static const IconData preview = Icons.visibility_outlined;

  // Section Icons
  static const IconData personalInfo = Icons.person_rounded;
  static const IconData experience = Icons.work_rounded;
  static const IconData education = Icons.school_rounded;
  static const IconData skills = Icons.star_rounded;
  static const IconData languages = Icons.language_rounded;
  static const IconData interests = Icons.favorite_rounded;
  static const IconData summary = Icons.description_rounded;
  static const IconData coverLetter = Icons.mail_rounded;

  // Status Icons
  static const IconData draft = Icons.edit_document;
  static const IconData applied = Icons.send_rounded;
  static const IconData interviewing = Icons.forum_rounded;
  static const IconData successful = Icons.check_circle_rounded;
  static const IconData rejected = Icons.cancel_rounded;
  static const IconData noResponse = Icons.timer_off_rounded;

  // Assets Paths
  static const String appLogo = 'assets/icons/app_logo.png';
  static const String appIcon = 'assets/icons/app_icon.ico';
}
