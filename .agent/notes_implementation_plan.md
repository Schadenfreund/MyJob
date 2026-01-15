# Notes Tab Implementation Plan

## ✅ Completed
1. ✅ Created `NoteItem` data model (`lib/models/notes_data.dart`)
2. ✅ Added YAML storage methods to `StorageService`
3. ✅ Created `NotesProvider` for state management
4. ✅ Added `notes` folder to UserData directory structure

## 🔄 Remaining Tasks

### 1. Create Notes Screen UI
**File**: `lib/screens/notes/notes_screen.dart`

- Build main notes screen layout matching app design
- Add "Add Note" action button
- Display notes in collapsible sections (Active / Completed)
- Use `AppCard`, `AppCardContainer`, `UIUtils.buildSectionHeader` for consistency
- Filter notes by type (Todo, Company Lead, Note, Reminder)
- Sort by priority and due date

### 2. Create Note Editor Dialog
**File**: `lib/screens/notes/note_editor_dialog.dart`

- Dialog for creating/editing notes
- Fields: Title, Description, Type dropdown, Priority dropdown, Due Date picker, Tags
- Use app's form styling (`TextFormField`, `DropdownButtonFormField`)
- Save/Cancel buttons styled like other dialogs

### 3. Create Note Card Widget
**File**: `lib/widgets/note_card.dart`

- Compact card displaying note info
- Checkbox for completion toggle
- Priority indicator (color-coded)
- Type badge/icon
- Due date display (with overdue warning)
- Edit/Delete actions
- Match `CompactApplicationCard` style

### 4. Integrate with Main Navigation
**File**: `lib/screens/home_page.dart`

- Add Notes tab to main navigation
- Icon: `Icons.sticky_note_2_outlined`
- Add `NotesProvider` to main.dart providers list

### 5. Update Backup/Restore
**File**: `lib/services/storage_service.dart`

Update `exportAllData()` method:
```dart
final notes = await loadNotes();
'notes': notes.map((n) => n.toJson()).toList(),
```

Update `importData()` method:
```dart
if (data['notes'] != null) {
  for (final noteJson in data['notes'] as List) {
    final note = NoteItem.fromJson(noteJson as Map<String, dynamic>);
    await saveNote(note);
  }
}
```

### 6. Add Dependencies
**File**: `pubspec.yaml`

Ensure `yaml: ^3.1.2` is in dependencies

### 7. Register Provider
**File**: `lib/main.dart`

Add to MultiProvider:
```dart
ChangeNotifierProvider(create: (_) => NotesProvider()..loadNotes()),
```

## Design Guidelines

- **Colors**: Use `AppColors` for priority indicators
  - Urgent: `AppColors.statusRejected` (red)
  - High: `Colors.orange`
  - Medium: `AppColors.statusApplied` (blue)
  - Low: `AppColors.statusAccepted` (green)

- **Typography**: Follow existing patterns
  - Headers: `theme.textTheme.titleLarge` with `FontWeight.w700`
  - Body: `theme.textTheme.bodyMedium`
  - Labels: `theme.textTheme.labelSmall`

- **Spacing**: Use `AppSpacing` constants (`sm`, `md`, `lg`)

- **Cards**: Use `AppCard` and `AppCardContainer` with proper padding

## YAML File Example
```yaml
id: "uuid-here"
title: "Apply to Google"
description: "Senior Software Engineer position"
type: "companyLead"
priority: "high"
completed: false
createdAt: "2026-01-15T22:00:00.000"
completedAt: null
dueDate: "2026-01-20T00:00:00.000"
tags:
  - "tech"
  - "remote"
```

## Next Steps
1. Create notes_screen.dart with full UI
2. Create note_editor_dialog.dart
3. Create note_card.dart widget
4. Update main.dart to add provider
5. Update home_page.dart to add Notes tab
6. Update backup/restore in storage_service.dart
7. Test full workflow
