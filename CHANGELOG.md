# Changelog

All notable changes to MyJob will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-03-16

### Security

- **Command injection via user-supplied URLs** — URLs passed to
  `Process.run('cmd', ...)` could allow shell metacharacters to execute
  arbitrary commands. Created `PlatformUtils` with scheme validation and
  shell escaping; replaced all 9 call sites.
- **Auto-updater checksum verification** — Downloaded ZIPs are now verified
  against a `.sha256` checksum before extraction. Skips gracefully when no
  checksum URL is available.
- **Path traversal in update extraction** — Added `..` and leading slash
  checks plus canonical path validation to the ZIP extraction isolate.
- **Path traversal in backup extraction** — Added the same guards to the
  backup restore isolate for defense in depth (the validator already
  rejects suspicious entries, but the extractor now independently skips them).

### Fixed

- **`CoverLetter.copyWith()` subject dropped** — `subject` was missing from
  the parameter list, so edits were silently lost.
- **Inconsistent log directory path** — `LogService` referenced two different
  directory names. Unified to `MyJob/logs`.
- **Hardcoded English strings in PDF dialogs** — Cover letter edit panel
  labels now use `context.tr()` with EN + DE translations.
- **Mutable lists in `MasterProfile.empty()`** — Changed to `const []` to
  prevent accidental mutation that bypasses `copyWith`.
- **Custom languages lost on backup restore** — The `localization/` directory
  was included in backup ZIPs but not whitelisted for restore. Custom
  language files are now correctly restored.
- **Critical operation errors hidden from user** — Notes and applications
  loading failures, PDF settings save failures, and inline-edit save failures
  now surface as user-visible error messages with retry options.

### Changed

#### Code Quality & DRY
- **`PlatformUtils`** — Consolidates 7 duplicated `Process.run` blocks into
  `openUrl()`, `openFolder()`, and `openFolderAndSelect()`.
- **`DateFormatUtils`** — Eliminated 3 identical `_formatDate` methods by
  reusing `AppDateUtils.formatShort()`.
- **`FileConfig.sanitizeFilename`** — Unified two divergent filename
  sanitizers with `useUnderscores`, control char handling, and max length.
- **PDF settings consolidation** — 9 near-identical load/save methods reduced
  to thin wrappers around generic `loadPdfSettings`/`savePdfSettings`.
- **Dead code removal** — Deleted unused `UserDataService` (192 lines),
  single-value `ProfilePhotoStyle` enum, and 11 deprecated provider methods.
- **`debugPrint` to `LogService`** — Migrated 13 files to proper severity
  levels. Isolate functions kept as `debugPrint` (no `LogService` in isolates).
- **Silent `catch` audit** — 9 of 14 silent catches now log warnings.
  5 intentionally kept (tryParse, font probing, enum fallback).

#### Structural Refactors
- **`UnifiedImportResult` sealed class** — Replaced nullable-field class with
  `CvImportResult`, `CoverLetterImportResult`, and `ImportError` subtypes.
  Dialog uses Dart 3 pattern matching.
- **`CvEducation` rename** — Disambiguated from `master_profile.Education`.
  Updated PDF components, templates, and dialogs.
- **`ApplicationsScreen` business logic extraction** — Statistics, filtering,
  and export logic moved to provider and `ApplicationExportService`.
- **`StorageService` repository split** — Extracted `ProfileRepository`,
  `ApplicationRepository`, and `NotesRepository`. `StorageService` reduced
  from 1100+ to ~350 lines.
- **Deleted `ElectricCoverLetterTemplate`** — Dead code with zero callers.

#### Caching
- **Filtered applications list** — Provider now caches the result and
  invalidates on data/filter changes instead of recalculating every build.

---

## [1.1.8] - 2026-03-09

### Added

- **Cover letter toggles in Two-Column layout** — Show Greeting / Show
  Closing toggles were missing from the Two-Column preset. All four
  presets now expose the full set of cover letter display options.

### Fixed

- **Layout preset not persisted** — `setLayoutPreset()` was not calling
  `_scheduleSave()`, so switching presets was never written to disk.
  The async global-customization load could also overwrite the preset
  if it resolved after the switch. Both issues fixed.

### Changed

- **`LayoutPreset` locale key** — `currentLayoutPresetName` now returns a
  locale key instead of a hardcoded English string. Old saved presets fall
  back gracefully.
- **Dead code removal** — Removed unused `setStyle()` from
  `PdfEditorController` and the unused `label` field from `PdfViewMode`.

---

## [1.1.7] - 2026-03-09

### Added

- **Show Greeting / Show Closing toggles** — Sidebar toggles to hide or
  show the greeting and closing lines in cover letter PDFs. Available in
  Modern, Compact, and Traditional presets. Persists via
  `TemplateCustomization` (backward-compatible defaults to `true`).

### Fixed

- **`TypeError` on old UserData** — Numeric fields in
  `TemplateCustomization` were deserialized with `as double?`, which throws
  when the stored value is an integer. Changed to `(as num?)?.toDouble()`.
- **Job-specific PDF settings overwritten** — Async global customization
  load could overwrite job-specific settings. Fixed with an
  `_hasExplicitCustomization` guard.
- **Cover letter subject not saved** — `_saveFieldChanges()` omitted
  `subject` from the `copyWith` call.

### Changed

- **Cover letter DRY cleanup** — Extracted `CoverLetterHelpers` with shared
  `formatDate()` and `splitBodyParagraphs()`. Removed duplicate private
  methods from all 4 templates.

---

## [1.1.6] - 2026-03-08

### Fixed

#### Profile Import / Export
- **Work experience `description` not exported** — Descriptions were silently
  dropped, causing data loss on re-import.
- **`default_cover_letter` ignored on import** — The value was parsed but
  never applied.
- **Interest `level` not round-tripped** — Not written on export, not read
  on import. Both directions now work.

#### Profile Import — Target Profile Selector
- **Import always wrote to the active profile** — The dialog now shows a
  target profile chip row so you can import into any language without
  changing the global selection.
- **Cover letter import ignored target selector** — Now respects the same
  chip selection as CV imports.
- **Silent failure on first use** — On a fresh install the dialog reported
  success while writing nothing. Now creates the target profile if needed.

#### Import Service
- **Duplicate language-detection code** — Extracted into a single
  `_detectLanguage()` helper.
- **Fragile file-path parsing** — Replaced manual string splitting with
  `File(filePath).uri.pathSegments.last`.

---

## [1.1.5] - 2026-03-07

### Fixed

#### UserData Portability
- **Relative path storage** — `folderPath` and `profilePicturePath` are now
  stored relative to the UserData root. Existing folders can be moved freely.
- **Backward-compatible path resolution** — Stale absolute paths are
  recovered at load time by scanning for known directory names and
  re-anchoring to the current root.
- **Backup/restore guard** — Path remapping now requires an absolute path
  before rewriting, preventing JSON corruption from relative paths.

#### Notes
- **Multi-line text round-trip** — Literal newlines were collapsed by YAML
  line-folding. The serializer now escapes `\n`, `\r`, and `\\` correctly.
- **Nullable fields can be cleared** — `NoteItem.copyWith` used
  `value ?? this.value`, making it impossible to clear optional fields.
  Fixed with a private sentinel pattern.

---

## [1.1.4] - 2026-02-24

### Added

#### Custom Language Import
- **Import language files** — Add any UI language by importing a JSON locale
  file from Settings > Language. Appears immediately in the language
  selector and PDF editor.
- **Delete custom languages** — Remove imported languages via the delete
  button. Falls back to English automatically.
- **PDF language dropdown** — Now lists every installed language, not just
  English and German.
- **Persistent PDF language choice** — Saved per document and restored on
  reopen.
- **Croatian demo locale** — `DEMO_DATA/localization/locale_hr.json`
  included as a ready-to-import example.

### Changed

#### PDF Language System
- Replaced `CvLanguage` enum with a plain language code string. Old
  `pdf_settings.json` files with enum values are upgraded transparently.
- Section headers fall back to English for languages without explicit
  translations.

#### PDF Editor — Full UI Localization
- All hardcoded English strings in the PDF editor now use the localization
  system: sidebar headers, toolbar tooltips, template panel buttons, info
  panels, and cover letter preset descriptions.

### Fixed

- Import summary labels were hardcoded English; now translated correctly.

---

## [1.1.3] - 2026-02-20

### Fixed

#### Backup & Restore
- **Profile pictures missing after restore** — `profilePicturePath` was an
  absolute path tied to the original machine. Restore now remaps it.
- **Application data inaccessible after restore** — `folderPath` was also
  absolute. Now remapped in the same pass.
- **CV data picture path stale** — `cv_data.json` inside application
  subfolders also stores `profilePicturePath`. All three path types are now
  patched together.

---

## [1.1.2] - 2026-02-20

### Fixed

#### Backup & Restore
- **Restore always failed** — Safety backup used the public `createBackup()`
  which rejects destinations inside UserData.
- **Old backups rejected** — Pre-v1.1.1 backups without `manifest.json` were
  incorrectly treated as invalid. Manifest is now optional.
- **Incomplete restore** — `pdf_presets/`, `preferences.json`, and other
  files were not covered by the atomic rename/rollback cycle.
- **Foreign files written to UserData** — Non-UserData entries from ZIPs
  were extracted. Restore now uses a strict whitelist.
- **Safety backups included nested zips** — `.backup_safety/` and
  `.restore_temp/` are now always excluded.
- **`settings.json` check too broad** — Validator matched any path containing
  `settings.json`. Now requires an exact root-level match.

#### Software Updates
- **False "up to date" report** — Version comparison was gated on download
  availability. Version detection and download are now independent.
- **404 shown as "up to date"** — Now shows a proper error message.
- **Missing download URL** — Falls back to opening the releases page in the
  browser.

---

## [1.1.1] - 2026-02-15

### Backup System Overhaul

This release makes backup and restore safe and reliable for production use.

- **Automatic safety backups** — Current data is backed up before every
  restore. Failed restores roll back automatically. Keeps last 2 safety
  backups.
- **Validation** — Corrupted or invalid files are rejected before extraction.
  Every backup includes metadata (version, timestamp, file counts). Security
  checks prevent malicious files.
- **Atomic restore** — Either completes fully or not at all. No partial
  corruption.
- **Better UX** — Warning dialog before backup creation. Clear error messages
  for disk full, permission denied, etc.

### Bug Fixes

- Settings could be lost due to path inconsistencies
- Corrupted backups could destroy all user data
- Partial restore could leave data in a broken state

---

## [1.1.0] - 2026-02-14

### Added

#### Full Localization (English & German)
- App-wide localization system via JSON locale files
- All UI strings, skill levels, language proficiency levels, interest levels,
  note types, and note priorities translated
- Personal Info and Work Experience add/edit buttons in Profile tab

### Fixed

- `context.tr()` crash in event handlers — now uses `listen: false`
- About card header formatting inconsistency

---

## [1.0.5] - 2026-02-11

### Added

- **Bilingual statistics export** — Export job application reports as
  Markdown in both English and German
- Professional report structure: executive summary, chronological history,
  status breakdown, and statistics

### Changed

- Export button redesigned to match profile tab style
- Removed underline from job URL links for cleaner appearance

---

## [1.0.4] - 2026-02-02

### Fixed

- German CV translations: language proficiency levels, "at" preposition,
  section labels
- Centralized translation logic in `CvTranslations`

---

## [1.0.3] - 2026-01-20

### Fixed

- Application editor: prevent accidental dismissal; accent-colored close button
- PDF preview responsiveness: reduced debounce, optimized controller changes
- PDF settings persistence: deferred controller updates until after saved
  settings load — no more flashing or incorrect defaults
- Two-Column CV layout: fixed sidebar alignment, text wrapping, and profile
  picture positioning

---

## [1.0.2] - 2026-01-19

### Added

- **Master Profile PDF Preview** — Preview CV and cover letter from the
  Profile tab to check formatting before creating applications
- **Style Preset Management** — PDF style changes in the master profile save
  as defaults; new applications inherit them automatically
- Language-specific presets (EN/DE profiles maintain separate defaults)

---

## [1.0.0] - 2026-01-16

### Initial Release

The first stable release of MyJob — a portable Windows desktop app for
managing job applications.

**Core features:**
- Bilingual profile management (English & German)
- Job application tracking with status, dates, contacts, and notes
- Notes system with types, priorities, tags, due dates, and archiving
- Professional PDF generation with multiple CV and cover letter templates
- Backup & restore with ZIP files
- Five accent color themes, dark and light mode
- Portable UserData folder — no installation required

---

**For older versions, see [GitHub Releases](https://github.com/Schadenfreund/MyJob/releases)**
