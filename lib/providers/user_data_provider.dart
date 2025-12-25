import 'package:flutter/foundation.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../services/user_data_service.dart';

/// Provider for user data management
class UserDataProvider with ChangeNotifier {
  final UserDataService _service = UserDataService();

  // Getters
  PersonalInfo? get personalInfo => _service.personalInfo;
  List<Skill> get skills => _service.skills;
  List<WorkExperience> get workExperiences => _service.workExperiences;
  List<Language> get languages => _service.languages;
  List<Interest> get interests => _service.interests;

  /// Load all user data
  Future<void> loadAll() async {
    await _service.loadAll();
    notifyListeners();
  }

  // Personal Info Methods
  Future<void> updatePersonalInfo(PersonalInfo info) async {
    await _service.updatePersonalInfo(info);
    notifyListeners();
  }

  // Skills Methods
  Future<void> addSkill(Skill skill) async {
    await _service.addSkill(skill);
    notifyListeners();
  }

  Future<void> updateSkill(Skill skill) async {
    await _service.updateSkill(skill);
    notifyListeners();
  }

  Future<void> deleteSkill(String id) async {
    await _service.deleteSkill(id);
    notifyListeners();
  }

  // Work Experience Methods
  Future<void> addWorkExperience(WorkExperience experience) async {
    await _service.addWorkExperience(experience);
    notifyListeners();
  }

  Future<void> updateWorkExperience(WorkExperience experience) async {
    await _service.updateWorkExperience(experience);
    notifyListeners();
  }

  Future<void> deleteWorkExperience(String id) async {
    await _service.deleteWorkExperience(id);
    notifyListeners();
  }

  // Language Methods
  Future<void> addLanguage(Language language) async {
    await _service.addLanguage(language);
    notifyListeners();
  }

  Future<void> updateLanguage(Language language) async {
    await _service.updateLanguage(language);
    notifyListeners();
  }

  Future<void> deleteLanguage(String id) async {
    await _service.deleteLanguage(id);
    notifyListeners();
  }

  // Interest Methods
  Future<void> addInterest(Interest interest) async {
    await _service.addInterest(interest);
    notifyListeners();
  }

  Future<void> updateInterest(Interest interest) async {
    await _service.updateInterest(interest);
    notifyListeners();
  }

  Future<void> deleteInterest(String id) async {
    await _service.deleteInterest(id);
    notifyListeners();
  }

  /// Clear all user data
  Future<void> clearAll() async {
    await _service.clearAll();
    notifyListeners();
  }

  /// Get skills by category
  List<Skill> getSkillsByCategory(String? category) {
    if (category == null) return skills;
    return skills.where((s) => s.category == category).toList();
  }

  /// Get work experiences sorted by date (most recent first)
  List<WorkExperience> get sortedWorkExperiences {
    final sorted = List<WorkExperience>.from(workExperiences);
    sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  /// Get current work experiences
  List<WorkExperience> get currentWorkExperiences {
    return workExperiences.where((e) => e.isCurrent).toList();
  }
}
