import 'package:flutter/foundation.dart';
import '../models/master_profile.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

/// Provider for bilingual user profile management
///
/// Manages two separate master profiles (English and German) and allows
/// switching between them. Each profile is completely independent.
class UserDataProvider with ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  // Current active language and profile
  DocumentLanguage _currentLanguage = DocumentLanguage.en;
  MasterProfile? _enProfile;
  MasterProfile? _deProfile;

  // Getters for current profile data
  DocumentLanguage get currentLanguage => _currentLanguage;
  MasterProfile? get currentProfile => _getCurrentProfile();

  PersonalInfo? get personalInfo => currentProfile?.personalInfo;
  List<WorkExperience> get experiences => currentProfile?.experiences ?? [];
  List<Education> get education => currentProfile?.education ?? [];
  List<Skill> get skills => currentProfile?.skills ?? [];
  List<Language> get languages => currentProfile?.languages ?? [];
  List<Interest> get interests => currentProfile?.interests ?? [];
  String get defaultCoverLetterBody =>
      currentProfile?.defaultCoverLetterBody ?? '';

  /// Get the current active profile
  MasterProfile? _getCurrentProfile() {
    return _currentLanguage == DocumentLanguage.en ? _enProfile : _deProfile;
  }

  /// Load all profiles
  Future<void> loadAll() async {
    _enProfile = await _storage.loadMasterProfile(DocumentLanguage.en);
    _deProfile = await _storage.loadMasterProfile(DocumentLanguage.de);
    notifyListeners();
  }

  /// Switch active language
  Future<void> switchLanguage(DocumentLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();
  }

  /// Update personal info for current language
  Future<void> updatePersonalInfo(PersonalInfo info) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(personalInfo: info);
    await _saveProfile(updated);
  }

  /// Update default cover letter body
  Future<void> updateDefaultCoverLetterBody(String body) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(defaultCoverLetterBody: body);
    await _saveProfile(updated);
  }

  /// Add experience
  Future<void> addExperience(WorkExperience experience) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      experiences: [...profile.experiences, experience],
    );
    await _saveProfile(updated);
  }

  /// Update experience
  Future<void> updateExperience(WorkExperience experience) async {
    final profile = _getCurrentProfile();
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
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      experiences: profile.experiences.where((e) => e.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add education
  Future<void> addEducation(Education edu) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      education: [...profile.education, edu],
    );
    await _saveProfile(updated);
  }

  /// Update education
  Future<void> updateEducation(Education edu) async {
    final profile = _getCurrentProfile();
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
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      education: profile.education.where((e) => e.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add skill
  Future<void> addSkill(Skill skill) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      skills: [...profile.skills, skill],
    );
    await _saveProfile(updated);
  }

  /// Update skill
  Future<void> updateSkill(Skill skill) async {
    final profile = _getCurrentProfile();
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
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      skills: profile.skills.where((s) => s.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add language
  Future<void> addLanguage(Language language) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      languages: [...profile.languages, language],
    );
    await _saveProfile(updated);
  }

  /// Update language
  Future<void> updateLanguage(Language language) async {
    final profile = _getCurrentProfile();
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
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      languages: profile.languages.where((l) => l.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Add interest
  Future<void> addInterest(Interest interest) async {
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      interests: [...profile.interests, interest],
    );
    await _saveProfile(updated);
  }

  /// Update interest
  Future<void> updateInterest(Interest interest) async {
    final profile = _getCurrentProfile();
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
    final profile = _getCurrentProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      interests: profile.interests.where((i) => i.id != id).toList(),
    );
    await _saveProfile(updated);
  }

  /// Save the updated profile
  Future<void> _saveProfile(MasterProfile profile) async {
    if (profile.language == DocumentLanguage.en) {
      _enProfile = profile;
    } else {
      _deProfile = profile;
    }

    await _storage.saveMasterProfile(profile);
    notifyListeners();
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

  /// Legacy compatibility - map old method names
  @Deprecated('Use experiences instead')
  List<WorkExperience> get workExperiences => experiences;

  @Deprecated('Use addExperience instead')
  Future<void> addWorkExperience(WorkExperience experience) =>
      addExperience(experience);

  @Deprecated('Use updateExperience instead')
  Future<void> updateWorkExperience(WorkExperience experience) =>
      updateExperience(experience);

  @Deprecated('Use deleteExperience instead')
  Future<void> deleteWorkExperience(String id) => deleteExperience(id);

  @Deprecated('Use sortedExperiences instead')
  List<WorkExperience> get sortedWorkExperiences => sortedExperiences;

  @Deprecated('Use currentExperiences instead')
  List<WorkExperience> get currentWorkExperiences => currentExperiences;
}
