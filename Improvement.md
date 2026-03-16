# MyJob — Improvement Plan

> Generated 2026-03-10 from full codebase analysis.
> This document is the single source of truth for all planned improvements.
> Supersedes `TODO_pdf_editor.md` — all remaining items from that file are incorporated below.
> Mark items `[x]` as they are completed. Add notes inline as needed.

---

## App Context (for future sessions)

**MyJob** is a Windows-first Flutter desktop app for managing job applications.

### Intended Workflow
1. **Profile tab** — User imports or creates profile data (supports multiple languages) for CV and cover letter fields.
2. **Applications tab** — User creates job applications using stored profile data as a template, customizes per-job, generates CV and cover letter PDFs. Application status is tracked here. Profile data is **never edited** here — only in the Profile tab.
3. **Notes tab** — To-dos, company leads, general notes, reminders.
4. **Settings tab** — Backup/restore all data, add custom languages, choose theme.

### Project Structure
- **Models:** `master_profile`, `cv_data` (`CvEducation`), `job_application`, `cover_letter`, `cv_template`, `template_customization`, `note_item`
- **Providers:** `UserDataProvider`, `ApplicationsProvider`, `NotesProvider`, `SettingsProvider`
- **Services:** `StorageService` (central persistence), `BackupService`, `PdfService`, `UpdateService`, `LogService`, `UnifiedYamlImportService`, `ApplicationExportService`
- **PDF system:** `BasePdfTemplate` contract, components in `lib/pdf/components/`, shared helpers in `lib/pdf/shared/`, cover letter + CV templates
- **Screens:** Profile, Applications, Notes, Settings (in `lib/screens/`)
- **Utils:** `PlatformUtils` (safe URL/folder opening), `AppDateUtils`, `FileConfig.sanitizeFilename`

### Coding Principles
- **DRY** — Reuse existing utilities (`PlatformUtils`, `AppDateUtils`, `CoverLetterHelpers`, `FileConfig.sanitizeFilename`, generic `_loadPdfSettings`/`_savePdfSettings`)
- **Backwards compatibility** — Old UserData folders, JSON presets, and backups must load without errors. Graceful fallbacks for missing/unknown keys.
- **Robust error handling** — Use `LogService` (not `debugPrint`), no silent `catch (_)` in critical paths
- **No over-engineering** — Minimal changes, no speculative abstractions
- **Backup/restore integrity** — Atomic operations, relative path storage, path remapping on restore, validation
- **Security** — No command injection (`PlatformUtils`), path traversal checks, checksum verification for updates

### Open Items Summary
- **Phase 1–2:** All fixes applied; remaining items are **manual verification** tasks (URLs with `&`, mismatched hash, `../` traversal, filename output, PDF settings, preset loading)
- **Phase 3.5:** `StorageService` scope reduction — done (3 repositories extracted)
- **Phase 4.2:** Surface critical operation errors to UI — ✅ resolved
- **Backwards Compatibility Checklist:** All items need verification pass before shipping

---

## Phase 1 — Bugs & Security (Priority: Immediate)

Complexity: Low | Effort: ~2-3 hours | Breaking changes: None

### 1.1 [BUG] `CoverLetter.copyWith()` — subject field silently dropped
- **File:** `lib/models/cover_letter.dart:103`
- **Issue:** `subject` was missing from the `copyWith` parameter
  list entirely, so the field could never be updated. Additionally
  the fallback was `subject ?? subject` (self-referential) instead
  of `subject ?? this.subject`.
- **Fix:** Added `subject` parameter and `this.` prefix.
- [x] Fix applied
- [ ] Verified with manual test

### 1.2 [SECURITY] Command injection via `Process.run` with user-supplied URLs
- **Severity:** Critical
- **Issue:** URLs from job applications and notes are passed directly to `Process.run('cmd', ['/c', 'start', url])`. Shell metacharacters (`&`, `|`, `&&`) in a URL can execute arbitrary commands.
- **Affected files (7 locations):**
  - `lib/screens/applications/applications_screen.dart` (2x)
  - `lib/dialogs/job_application_pdf_dialog.dart`
  - `lib/screens/applications/widgets/compact_application_card.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/notes/notes_screen.dart`
  - `lib/widgets/note_card.dart`
- **Fix:** Created `lib/utils/platform_utils.dart` with
  `openUrl()` (validates scheme, escapes `&` on Windows),
  `openFolder()`, and `openFolderAndSelect()`. Replaced all
  9 call sites (7 original + update_service + cv_export_dialog).
  Also absorbed item 2.1.
- [x] Fix applied to all locations
- [ ] Verified: URLs with `&` no longer execute commands

### 1.3 [SECURITY] Auto-updater downloads without integrity verification
- **Severity:** High
- **File:** `lib/services/update_service.dart`
- **Issue:** `UpdateInfo` model already has a `checksumUrl` field but it is never used. Downloaded ZIP is extracted without SHA256 verification.
- **Fix:** Added `package:crypto` dependency. New
  `_verifyChecksum()` method downloads `.sha256` file, compares
  against computed hash, and aborts with error on mismatch.
  Added `UpdateState.verifying` state. Gracefully skips if no
  checksum URL is available or fetch fails.
- [x] Checksum verification implemented
- [ ] Tested with mismatched hash (should abort)

### 1.4 [SECURITY] Path traversal in update ZIP extraction
- **Severity:** High
- **File:** `lib/services/update_service.dart:380-409`
- **Issue:** Unlike backup restore (which validates via `BackupValidator`), the update extraction has no `..` path checks. A malicious ZIP could write files outside the target directory.
- **Fix:** Added `..`, leading `/`/`\\` checks and canonical
  path validation (`p.normalize` + prefix check) to
  `_extractZipIsolate`. Suspicious entries are skipped with a
  debug log.
- [x] Path validation added
- [ ] Tested with crafted `../` entry (should skip)

---

## Phase 2 — DRY & Dead Code Cleanup (Priority: High)

Complexity: Low-Medium | Effort: ~4-6 hours | Breaking changes: None

### 2.1 Extract `PlatformUtils` — eliminate 7x duplicated folder/URL opening
- **Issue:** The same `if (Platform.isWindows) Process.run('explorer.exe'...)` block is copy-pasted in 7 files.
- **Fix:** Create `lib/utils/platform_utils.dart` with `openFolder(String path)` and `openUrl(String url)` (absorbs 1.2's fix). Replace all 7 call sites.
- **Files to update:**
  - `lib/screens/applications/applications_screen.dart` (2x)
  - `lib/dialogs/job_application_pdf_dialog.dart`
  - `lib/screens/applications/widgets/compact_application_card.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/notes/notes_screen.dart`
  - `lib/widgets/note_card.dart`
- [x] `PlatformUtils` created (done as part of 1.2)
- [x] All 9 call sites replaced (including update_service,
  cv_export_dialog)
- [x] URL opening includes validation (from 1.2)

### 2.2 Extract shared `DateFormatUtils` — eliminate 3x duplicated `_formatDate`
- **Issue:** Identical month-abbreviation date formatting in 3 files.
- **Files:** `lib/dialogs/job_application_pdf_dialog.dart`, `lib/dialogs/master_profile_pdf_dialog.dart`, `lib/services/pdf_service.dart`
- **Fix:** Create utility method (e.g., in `lib/utils/date_format_utils.dart` or add to existing utils). Replace all 3.
- [x] Reused existing `AppDateUtils.formatShort()` — no new file
  needed. Replaced all 3 private `_formatDate` methods with
  one-line delegates.
- [x] All 3 call sites replaced

### 2.3 Unify `_sanitizeFilename` — two divergent implementations
- **Issue:** `FileConfig.sanitizeFilename` in `app_constants.dart` and a private `_sanitizeFilename` in `job_application_pdf_dialog.dart` produce different results for the same input.
- **Fix:** Enhance `FileConfig.sanitizeFilename` to cover both needs (whitespace→underscore, trailing cleanup). Remove the private version.
- [x] `FileConfig.sanitizeFilename` enhanced with `useUnderscores`
  param, control char handling, max length enforcement
- [x] Private duplicate replaced with one-line delegate
- [ ] Verified: filenames match expected output

### 2.4 Consolidate PDF settings load/save — eliminate 9 near-identical methods
- **File:** `lib/services/storage_service.dart`
- **Issue:** 9 methods (`loadJobCvPdfSettings`, `loadJobClPdfSettings`, `loadMasterProfileCvPdfSettings`, etc.) all follow the exact same JSON read/write pattern with `style` and `customization` keys.
- **Fix:** Extract generic `_loadPdfSettings(String filePath)` and `_savePdfSettings(String filePath, TemplateStyle, TemplateCustomization)`. Keep the public methods as thin wrappers that just pass the correct path.
- [x] Generic `_loadPdfSettings` / `_savePdfSettings` extracted
- [x] 9 public methods reduced to thin wrappers (~100 lines saved)
- [ ] Verified: PDF settings still load/save correctly

### 2.5 Delete dead `UserDataService`
- **File:** `lib/services/user_data_service.dart` (192 lines)
- **Issue:** Legacy service using `path_provider` / `getApplicationDocumentsDirectory()` while the entire app uses `StorageService.instance` with portable paths. No active callers.
- **Fix:** Confirm no imports, then delete.
- [x] Confirmed no callers (grep found zero imports)
- [x] File deleted

### 2.6 Remove single-value `ProfilePhotoStyle` enum
- **File:** `lib/models/template_customization.dart:27-30`
- **Issue:** Only has one value (`color`) — the `grayscale` option was removed because the PDF library doesn't support it. The enum, its field, serialization, and copyWith parameter all add noise.
- **Fix:** Remove enum, remove field from `TemplateCustomization`, update serialization. Keep a comment noting why grayscale was removed.
- **Backwards compatibility:** Old JSON with `"photoStyle": "color"` must not crash on load — just ignore the unknown key.
- [x] Enum, field, constructor param, toJson, copyWith all removed
- [x] fromJson ignores old `profilePhotoStyle` key gracefully
- [ ] Verified: existing presets still load

### 2.7 Clean up deprecated methods
- **Files:** `lib/providers/user_data_provider.dart` (6 deprecated), `lib/providers/notes_provider.dart` (4 deprecated)
- **Fix:** Search for callers. If none, delete. If callers exist, migrate them first.
- [x] Callers audited — migrated `work_experience_section.dart`
  and `cv_export_dialog.dart` to use current method names
- [x] Removed 6 deprecated from UserDataProvider, 2 from
  NotesProvider, 1 from PdfStyling (11 total)

---

## Phase 3 — Structural Refactors (Priority: Medium)

Complexity: Medium-High | Effort: ~2-3 days | Breaking changes: Low (see notes)

> These are worthwhile but not urgent. Tackle when actively feeling the pain or before a major feature addition.

### ~~3.1 Migrate legacy cover letter templates to `BasePdfTemplate` contract~~
- **Status:** Resolved (v1.1.8)
- **Electric:** Deleted — 100% dead code, zero active callers, commented out of registry.
- **ModernTwo:** Actively used as the `Compact` cover letter preset in `PdfService`.
  Still uses old `static build()` pattern but works correctly. Not worth migrating
  unless the template itself is being reworked.
- [x] ElectricCoverLetterTemplate deleted (dead code)
- [x] Registry reference removed
- [x] PDF README updated

### ~~3.2 Refactor `UnifiedImportResult` into sealed class hierarchy~~
- **Status:** Resolved (v1.1.8)
- **What changed:**
  - `UnifiedImportResult` is now a `sealed class` with three subtypes:
    `CvImportResult`, `CoverLetterImportResult`, `ImportError`
  - Each subtype carries only its own fields — no more nullable cross-type ambiguity
  - Factory constructors (`UnifiedImportResult.cv()`, `.coverLetter()`, `.error()`) preserved
    for zero-diff in the service layer
  - Dialog updated to use Dart 3 pattern matching (`switch`, `case ... :final`)
  - `isCvData` / `isCoverLetter` convenience getters kept on the sealed base
- [x] Sealed classes created
- [x] Import dialog updated to pattern-match
- [x] Verified: analyzer reports zero errors

### ~~3.3 Unify or rename duplicate `Education` model~~
- **Status:** Resolved
- **Files:** `lib/models/master_profile.dart:134` vs `lib/models/cv_data.dart:326`
- **Analysis findings:**
  - `master_profile.Education` is the **canonical data model** — used everywhere in the GUI:
    - Profile tab (CRUD via `EducationSection` + `EducationEditDialog`)
    - `JobCvData` (per-application clones, serialised to JSON)
    - `UserDataProvider` (state management)
    - `UnifiedYamlImportService` (YAML import)
    - Fields: `id`, `institution`, `degree`, `fieldOfStudy`, `startDate` (DateTime),
      `endDate` (DateTime?), `isCurrent`, `description`, `grade`
  - `cv_data.Education` was a **PDF display model** — only used in:
    - `CvData` model (old-style CV data container for PDF templates)
    - PDF components (`education_component.dart`)
    - PDF templates (`professional_cv_template.dart`, `electric_cv_template.dart`)
    - Fields: `institution`, `degree`, `startDate` (String), `endDate` (String?), `description`
  - **Conversion point:** `job_application_pdf_dialog.dart` and `master_profile_pdf_dialog.dart` —
    inline `.map()` converts `master_profile.Education` → `CvEducation` using `_formatDate()`.
  - The two models serve **fundamentally different purposes** (rich data vs pre-formatted display).
- **What changed:**
  - Renamed `cv_data.Education` → `CvEducation` in `lib/models/cv_data.dart`
  - Renamed `EducationComponent` → `CvEducationComponent` and `EducationStyle` → `CvEducationStyle`
    in `lib/pdf/components/education_component.dart`
  - Updated `professional_cv_template.dart` to use renamed component/style
  - Updated `cv_template.dart` (both `CvTemplate` and `CvInstance` classes)
  - Updated `tabbed_cv_editor.dart` (_EducationDialog and callers)
  - Updated `job_application_pdf_dialog.dart` — removed `as cv_data` alias import
  - Updated `master_profile_pdf_dialog.dart` — removed `as cv_data` alias import
  - Analyzer reports zero errors from the rename
- [x] Renamed `cv_data.Education` → `CvEducation`
- [x] Updated all PDF template / component references
- [x] Removed `as cv_data` import alias from both PDF dialog files
- [x] Verified: analyzer reports zero errors

### ~~3.4 Extract business logic from `ApplicationsScreen`~~
- **Status:** Resolved (v1.1.8)
- **What changed:**
  - Created `ApplicationStatistics` data class in `applications_provider.dart`
  - Moved `filterByTimeRange()`, `computeStatistics()`, `groupByCategory()` to provider
  - Created `ApplicationExportService` (`lib/services/application_export_service.dart`)
    with `ExportResult` return type — screen only handles folder picker + success/error UI
  - Extracted `_buildStatRow()` to DRY up collapsed/expanded stat displays
  - Extracted `_buildActionCard()` for readability
  - Removed unused `app_constants.dart` import
  - Screen reduced from 1082 → 999 lines; inline business logic eliminated
- [x] Statistics moved to provider
- [x] Export logic moved to service
- [x] Screen simplified

### ~~3.5 Reduce `StorageService` scope~~
- **Status:** Resolved (v1.1.9)
- **File:** `lib/services/storage_service.dart` (1100+ lines → ~350 lines)
- **Issue:** God class handling all persistence for every domain.
- **What changed:**
  - Extracted `ProfileRepository` (`lib/services/profile_repository.dart`) —
    master profile CRUD, language discovery, profile PDF settings
  - Extracted `ApplicationRepository` (`lib/services/application_repository.dart`) —
    application CRUD, job folders, profile cloning, job CV/CL data, job PDF settings
  - Extracted `NotesRepository` (`lib/services/notes_repository.dart`) —
    notes CRUD, YAML serialization helpers
  - `StorageService` retains: `getUserDataPath()`, path portability helpers,
    shared PDF settings I/O, legacy CV/CoverLetter methods, export/import orchestration
  - Repositories exposed as `StorageService.instance.profiles`, `.applications`, `.notes`
  - Updated 10 caller files to use new repository API
  - `flutter analyze` reports zero errors
- [x] Domain repositories extracted
- [x] StorageService simplified
- [x] All call sites updated

### 3.6 Fix mutable lists inside "immutable" models
- **Files:** `lib/models/master_profile.dart`, `lib/models/job_application.dart`
- **Issue:** `MasterProfile.empty()` creates mutable `[]` lists. External code could mutate them, bypassing `copyWith`.
- **Fix:** Use `const []` in constructors or `List.unmodifiable()` in factories.
- **Breaking:** None if done carefully — ensure no code relies on mutating these lists directly.
- [x] Identified all mutable list fields (only `MasterProfile.empty()`)
- [x] Made immutable (`const []` in factory constructor)
- [x] Verified: no code mutates lists directly (grep confirmed)

---

## Phase 4 — Quality & Robustness (Priority: Normal)

Complexity: Low-Medium | Effort: ~1-2 days | Breaking changes: None

### 4.1 Replace `debugPrint` with `LogService` throughout
- **Issue:** 295 `debugPrint` calls across 23 files. The app has a proper `LogService` with severity levels and file rotation, but it's barely used.
- **Fix:** Replace `debugPrint` calls with appropriate `LogService` severity levels. Remove emoji characters from log messages in `storage_service.dart`.
- [x] All debugPrint calls replaced (13 files migrated, isolate
  functions intentionally kept as debugPrint)
- [x] Log severity levels appropriate (info/warning/error)
- [ ] Verified: log files capture expected output

### 4.2 Audit and fix silent `catch (_)` blocks
- **Issue:** 19 instances of `catch (_)` silently swallowing errors. Data load/save failures go completely unnoticed.
- **Fix:** At minimum, add `LogService.warning()` to every catch block. For data operations, consider surfacing errors to the user.
- [x] All silent catches identified (14 across 7 files)
- [x] 9 fixed: 3 in backup_service (added logging), 4 in
  template_registry + 1 in app_localizations (replaced with
  loop-based lookup, no exception thrown), 1 in base_pdf_template
  (added logWarning)
- [x] 5 intentionally kept silent: tryParse pattern (1), font path
  probing (3), enum fallback (1)
- [x] Critical operations surface errors to UI
  - NotesProvider: added `_error` state + error display with retry in notes_screen
  - ApplicationsScreen: added error display with retry for load failures
  - Base PDF dialog: made `showError`/`showSuccess` protected for subclass access
  - JobApplicationPdfDialog: 5 catch blocks now call `showError()` (save settings, field changes, experience, skills, remove experience)
  - MasterProfilePdfDialog: save settings catch block now calls `showError()`
  - Added `error_loading_applications`, `error_loading_notes`, `retry` translation keys (EN + DE)

### 4.3 Fix inconsistent log directory path
- **File:** `lib/services/log_service.dart`
- **Issue:** Line 26 references `MyLife` while line 133 references `MyJob`. Logs may be written to one directory and cleaned from another.
- [x] Directory names unified (both already use `MyJob/logs`)
- [x] Verified: logs write and clean from same location

### 4.4 Fix hardcoded English strings in cover letter dialog
- **File:** `lib/dialogs/job_application_pdf_dialog.dart:647-668`
- **Issue:** Labels like `'Recipient Name'` and `'Company Name'` are hardcoded in English while surrounding labels use `context.tr()`.
- [x] All hardcoded strings replaced with `context.tr()` keys
  (6 in job_application_pdf_dialog, 2 in master_profile_pdf_dialog)
- [x] Translation keys added to EN + DE locale files
  (pdf_hint_summary, pdf_hint_skills, pdf_hint_experience,
  pdf_remove_experience, pdf_position_at_company)

### 4.5 Cache `_filteredApplications` in provider
- **File:** `lib/providers/applications_provider.dart:28-45`
- **Issue:** Getter recalculates filtered list on every access,
  called from build methods.
- **Fix:** Cache result, invalidate on data or filter changes.
- [x] Caching implemented (`_cachedFiltered` + `_invalidateCache()`)
- [x] Invalidation on data/filter change verified (8 call sites)

### ~~4.6 `PdfViewMode` — hardcoded English labels~~
- **Status:** Done in v1.1.8 — `label` field removed from enum, toolbar uses `context.tr()` switch.

### 4.7 Cover letter `_buildLetterBody` — bullet rendering
- **Files:** All 4 cover letter templates
- **Issue:** Each template has its own `_buildLetterBody` because
  bullet/paragraph rendering differs. Shared logic (paragraph
  splitting, line-height, font scaling) is in `CoverLetterHelpers`,
  but widget construction is template-specific.
- **Action:** No immediate change needed. Revisit if a 5th template
  is added to avoid further divergence.
- **Origin:** TODO_pdf_editor.md #5

### ~~4.8 Cover letter — `twoColumn` preset sidebar toggles~~
- **Status:** Done in v1.1.8 — Two-Column now exposes
  all cover letter display options.

---

## Done (from TODO_pdf_editor.md v1.1.8)

- [x] `setLayoutPreset()` persistence + `_hasExplicitCustomization`
- [x] Removed duplicate `setStyle()` (consolidated into `updateStyle()`)
- [x] `currentLayoutPresetName` returns locale key via `localeKey` getter
- [x] `showGreeting` / `showClosing` fields + sidebar toggles
- [x] Conditional greeting/closing in all 4 cover letter templates
- [x] Fixed `as double?` → `(as num?)?.toDouble()` in `fromJson`
- [x] Fixed `_hasExplicitCustomization` race condition
- [x] Fixed missing `subject` field in `_saveFieldChanges()`
- [x] Extracted `CoverLetterHelpers` (`formatDate`, `splitBodyParagraphs`)
- [x] Removed dead `_formatDate` from all 4 cover letter templates
- [x] Added EN + DE localization keys for new toggles

---

## Deferred / Low Priority

These are architecturally "correct" but provide marginal benefit for a solo desktop app:

- **Abstract interfaces for all services (DI)** — only needed if adding unit tests or cloud sync
- **Separate SettingsService from ChangeNotifier** — common Flutter pattern, low practical impact
- **UserDataProvider CRUD generics** — 15 repetitive methods, but each is simple and clear
- **Encrypt data at rest** — local desktop app, OS-level file permissions suffice for most users
- **CI/CD pipeline** — worth adding eventually (`flutter analyze` + `flutter test` in GitHub Actions)
- **Unit tests** — highest-value targets: model serialization round-trips, provider logic, YAML import parsing

---

## Backwards Compatibility Checklist

All changes must pass this check before shipping:

- [ ] Existing `UserData/` folder loads without errors after update
- [ ] Saved PDF presets (JSON) load correctly
- [ ] Old backups can still be restored
- [ ] Application data (job listings, status history) intact
- [ ] Cover letters and CVs render identically
- [ ] Custom language files still work
- [ ] Auto-updater still functions (with added security)
