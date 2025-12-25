import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';

/// Service for managing user data (personal info, skills, experience, etc.)
class UserDataService {
  static const String _userDataFileName = 'user_data.json';

  PersonalInfo? _personalInfo;
  List<Skill> _skills = [];
  List<WorkExperience> _workExperiences = [];
  List<Language> _languages = [];
  List<Interest> _interests = [];

  // Getters
  PersonalInfo? get personalInfo => _personalInfo;
  List<Skill> get skills => List.unmodifiable(_skills);
  List<WorkExperience> get workExperiences =>
      List.unmodifiable(_workExperiences);
  List<Language> get languages => List.unmodifiable(_languages);
  List<Interest> get interests => List.unmodifiable(_interests);

  /// Load all user data from storage
  Future<void> loadAll() async {
    try {
      final file = await _getUserDataFile();
      if (!await file.exists()) {
        return;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Load personal info
      if (json['personalInfo'] != null) {
        _personalInfo =
            PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>);
      }

      // Load skills
      if (json['skills'] != null) {
        _skills = (json['skills'] as List<dynamic>)
            .map((e) => Skill.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load work experiences
      if (json['workExperiences'] != null) {
        _workExperiences = (json['workExperiences'] as List<dynamic>)
            .map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load languages
      if (json['languages'] != null) {
        _languages = (json['languages'] as List<dynamic>)
            .map((e) => Language.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load interests
      if (json['interests'] != null) {
        _interests = (json['interests'] as List<dynamic>)
            .map((e) => Interest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  /// Save all user data to storage
  Future<void> saveAll() async {
    try {
      final json = {
        'personalInfo': _personalInfo?.toJson(),
        'skills': _skills.map((e) => e.toJson()).toList(),
        'workExperiences': _workExperiences.map((e) => e.toJson()).toList(),
        'languages': _languages.map((e) => e.toJson()).toList(),
        'interests': _interests.map((e) => e.toJson()).toList(),
      };

      final file = await _getUserDataFile();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Personal Info Methods
  Future<void> updatePersonalInfo(PersonalInfo info) async {
    _personalInfo = info;
    await saveAll();
  }

  // Skills Methods
  Future<void> addSkill(Skill skill) async {
    _skills.add(skill);
    await saveAll();
  }

  Future<void> updateSkill(Skill skill) async {
    final index = _skills.indexWhere((s) => s.id == skill.id);
    if (index != -1) {
      _skills[index] = skill;
      await saveAll();
    }
  }

  Future<void> deleteSkill(String id) async {
    _skills.removeWhere((s) => s.id == id);
    await saveAll();
  }

  // Work Experience Methods
  Future<void> addWorkExperience(WorkExperience experience) async {
    _workExperiences.add(experience);
    await saveAll();
  }

  Future<void> updateWorkExperience(WorkExperience experience) async {
    final index = _workExperiences.indexWhere((e) => e.id == experience.id);
    if (index != -1) {
      _workExperiences[index] = experience;
      await saveAll();
    }
  }

  Future<void> deleteWorkExperience(String id) async {
    _workExperiences.removeWhere((e) => e.id == id);
    await saveAll();
  }

  // Language Methods
  Future<void> addLanguage(Language language) async {
    _languages.add(language);
    await saveAll();
  }

  Future<void> updateLanguage(Language language) async {
    final index = _languages.indexWhere((l) => l.id == language.id);
    if (index != -1) {
      _languages[index] = language;
      await saveAll();
    }
  }

  Future<void> deleteLanguage(String id) async {
    _languages.removeWhere((l) => l.id == id);
    await saveAll();
  }

  // Interest Methods
  Future<void> addInterest(Interest interest) async {
    _interests.add(interest);
    await saveAll();
  }

  Future<void> updateInterest(Interest interest) async {
    final index = _interests.indexWhere((i) => i.id == interest.id);
    if (index != -1) {
      _interests[index] = interest;
      await saveAll();
    }
  }

  Future<void> deleteInterest(String id) async {
    _interests.removeWhere((i) => i.id == id);
    await saveAll();
  }

  /// Get user data file
  Future<File> _getUserDataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_userDataFileName');
  }

  /// Clear all user data
  Future<void> clearAll() async {
    _personalInfo = null;
    _skills = [];
    _workExperiences = [];
    _languages = [];
    _interests = [];
    await saveAll();
  }
}
