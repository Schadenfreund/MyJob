# Code Cleanup & Refactoring Plan

**Analysis Date:** 2026-01-10
**Total Files Analyzed:** 117 Dart files
**Total Issues Found:** 20 major issues
**Estimated Dead/Duplicate Code:** ~1,500-2,000 lines

---

## Executive Summary

This document contains a comprehensive analysis of code quality issues in the MyLife Flutter application, focusing on:
- Dead code and unused files
- DRY (Don't Repeat Yourself) principle violations
- Code quality and maintainability issues

---

## 1. CRITICAL ISSUES (3)

### 1.1 Status Helper Methods Duplicated (3x)

**Severity:** 🔴 CRITICAL
**Code Duplication:** ~150 lines

**Files Affected:**
- [lib/widgets/status_chip.dart](lib/widgets/status_chip.dart#L54-L103)
- [lib/widgets/status_badge.dart](lib/widgets/status_badge.dart#L16-L48)
- [lib/screens/applications/widgets/compact_application_card.dart](lib/screens/applications/widgets/compact_application_card.dart#L48-L97)

**Issue:**
Three separate implementations of the same status mapping logic:
- `_getStatusColor()` - duplicated 3 times with different color values
- `_getStatusIcon()` - duplicated 3 times with slightly different icons
- `_getStatusLabel()` - duplicated 3 times

**Recommended Solution:**
Create a centralized utility class:
```dart
// lib/utils/application_status_helper.dart
class ApplicationStatusHelper {
  static Color getColor(ApplicationStatus status) { ... }
  static IconData getIcon(ApplicationStatus status) { ... }
  static String getLabel(ApplicationStatus status) { ... }
}
```

---

### 1.2 UserData Path Retrieval Duplicated (5x)

**Severity:** 🔴 CRITICAL
**Code Duplication:** ~100 lines

**Files Affected:**
- [lib/services/storage_service.dart](lib/services/storage_service.dart#L23-L50)
- [lib/services/templates_storage_service.dart](lib/services/templates_storage_service.dart#L17-L44)
- [lib/services/settings_service.dart](lib/services/settings_service.dart#L22-L33)
- [lib/services/customization_persistence.dart](lib/services/customization_persistence.dart#L13-L16)
- [lib/services/preferences_service.dart](lib/services/preferences_service.dart#L15-L18)

**Issue:**
The same logic to get `UserData` folder path is implemented 5 times:
```dart
final exePath = Platform.resolvedExecutable;
final exeDir = p.dirname(exePath);
final userDataPath = p.join(exeDir, 'UserData');
```

**Recommended Solution:**
Create a single `PathService` or extract to a shared base class/constant.

---

### 1.3 Inconsistent Error Handling

**Severity:** 🔴 CRITICAL
**Occurrences:** 50+ locations

**Files Affected:**
- [lib/services/preferences_service.dart](lib/services/preferences_service.dart#L50) - uses `print()`
- Multiple files - mix of `print()`, `debugPrint()`, and `LogService`

**Issue:**
Inconsistent error handling and logging patterns across the codebase. Some files use `print()`, others use `debugPrint()`, and some use the proper `LogService`.

**Recommended Solution:**
Standardize on `LogService` throughout the entire application.

---

## 2. HIGH PRIORITY ISSUES (7)

### 2.1 Unused/Legacy Service: TemplatesStorageService

**Severity:** 🟠 HIGH
**File Size:** 502 lines
**File:** [lib/services/templates_storage_service.dart](lib/services/templates_storage_service.dart)

**Issue:**
This entire service appears to be legacy code for managing CV/Cover Letter templates and instances. Only 5 references across the entire codebase. The app now uses a different architecture (folder-based per job application).

**Services Managed:**
- `cv_templates`
- `cv_instances`
- `cover_letter_templates`
- `cover_letter_instances`

**Recommended Action:**
Remove this file and migrate any remaining functionality to `StorageService`.

---

### 2.2 Dialog Structure Duplication

**Severity:** 🟠 HIGH
**Code Duplication:** ~200 lines of shared structure

**Files Affected:**
- [lib/dialogs/experience_edit_dialog.dart](lib/dialogs/experience_edit_dialog.dart) (455 lines)
- [lib/dialogs/education_edit_dialog.dart](lib/dialogs/education_edit_dialog.dart) (311 lines)
- [lib/dialogs/interest_edit_dialog.dart](lib/dialogs/interest_edit_dialog.dart) (126 lines)

**Issue:**
Nearly identical dialog structure with:
- Same header layout (lines 136-170 in experience, 136-170 in education)
- Same form validation pattern
- Same save/cancel button layout (lines 348-368 in experience, 284-304 in education)
- Same date picker logic (lines 99-121 in both)

**Recommended Solution:**
Create a `BaseEditDialog` abstract class or a dialog builder utility.

---

### 2.3 StatusChip vs StatusBadge Redundancy

**Severity:** 🟠 HIGH
**Code Duplication:** 210 lines total

**Files Affected:**
- [lib/widgets/status_chip.dart](lib/widgets/status_chip.dart) (105 lines)
- [lib/widgets/status_badge.dart](lib/widgets/status_badge.dart) (105 lines)

**Issue:**
Two nearly identical widgets for displaying application status.

**Differences:**
- StatusChip uses `compact` parameter
- StatusBadge uses `size` enum (small/medium/large)
- Color schemes slightly different

**Recommended Action:**
Merge into single widget with unified API.

---

### 2.4 Tight Coupling in CompactApplicationCard

**Severity:** 🟠 HIGH
**File Size:** 665 lines
**File:** [lib/screens/applications/widgets/compact_application_card.dart](lib/screens/applications/widgets/compact_application_card.dart)

**Issue:**
Single widget handles multiple responsibilities:
- Status management
- UI rendering
- Menu display
- Timeline calculation
- Date formatting

**Recommended Action:**
Split into:
- `CompactApplicationCard` (presentation)
- `ApplicationStatusManager` (status logic)
- `ApplicationTimelineBuilder` (timeline logic)

---

### 2.5 Nested Dialog Classes in TabbedCvEditor

**Severity:** 🟠 HIGH
**Lines:** 892-1123
**File:** [lib/widgets/tabbed_cv_editor.dart](lib/widgets/tabbed_cv_editor.dart#L892-L1123)

**Issue:**
Contains 3 nested dialog classes that duplicate logic from standalone dialogs:
- `_ExperienceDialog`
- `_EducationDialog`
- `_LanguageDialog`

**Recommended Action:**
Use the standalone dialog files instead.

---

### 2.6 File I/O Pattern Repetition

**Severity:** 🟠 HIGH
**Occurrences:** 47 times across services

**Pattern:**
```dart
final file = File(p.join(userDataPath, ...));
if (!file.existsSync()) return null;
final content = await file.readAsString();
final json = jsonDecode(content) as Map<String, dynamic>;
```

**Recommended Solution:**
Create reusable `FileStorageHelper` class with methods:
- `readJsonFile()`
- `writeJsonFile()`
- `deleteFile()`
- `fileExists()`

---

### 2.7 Date Formatting Duplication

**Severity:** 🟠 HIGH
**File:** [lib/screens/applications/widgets/compact_application_card.dart](lib/screens/applications/widgets/compact_application_card.dart#L165-L167)

**Issue:**
Custom date formatting implemented instead of using existing `app_date_utils.dart`:
```dart
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
```

**Recommended Action:**
Use existing date utilities throughout the app.

---

## 3. MEDIUM PRIORITY ISSUES (8)

### 3.1 Underutilized Service: PreferencesService

**Severity:** 🟡 MEDIUM
**File Size:** 120 lines
**File:** [lib/services/preferences_service.dart](lib/services/preferences_service.dart)

**Issue:**
Nearly identical to `CustomizationPersistence` - both manage JSON file persistence in UserData folder. Only 4 references in codebase.

**Recommended Action:**
Consolidate with `CustomizationPersistence` or fully integrate into existing settings system.

---

### 3.2 JSON Encoder Duplication

**Severity:** 🟡 MEDIUM
**Occurrences:** 47 total uses

**Issue:**
`const JsonEncoder.withIndent('  ')` appears in 5 files:
- `storage_service.dart`
- `templates_storage_service.dart`
- `settings_service.dart`
- `customization_persistence.dart`
- `preferences_service.dart`

**Recommended Solution:**
Create a shared constant:
```dart
// lib/constants/json_constants.dart
const prettyJsonEncoder = JsonEncoder.withIndent('  ');
```

---

### 3.3 Deprecated Fields in JobApplication

**Severity:** 🟡 MEDIUM
**File:** [lib/models/job_application.dart](lib/models/job_application.dart#L126-L129)

**Issue:**
Deprecated fields still present:
- `cvInstanceId`
- `coverLetterInstanceId`

**Recommended Action:**
Remove after confirming no legacy data depends on them.

---

### 3.4 Profile Picture Methods Potentially Unused

**Severity:** 🟡 MEDIUM
**File:** [lib/services/templates_storage_service.dart](lib/services/templates_storage_service.dart#L46-L133)

**Methods:**
- `saveProfilePicture()`
- `loadProfilePictureBytes()`
- `deleteProfilePicture()`
- `isStoredProfilePicture()`
- `getDefaultProfilePicturePath()`

**Issue:**
Profile picture management appears duplicated or unused given the new architecture.

**Recommended Action:**
Verify usage and migrate to appropriate service or remove.

---

### 3.5 Inconsistent State Management Patterns

**Severity:** 🟡 MEDIUM

**Files Affected:**
- [lib/providers/app_state.dart](lib/providers/app_state.dart)
- [lib/providers/user_data_provider.dart](lib/providers/user_data_provider.dart)
- [lib/providers/templates_provider.dart](lib/providers/templates_provider.dart)
- [lib/providers/applications_provider.dart](lib/providers/applications_provider.dart)

**Issue:**
Mix of `ChangeNotifier` and `extends ChangeNotifier` patterns.

**Recommended Action:**
Standardize on a single state management approach.

---

### 3.6 Deprecated Methods in PDF Styling

**Severity:** 🟡 MEDIUM
**File:** [lib/pdf/shared/pdf_styling.dart](lib/pdf/shared/pdf_styling.dart)

**Deprecated Methods:**
- `lineHeight` (line 127)
- `sectionGap` (line 155)
- Old spacing names: `spaceXxs`, `spaceXs`, etc. (lines 158-171)
- `contentPadding` (line 195)

**Recommended Action:**
Remove deprecated methods after ensuring no usages remain.

---

### 3.7 Large Widget Files

**Severity:** 🟡 MEDIUM

**Files:**
1. [lib/screens/applications/widgets/compact_application_card.dart](lib/screens/applications/widgets/compact_application_card.dart) - 665 lines
2. [lib/widgets/tabbed_cv_editor.dart](lib/widgets/tabbed_cv_editor.dart) - 1300+ lines
3. [lib/dialogs/experience_edit_dialog.dart](lib/dialogs/experience_edit_dialog.dart) - 455 lines
4. [lib/services/storage_service.dart](lib/services/storage_service.dart) - 595 lines
5. [lib/services/templates_storage_service.dart](lib/services/templates_storage_service.dart) - 502 lines

**Recommended Action:**
Split into smaller, more focused files with single responsibilities.

---

### 3.8 TODO Comments

**Severity:** 🟡 MEDIUM
**Total Found:** 8 locations

**Locations:**
1. [lib/screens/templates/templates_screen.dart:273](lib/screens/templates/templates_screen.dart#L273) - "Implement cover letter export dialog"
2. [lib/screens/templates/templates_screen.dart:333](lib/screens/templates/templates_screen.dart#L333) - "Implement file picker for YAML import"
3. [lib/screens/templates/sections/templates_section.dart:156](lib/screens/templates/sections/templates_section.dart#L156) - "Open template editor"
4. [lib/screens/templates/sections/templates_section.dart:349](lib/screens/templates/sections/templates_section.dart#L349) - "Open template editor"
5. [lib/widgets/job_cv_editor_widget.dart:113](lib/widgets/job_cv_editor_widget.dart#L113) - "Load from storage when implemented"
6. [lib/widgets/job_cv_editor_widget.dart:154](lib/widgets/job_cv_editor_widget.dart#L154) - "Auto-save to storage"
7. [lib/widgets/job_cv_editor_widget.dart:1240](lib/widgets/job_cv_editor_widget.dart#L1240) - "Implement template selector"
8. [lib/widgets/job_cv_editor_widget.dart:1441](lib/widgets/job_cv_editor_widget.dart#L1441) - "Show PDF preview"

**Recommended Action:**
Address or remove these TODO items.

---

## 4. LOW PRIORITY ISSUES (2)

### 4.1 Old Spacing Method Names

**Severity:** ⚪ LOW
**File:** [lib/pdf/shared/pdf_styling.dart](lib/pdf/shared/pdf_styling.dart#L158-L171)

**Issue:**
Deprecated spacing method names still present.

**Recommended Action:**
Remove after migration is complete.

---

### 4.2 Minor Naming Inconsistencies

**Severity:** ⚪ LOW

**Issue:**
Minor inconsistencies in naming patterns across the codebase.

**Recommended Action:**
Review and standardize naming conventions.

---

## 5. RECOMMENDED CLEANUP ORDER

### Phase 1: Quick Wins (Remove Dead Code)
1. Remove `templates_storage_service.dart` (502 lines)
2. Remove deprecated fields from `JobApplication`
3. Remove deprecated methods from `pdf_styling.dart`
4. Remove nested dialog classes from `tabbed_cv_editor.dart`

**Estimated Code Reduction:** ~800-1000 lines

---

### Phase 2: Consolidate Duplicates
1. Create `ApplicationStatusHelper` utility
2. Merge `StatusChip` and `StatusBadge`
3. Consolidate `PreferencesService` with `CustomizationPersistence`
4. Create shared `PathService` for UserData path retrieval
5. Create `FileStorageHelper` for file I/O operations
6. Create shared JSON encoder constant

**Estimated Code Reduction:** ~500-700 lines

---

### Phase 3: Refactor for Maintainability
1. Create `BaseEditDialog` abstract class
2. Split `CompactApplicationCard` into smaller components
3. Split large widget files (> 500 lines)
4. Standardize error handling to use `LogService`
5. Standardize state management patterns

**Estimated Improvement:** Better separation of concerns, easier testing

---

### Phase 4: Code Quality
1. Address TODO comments
2. Standardize naming conventions
3. Add missing documentation
4. Review and optimize large files

---

## 6. METRICS

**Before Cleanup:**
- Total Lines: ~15,000+ (estimated)
- Duplicate Code: ~1,500-2,000 lines
- Large Files (>500 lines): 5 files
- Critical Issues: 3
- High Priority Issues: 7

**After Cleanup (Estimated):**
- Total Lines: ~12,500-13,000
- Duplicate Code: Minimal
- Large Files (>500 lines): 2-3 files
- Critical Issues: 0
- High Priority Issues: 0

**Expected Benefits:**
- 15-20% code reduction
- Improved maintainability
- Easier testing
- Better performance (fewer redundant operations)
- Reduced bug surface area

---

## 7. NOTES

- This analysis was performed on 2026-01-10
- All line numbers are approximate and may shift during cleanup
- Priority levels are suggestions and can be adjusted based on project needs
- Consider creating a backup or feature branch before starting major refactoring
- Some cleanup items may require careful migration of legacy data

---

**End of Report**
