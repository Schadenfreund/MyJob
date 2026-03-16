import 'package:flutter/foundation.dart';
import '../models/master_profile.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

/// Provider for dynamic multilingual user profile management
///
/// Manages profiles for any number of languages. Each profile is completely
/// independent and stored in profiles/{langCode}/. Profiles are auto-discovered
/// from the file system on load.
class UserDataProvider with ChangeNotifier {
  final _profileRepo = StorageService.instance.profiles;

  // Dynamic profile map keyed by language code (e.g. 'en', 'de', 'hr')
  final Map<String, MasterProfile?> _profiles = {};
  String _currentLanguageCode = 'en';

  /// Called whenever the active language code changes (switch or new profile).
  /// Wired once at app startup to sync the UI language.
  Future<void> Function(String langCode)? _onLanguageSwitch;
  void setLanguageSwitchCallback(Future<void> Function(String) callback) {
    _onLanguageSwitch = callback;
  }

  // Getters for current profile data
  /// Backward-compat getter for code that still uses DocumentLanguage
  DocumentLanguage get currentLanguage =>
      DocumentLanguage.fromCode(_currentLanguageCode);
  String get currentLanguageCode => _currentLanguageCode;
  List<String> get profileLanguageCodes => _profiles.keys.toList();

  MasterProfile? get currentProfile => _profiles[_currentLanguageCode];

  PersonalInfo? get personalInfo => currentProfile?.personalInfo;
  List<WorkExperience> get experiences => currentProfile?.experiences ?? [];
  List<Education> get education => currentProfile?.education ?? [];
  List<Skill> get skills => currentProfile?.skills ?? [];
  List<Language> get languages => currentProfile?.languages ?? [];
  List<Interest> get interests => currentProfile?.interests ?? [];
  String get profileSummary => currentProfile?.profileSummary ?? '';
  String get defaultCoverLetterBody =>
      currentProfile?.defaultCoverLetterBody ?? '';

  bool get hasData {
    final profile = currentProfile;
    if (profile == null) return false;

    return profile.personalInfo != null ||
        profile.experiences.isNotEmpty ||
        profile.education.isNotEmpty ||
        profile.skills.isNotEmpty ||
        profile.languages.isNotEmpty ||
        profile.interests.isNotEmpty ||
        profile.profileSummary.isNotEmpty ||
        profile.defaultCoverLetterBody.isNotEmpty;
  }

  /// Get the profile for a specific DocumentLanguage (backward compat)
  MasterProfile? getProfileForLanguage(DocumentLanguage language) {
    return _profiles[language.code];
  }

  /// Load all profiles by discovering them from the file system
  Future<void> loadAll() async {
    _profiles.clear();
    final codes = await _profileRepo.discoverLanguageCodes();
    for (final code in codes) {
      _profiles[code] = await _profileRepo.load(code);
    }
    // If current code not in discovered profiles, switch to first available
    if (_profiles.isNotEmpty && !_profiles.containsKey(_currentLanguageCode)) {
      _currentLanguageCode = _profiles.keys.first;
    }
    notifyListeners();
  }

  /// Switch to a profile by language code
  Future<void> switchProfile(String langCode) async {
    if (_currentLanguageCode == langCode) return;
    _currentLanguageCode = langCode;
    notifyListeners();
    await _onLanguageSwitch?.call(langCode);
  }

  /// Switch active language (backward compat wrapper)
  Future<void> switchLanguage(DocumentLanguage language) =>
      switchProfile(language.code);

  /// Add a new profile for a language code
  Future<void> addProfile(String langCode) async {
    final profile = MasterProfile.empty(langCode);
    _profiles[langCode] = profile;
    _currentLanguageCode = langCode;
    await _profileRepo.save(profile);
    notifyListeners();
    await _onLanguageSwitch?.call(langCode);
  }

  /// Delete a profile entirely (removes folder from disk)
  Future<void> deleteProfile(String langCode) async {
    _profiles.remove(langCode);
    await _profileRepo.deleteFolder(langCode);
    if (_currentLanguageCode == langCode) {
      _currentLanguageCode =
          _profiles.isNotEmpty ? _profiles.keys.first : 'en';
    }
    notifyListeners();
  }

  /// Update personal info for current language
  Future<void> updatePersonalInfo(PersonalInfo info) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(personalInfo: info);
    await _saveProfile(updated);
  }

  /// Update default cover letter body
  Future<void> updateDefaultCoverLetterBody(String body) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(defaultCoverLetterBody: body);
    await _saveProfile(updated);
  }

  /// Update profile summary
  Future<void> updateProfileSummary(String summary) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(profileSummary: summary);
    await _saveProfile(updated);
  }

  /// Add experience
  Future<void> addExperience(WorkExperience experience) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      experiences: [...profile.experiences, experience],
    );
    await _saveProfile(updated);
  }

  /// Update experience
  Future<void> updateExperience(WorkExperience experience) async {
    final profile = currentProfile;
    if (profile == null) return;

    final experiences = List<WorkExperience>.from(profile.experiences);
    final index = experiences.indexWhere((e) => e.id == experience.id);
    if (index != -1) {
      experiences[index] = experience;
      final updated = profile.copyWith(experiences: experiences);
      await _saveProfile(updated);
    }
  }

  /// Delete experience
  Future<void> deleteExperience(String id) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      experiences: profile.experiences.where((e) => e.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add education
  Future<void> addEducation(Education edu) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      education: [...profile.education, edu],
    );
    await _saveProfile(updated);
  }

  /// Update education
  Future<void> updateEducation(Education edu) async {
    final profile = currentProfile;
    if (profile == null) return;

    final education = List<Education>.from(profile.education);
    final index = education.indexWhere((e) => e.id == edu.id);
    if (index != -1) {
      education[index] = edu;
      final updated = profile.copyWith(education: education);
      await _saveProfile(updated);
    }
  }

  /// Delete education
  Future<void> deleteEducation(String id) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      education: profile.education.where((e) => e.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add skill
  Future<void> addSkill(Skill skill) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      skills: [...profile.skills, skill],
    );
    await _saveProfile(updated);
  }

  /// Update skill
  Future<void> updateSkill(Skill skill) async {
    final profile = currentProfile;
    if (profile == null) return;

    final skills = List<Skill>.from(profile.skills);
    final index = skills.indexWhere((s) => s.id == skill.id);
    if (index != -1) {
      skills[index] = skill;
      final updated = profile.copyWith(skills: skills);
      await _saveProfile(updated);
    }
  }

  /// Delete skill
  Future<void> deleteSkill(String id) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      skills: profile.skills.where((s) => s.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add language
  Future<void> addLanguage(Language language) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      languages: [...profile.languages, language],
    );
    await _saveProfile(updated);
  }

  /// Update language
  Future<void> updateLanguage(Language language) async {
    final profile = currentProfile;
    if (profile == null) return;

    final languages = List<Language>.from(profile.languages);
    final index = languages.indexWhere((l) => l.id == language.id);
    if (index != -1) {
      languages[index] = language;
      final updated = profile.copyWith(languages: languages);
      await _saveProfile(updated);
    }
  }

  /// Delete language
  Future<void> deleteLanguage(String id) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      languages: profile.languages.where((l) => l.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add interest
  Future<void> addInterest(Interest interest) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      interests: [...profile.interests, interest],
    );
    await _saveProfile(updated);
  }

  /// Update interest
  Future<void> updateInterest(Interest interest) async {
    final profile = currentProfile;
    if (profile == null) return;

    final interests = List<Interest>.from(profile.interests);
    final index = interests.indexWhere((i) => i.id == interest.id);
    if (index != -1) {
      interests[index] = interest;
      final updated = profile.copyWith(interests: interests);
      await _saveProfile(updated);
    }
  }

  /// Delete interest
  Future<void> deleteInterest(String id) async {
    final profile = currentProfile;
    if (profile == null) return;

    final updated = profile.copyWith(
      interests: profile.interests.where((i) => i.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Save the updated profile
  Future<void> _saveProfile(MasterProfile profile) async {
    _profiles[profile.language] = profile;
    await _profileRepo.save(profile);
    notifyListeners();
  }

  /// Clear current profile data (resets to empty, keeps the profile slot)
  Future<void> clearCurrentProfile() async {
    final empty = MasterProfile.empty(_currentLanguageCode);
    await _saveProfile(empty);
  }

  /// Get skills by category
  List<Skill> getSkillsByCategory(String? category) {
    if (category == null) return skills;
    return skills.where((s) => s.category == category).toList();
  }

  /// Get work experiences sorted by date (most recent first)
  List<WorkExperience> get sortedExperiences {
    final sorted = List<WorkExperience>.from(experiences);
    sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  /// Get current work experiences
  List<WorkExperience> get currentExperiences {
    return experiences.where((e) => e.isCurrent).toList();
  }

}
