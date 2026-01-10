# Persistent State Refactoring - Summary

## Overview
Refactored the application state persistence to follow DRY principles and store all settings in the UserData folder for portability.

## Changes Made

### 1. Created New PreferencesService (`lib/services/preferences_service.dart`)
- **Purpose**: Centralized preferences management stored in UserData folder
- **Location**: `UserData/preferences.json`
- **Features**:
  - JSON-based storage (human-readable)
  - Type-safe getters and setters (bool, string, int, double)
  - Automatic initialization and file creation
  - Pretty-printed JSON for easy debugging

### 2. Refactored ApplicationsScreen (`lib/screens/applications/applications_screen.dart`)
**Before:**
- Used SharedPreferences (default platform storage)
- 6 separate save methods with duplicate code
- Not stored in UserData folder

**After:**
- Uses PreferencesService (UserData folder)
- Generic `_saveExpandedState()` method following DRY principle
- All state methods now use the generic implementation
- Cleaner, more maintainable code

**State Persistence:**
- ✅ Statistics section expand/collapse
- ✅ Active applications section expand/collapse
- ✅ Successful applications section expand/collapse
- ✅ Rejected applications section expand/collapse
- ✅ No Response applications section expand/collapse
- ✅ Individual card expand/collapse (by application ID)

### 3. Updated CompactApplicationCard (`lib/screens/applications/widgets/compact_application_card.dart`)
- Added `initiallyExpanded` parameter to restore saved state
- Added `onExpandedChanged` callback to notify parent of state changes
- Properly initializes from saved preferences

### 4. Migrated CustomizationPersistence (`lib/services/customization_persistence.dart`)
**Before:**
- Used SharedPreferences
- Binary storage

**After:**
- Uses direct JSON file storage
- Location: `UserData/cv_customization.json`
- Human-readable format
- Consistent with other storage patterns

### 5. Removed Dependencies
- Removed `shared_preferences: ^2.2.0` from pubspec.yaml
- No longer needed since all preferences are in UserData folder

## Benefits

### 1. DRY Principle
- Eliminated 5 duplicate save methods
- Single generic `_saveExpandedState()` method
- Easier to maintain and extend

### 2. Portable Storage
- All settings in UserData folder
- Easy backup and migration
- No platform-specific storage locations

### 3. Human-Readable
- JSON format with indentation
- Easy to debug and inspect
- Can be manually edited if needed

### 4. Consistent Architecture
- All services now use UserData folder
- Consistent patterns across the codebase
- Easier for developers to understand

## File Locations

All preferences are now stored in the UserData folder:
```
UserData/
├── preferences.json          # UI state (sections, cards expanded/collapsed)
├── cv_customization.json     # CV template customization
├── applications/             # Job applications
├── profiles/                 # User profiles
│   ├── en/                   # English profiles
│   └── de/                   # German profiles
└── ...
```

## Code Quality Improvements

### Before (Repetitive):
```dart
Future<void> _saveStatsExpanded(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKeyStatsExpanded, value);
  setState(() => _statsExpanded = value);
}

Future<void> _saveActiveExpanded(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKeyActiveExpanded, value);
  setState(() => _activeExpanded = value);
}
// ... 4 more similar methods
```

### After (DRY):
```dart
/// Generic method to save expanded state (DRY principle)
Future<void> _saveExpandedState(
  String prefKey,
  bool value,
  void Function(bool) updateState,
) async {
  await _prefs.setBool(prefKey, value);
  setState(() => updateState(value));
}

Future<void> _saveStatsExpanded(bool value) =>
    _saveExpandedState(_prefKeyStatsExpanded, value, (v) => _statsExpanded = v);

Future<void> _saveActiveExpanded(bool value) =>
    _saveExpandedState(_prefKeyActiveExpanded, value, (v) => _activeExpanded = v);
// ... concise implementations
```

## Testing Recommendations

1. **Test state persistence**:
   - Expand/collapse sections and cards
   - Restart the app
   - Verify all states are restored correctly

2. **Test UserData portability**:
   - Copy UserData folder to different machine
   - Verify preferences are preserved

3. **Test customization persistence**:
   - Change CV template settings
   - Restart the app
   - Verify settings are restored

## Future Enhancements

1. **Versioning**: Add version field to preferences.json for migration support
2. **Validation**: Add schema validation for preferences
3. **Migration**: Add migration logic for upgrading preference formats
4. **Backup**: Add automatic backup of preferences before saving
5. **Encryption**: Consider encrypting sensitive preferences if needed
