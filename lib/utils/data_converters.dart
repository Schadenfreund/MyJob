import 'package:flutter/material.dart' show Color;
import '../models/cv_data.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/interest.dart';
import '../models/user_data/language.dart';

/// Utility class for converting between user_data models and cv_data models
/// Bridges PersonalInfo/Skill/Interest/Language <-> ContactDetails/String lists
class DataConverters {
  /// Convert PersonalInfo to ContactDetails for CV/Cover Letter
  static ContactDetails personalInfoToContactDetails(PersonalInfo info) {
    // Combine address components if available
    String? fullAddress;
    if (info.address != null) {
      final parts = <String>[];
      if (info.address!.isNotEmpty) parts.add(info.address!);
      if (info.city != null && info.city!.isNotEmpty) parts.add(info.city!);
      if (info.country != null && info.country!.isNotEmpty) parts.add(info.country!);
      fullAddress = parts.isNotEmpty ? parts.join(', ') : null;
    }

    return ContactDetails(
      fullName: info.fullName,
      email: info.email,
      phone: info.phone,
      address: fullAddress,
      linkedin: null, // PersonalInfo doesn't have LinkedIn, can be added later
      website: null,  // PersonalInfo doesn't have website, can be added later
    );
  }

  /// Convert ContactDetails back to PersonalInfo (for migration)
  static PersonalInfo contactDetailsToPersonalInfo(
    ContactDetails contact, {
    String? profileSummary,
    String? id,
  }) {
    // Try to split address into components
    String? address;
    String? city;
    String? country;

    if (contact.address != null) {
      final parts = contact.address!.split(',').map((p) => p.trim()).toList();
      if (parts.length >= 3) {
        address = parts[0];
        city = parts[1];
        country = parts[2];
      } else if (parts.length == 2) {
        address = parts[0];
        city = parts[1];
      } else {
        address = contact.address;
      }
    }

    return PersonalInfo(
      id: id,
      fullName: contact.fullName,
      profileSummary: profileSummary,
      email: contact.email,
      phone: contact.phone,
      address: address,
      city: city,
      country: country,
    );
  }

  /// Convert List<Skill> to List<String> for backward compatibility
  /// Includes level information in format: "Skill Name (Level)"
  static List<String> skillsToStrings(List<Skill> skills) {
    return skills.map((skill) {
      if (skill.level != null) {
        return '${skill.name} (${skill.level!.displayName})';
      }
      return skill.name;
    }).toList();
  }

  /// Parse skill strings back to Skill objects
  /// Handles both "Skill Name" and "Skill Name (Level)" formats
  static List<Skill> parseSkillStrings(List<String> skillStrings) {
    return skillStrings.map((str) {
      str = str.trim();
      if (str.isEmpty) return null;

      // Check if string contains level info in parentheses
      final match = RegExp(r'^(.+)\s*\((.+)\)$').firstMatch(str);
      if (match != null) {
        final name = match.group(1)!.trim();
        final levelStr = match.group(2)!.trim().toLowerCase();

        SkillLevel? level;
        for (final lvl in SkillLevel.values) {
          if (lvl.displayName.toLowerCase() == levelStr) {
            level = lvl;
            break;
          }
        }

        return Skill(
          name: name,
          level: level ?? SkillLevel.intermediate,
        );
      }

      // Plain skill name without level
      return Skill(name: str);
    }).whereType<Skill>().toList();
  }

  /// Convert List<Interest> to List<String> for backward compatibility
  static List<String> interestsToStrings(List<Interest> interests) {
    return interests.map((interest) => interest.name).toList();
  }

  /// Parse interest strings back to Interest objects
  static List<Interest> parseInterestStrings(List<String> interestStrings) {
    return interestStrings
        .map((str) => str.trim())
        .where((str) => str.isNotEmpty)
        .map((str) => Interest(name: str))
        .toList();
  }

  /// Convert user_data Language list to cv_data LanguageSkill list
  static List<LanguageSkill> languagesToLanguageSkills(List<Language> languages) {
    return languages.map((lang) {
      return LanguageSkill(
        language: lang.name,
        level: lang.proficiency.displayName,
      );
    }).toList();
  }

  /// Convert cv_data LanguageSkill list to user_data Language list
  static List<Language> languageSkillsToLanguages(List<LanguageSkill> languageSkills) {
    return languageSkills.map((skill) {
      // Try to map level string to LanguageProficiency enum
      LanguageProficiency? proficiency;
      final levelLower = skill.level.toLowerCase();

      for (final prof in LanguageProficiency.values) {
        if (prof.displayName.toLowerCase() == levelLower) {
          proficiency = prof;
          break;
        }
      }

      return Language(
        name: skill.language,
        proficiency: proficiency ?? LanguageProficiency.intermediate,
      );
    }).toList();
  }

  /// Get skill level color for UI display
  static Color getSkillLevelColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return const Color(0xFF9E9E9E); // Grey
      case SkillLevel.intermediate:
        return const Color(0xFF2196F3); // Blue
      case SkillLevel.advanced:
        return const Color(0xFF4CAF50); // Green
      case SkillLevel.expert:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  /// Get language proficiency color for UI display
  static Color getLanguageProficiencyColor(LanguageProficiency proficiency) {
    switch (proficiency) {
      case LanguageProficiency.basic:
        return const Color(0xFF9E9E9E); // Grey
      case LanguageProficiency.intermediate:
        return const Color(0xFF2196F3); // Blue
      case LanguageProficiency.advanced:
        return const Color(0xFF4CAF50); // Green
      case LanguageProficiency.fluent:
        return const Color(0xFF9C27B0); // Purple
      case LanguageProficiency.native:
        return const Color(0xFFFF9800); // Orange
    }
  }
}
