import 'package:flutter/material.dart';
import '../models/cv_data.dart';
import '../models/cv_template.dart';
import '../models/cover_letter_template.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/interest.dart';
import '../models/user_data/language.dart';
import '../providers/user_data_provider.dart';
import '../utils/data_converters.dart';
import '../localization/app_localizations.dart';

/// Service for auto-filling CV and cover letter templates from user profile
class ProfileAutofillService {
  final UserDataProvider userDataProvider;

  ProfileAutofillService(this.userDataProvider);

  /// Check if user profile has enough data to be useful
  bool isProfileConfigured() {
    final info = userDataProvider.personalInfo;
    if (info == null) return false;

    // Profile is considered configured if it has at least name and one contact method
    return info.fullName.isNotEmpty &&
        (info.email != null || info.phone != null);
  }

  /// Get contact details from profile
  ContactDetails? getContactDetails() {
    final info = userDataProvider.personalInfo;
    if (info == null) return null;
    return DataConverters.personalInfoToContactDetails(info);
  }

  /// Get skills from profile
  List<Skill> getSkills() {
    return userDataProvider.skills;
  }

  /// Get interests from profile
  List<Interest> getInterests() {
    return userDataProvider.interests;
  }

  /// Get languages from profile
  List<Language> getLanguages() {
    return userDataProvider.languages;
  }

  /// Get profile summary
  String? getProfileSummary() {
    return userDataProvider.profileSummary.isNotEmpty
        ? userDataProvider.profileSummary
        : null;
  }

  /// Auto-fill CV template with profile data
  CvTemplate autofillCvTemplate(CvTemplate template) {
    final contactDetails = getContactDetails();
    final skills = getSkills();
    final interests = getInterests();
    final languages = getLanguages();
    final profileSummary = getProfileSummary();

    return template.copyWith(
      contactDetails: contactDetails ?? template.contactDetails,
      profile: profileSummary ?? template.profile,
      skills: skills.isNotEmpty
          ? DataConverters.skillsToStrings(skills)
          : template.skills,
      interests: interests.isNotEmpty
          ? DataConverters.interestsToStrings(interests)
          : template.interests,
      languages: languages.isNotEmpty
          ? DataConverters.languagesToLanguageSkills(languages)
          : template.languages,
    );
  }

  /// Auto-fill cover letter template with profile data (sender name only)
  /// Note: Contact details (email, phone, address) are passed separately when generating PDFs
  CoverLetterTemplate autofillCoverLetterTemplate(
      CoverLetterTemplate template) {
    final info = userDataProvider.personalInfo;
    if (info == null) return template;

    return template.copyWith(
      senderName:
          info.fullName.isNotEmpty ? info.fullName : template.senderName,
    );
  }

  /// Show confirmation dialog before auto-filling
  Future<bool> showAutofillDialog(
    BuildContext context, {
    required String title,
    required List<String> fieldsToFill,
  }) async {
    if (!isProfileConfigured()) {
      // Show warning if profile is not configured
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 48,
          ),
          title: Text(dialogContext.tr('profile_not_configured')),
          content: Text(
            dialogContext.tr('profile_not_configured_message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.tr('ok')),
            ),
          ],
        ),
      );
      return false;
    }

    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.auto_fix_high,
          color: Theme.of(dialogContext).colorScheme.primary,
          size: 48,
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContext.tr('autofill_confirmation_message'),
            ),
            const SizedBox(height: 16),
            ...fieldsToFill.map(
              (field) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(field),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dialogContext.tr('autofill_replace_warning'),
              style: TextStyle(
                color: Theme.of(dialogContext).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: Text(dialogContext.tr('use_profile_data')),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show success snackbar after auto-fill
  void showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Text(context.tr('profile_data_applied')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get a summary of what data is available in the profile
  Map<String, bool> getProfileDataAvailability() {
    final info = userDataProvider.personalInfo;
    return {
      'name': info?.fullName.isNotEmpty ?? false,
      'email': info?.email != null && info!.email!.isNotEmpty,
      'phone': info?.phone != null && info!.phone!.isNotEmpty,
      'address': info?.address != null && info!.address!.isNotEmpty,
      'profileSummary': userDataProvider.profileSummary.isNotEmpty,
      'skills': userDataProvider.skills.isNotEmpty,
      'interests': userDataProvider.interests.isNotEmpty,
      'languages': userDataProvider.languages.isNotEmpty,
    };
  }
}
