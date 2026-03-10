# Changelog

All notable changes to MyJob will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.8] - 2026-03-09

### Added

#### PDF Editor — Cover Letter Toggles in Two-Column Layout
- **Show Greeting / Show Closing toggles** were missing from the `Two-Column` layout preset case in the sidebar. Now all four layout preset cases (Modern, Compact, Traditional, Two-Column) expose the full set of cover letter display options.

### Fixed

#### PDF Editor — Layout Preset Persistence
- **Preset choice silently discarded** — `setLayoutPreset()` was not calling `_scheduleSave()`, so switching to a layout preset was never written to disk. The selection was also not setting `_hasExplicitCustomization`, meaning the async global-customization load could overwrite the preset if it resolved after the switch. Both guards are now applied.

### Changed

#### PDF Editor — `LayoutPreset` Locale Key
- Added `localeKey` getter to `LayoutPreset` (e.g. `'layout_preset_modern'`). `PdfEditorController.currentLayoutPresetName` now returns this key instead of a hardcoded English string.
- The sidebar translates `PdfPreset.basedOnPresetName` via `context.tr()`. Old saved presets that stored raw English names (`"Modern"`, `"Compact"`, etc.) fall back gracefully — `AppLocalizations.translate` returns the key itself when no match is found, so the displayed text is unchanged.

#### PDF Editor — Dead Code Removal
- Removed `setStyle()` from `PdfEditorController` — it was never called anywhere and was a confusing duplicate of `updateStyle()` with subtly different equality logic.
- Removed the unused `label` field from the `PdfViewMode` enum. The PDF toolbar already uses its own `context.tr()` switch methods and never accessed `.label`.

---

## [1.1.7] - 2026-03-09

### Added

#### PDF Editor — Cover Letter Display Options
- **Show Greeting toggle** — sidebar toggle to hide/show the greeting line in cover letter PDFs. Available in Modern, Compact, and Traditional layout presets.
- **Show Closing toggle** — sidebar toggle to hide/show the closing line in cover letter PDFs. Same presets as above.
- Both toggles persist via `TemplateCustomization` (backward-compatible: old `cv_customization.json` files without these keys default to `true`).
- Localized in English (`Show Greeting`, `Show Closing`) and German (`Anrede anzeigen`, `Grußformel anzeigen`).

### Fixed

#### PDF Editor — Backward-Compatible JSON Deserialization
- **`TypeError` on old UserData import** — `spacingScale`, `fontSizeScale`, `lineHeight`, and `sidebarWidthRatio` were deserialized with `as double?`, which throws a `TypeError` when the stored JSON value is an integer (e.g. `1` instead of `1.0`). Changed to `(as num?)?.toDouble()` for safe integer/double handling.

#### PDF Editor — Race Condition on Settings Load
- **Job-specific settings silently overwritten** — `PdfEditorController` loads global customization preferences asynchronously in its constructor. If this async load completed after the job dialog had already applied its own saved settings, the job-specific values were silently discarded. Fixed with an `_hasExplicitCustomization` guard flag that prevents the global load from overwriting explicitly-set customization.

#### PDF Editor — Cover Letter Subject Not Saved
- **Subject field edits not persisted** — Edits to the subject line in the cover letter edit panel updated the in-memory state and regenerated the PDF correctly, but `_saveFieldChanges()` omitted `subject` from the `copyWith` call so changes were never written to disk.

### Changed

#### PDF Code — DRY Cleanup (Cover Letter Templates)
- Extracted `_formatDate` (identical across all 4 cover letter templates) and `splitBodyParagraphs` (paragraph normalization, also identical) into a new `CoverLetterHelpers` abstract final class in `lib/pdf/shared/cover_letter_helpers.dart`.
- All 4 cover letter templates (`classic`, `professional`, `electric`, `modern_two`) now use `CoverLetterHelpers.formatDate()` and `CoverLetterHelpers.splitBodyParagraphs()` — the local private methods have been removed.
- `CoverLetterHelpers` is exported from the existing `lib/pdf/shared/shared.dart` barrel file.

---

## [1.1.6] - 2026-03-08

### Fixed

#### Profile Import / Export — Full Round-Trip Fidelity

- **Work experience `description` not exported** — Descriptions on work experience entries were silently dropped on export, causing data loss when re-importing an exported file. The field is now written as a YAML literal block scalar.
- **`default_cover_letter` ignored on import** — CV YAML files that contain a `default_cover_letter` section (matching the export format) were parsed but the value was discarded. It is now applied to the profile's default cover letter body on import.
- **Interest `level` not exported** — The optional `InterestLevel` (Casual / Moderate / Passionate) was parsed on import but never written on export. Both directions now round-trip correctly.
- **Interest `level` not parsed on import** — Even when a YAML file contained a `level` key for an interest entry, the value was not read. A `_parseInterestLevel()` helper (matching the existing skill/language parsers) now handles it.

#### Profile Import — Target Profile Selector

- **Importing always wrote to the active app profile** — The import dialog now shows a **Target Profile** chip row at the top of the header, listing every available language (built-in and custom-imported). Selecting a chip sets a local target without changing the global app language. Languages that do not yet have a profile show a `NEW` badge; selecting one creates the profile automatically before importing.
- **Cover letter import ignored the target selector** — The cover letter import path previously auto-detected language from the file name and switched the global profile as a side effect. It now respects the same target chip selection as CV imports.
- **Silent failure on first use** — On a fresh install (no profiles created yet) the import dialog reported success while writing nothing, because every provider write method guards against a null current profile. The dialog now ensures the target profile exists (creating it if needed) before any write operations.

#### Import Service — Robustness

- **Duplicate language-detection code** — The identical language-detection block existed in both `_parseCvData` and `_parseCoverLetter`. Extracted into a single `_detectLanguage()` private helper.
- **Fragile file-path basename** — `filePath.split('/').last.split('\\').last` was used to extract the file name for cover letter template naming; replaced with `File(filePath).uri.pathSegments.last` which is correct on all platforms.

---

## [1.1.5] - 2026-03-07

### Fixed

#### UserData Portability
- **Relative path storage** — `folderPath` and `profilePicturePath` are now stored as paths relative to the UserData root instead of absolute paths. Existing UserData folders can be freely moved or copied to a new location without breaking application links or profile pictures.
- **Backward-compatible path resolution** — Stale absolute paths from a previous location are transparently recovered at load time by scanning path segments for known top-level directory names (`applications`, `profiles`, etc.) and re-anchoring them to the current UserData root.
- **Backup/restore guard** — `_detectOldUserDataPath` in the backup service now requires an absolute path before attempting path remapping, preventing catastrophic JSON corruption when relative paths (e.g. `applications\folder`) were mistakenly used as the base for string replacement.

#### Notes — Formatting Preserved on Reopen
- **Multi-line note text now round-trips correctly** — Literal newlines in note descriptions, URLs, and other string fields were silently collapsed to spaces by the YAML double-quoted scalar line-folding rule. The custom `_jsonToYaml` serializer now escapes `\n`, `\r`, and `\\` correctly so the YAML reader restores the original text exactly.

#### Notes — Clearing Nullable Fields
- **Nullable note fields can now be explicitly cleared** — `NoteItem.copyWith` used the `value ?? this.value` pattern, which made it impossible to set a nullable field (description, URL, contact person, contact email, location, due date, completedAt) back to `null`. Fixed with a private `_unset` Object sentinel so `copyWith(description: null)` correctly clears the field.

---

## [1.1.4] - 2026-02-24

### Added

#### Custom Language Import
- **Import language files** - Add custom UI languages by importing a JSON locale file directly from Settings → Language. The new language immediately appears in the language selector and in the PDF editor's language dropdown.
- **Delete custom languages** - Remove imported languages via the delete button next to each custom language entry. Switching away from the active language falls back to English automatically.
- **PDF language dropdown sources all available languages** - The language selector in the PDF editor now lists every installed language (built-in and custom), not just English and German.
- **Persistent PDF language choice** - The selected PDF content language is saved per document and restored when reopening the PDF editor. Previously the choice was always overridden on reopen.
- **Croatian demo locale** - `DEMO_DATA/localization/locale_hr.json` included as a ready-to-import example for the custom language feature.

### Changed

#### PDF Language System
- Replaced the internal `CvLanguage` enum (`english`/`german`) with a plain language code string (`'en'`/`'de'`). Old `pdf_settings.json` files with enum values are transparently upgraded on load.
- PDF section headers and labels fall back to English for any language code without explicit translations in `CvTranslations`.

#### PDF Editor — Full UI Localization
- All hardcoded English strings in the PDF editor are now translated via the app's localization system:
  - Sidebar section headers, layout preset names and descriptions, font selector message
  - Toolbar tooltips and view-mode labels (Single Page, Side by Side, Fit Width)
  - Template Edit Panel header, Save Changes and Cancel buttons
  - Info panels in the Job Application and Master Profile PDF dialogs
  - Cover letter template preset section (Design Preset header and descriptions)
- Sub-header in the PDF editor top bar now shows a human-readable name (e.g. `Acme Corp · Developer · CV`) instead of the raw filename-safe string.

### Fixed

- Import summary labels (Personal Info, Skills, Work Experience, etc.) were hardcoded English; they now use locale keys and translate correctly.

---

## [1.1.3] - 2026-02-20

### Fixed

#### Backup & Restore

- **Profile pictures missing after restore** - `profilePicturePath` in
  `profiles/<lang>/base_data.json` was stored as an absolute path tied to
  the original machine. After restoring to a different location the picture
  appeared missing even though the image file was correctly present in the
  backup. Restore now rewrites the path to the current UserData location.
- **Application CV/Cover Letter inaccessible after restore** - `folderPath`
  in `applications/<uuid>.json` was stored as an absolute path. After
  restoring to a different drive/location the app could not find the folder,
  showing "folder does not exist" and "failed to load CV data". Restore now
  rewrites `folderPath` to the current UserData location.
- **CV data profile picture path stale after restore** - `cv_data.json`
  inside each application subfolder also stores `profilePicturePath` as an
  absolute path that was not updated on restore. All three path types are now
  patched in a single remapping pass after atomic replace.

---

## [1.1.2] - 2026-02-20

### Fixed

#### Backup & Restore

- **Restore always failed** - Safety backup was saved inside UserData using the public `createBackup()` which explicitly rejects destinations inside UserData. Every restore attempt threw at Step 2 before any data was touched
- **Old backups rejected** - Backups created before v1.1.1 (without `manifest.json`) were incorrectly treated as invalid. Manifest is now optional; legacy backups are accepted and validated by structure instead
- **Incomplete restore** - `pdf_presets/`, `preferences.json`, `cv_customization.json`, and `.migrated` were not included in the atomic rename/rollback cycle. A mid-restore failure left these files in a broken state with no rollback coverage
- **Foreign files written to UserData** - Zip files containing non-UserData entries caused those to be placed into UserData. Restore now uses a strict whitelist of known entries
- **Safety backups included nested zips** - `.backup_safety/` and `.restore_temp/` were zipped into new backups, creating bloated and potentially recursive archives. Both folders are now always excluded
- **`settings.json` structure check too broad** - Validator matched any path containing `settings.json` (e.g. `applications/.../pdf_settings.json`). Now requires exact root-level match

#### Software Updates

- **Update check reported "up to date" when newer version exists** - Version comparison was incorrectly gated on `hasValidDownload`. If the GitHub release had no matching Windows ZIP asset, the check silently fell through to "up to date" despite a newer version being available. Version detection and download availability are now independent
- **404 response incorrectly shown as "up to date"** - A 404 from the GitHub API now shows a proper error message instead of falsely reporting the current version is current
- **Missing download URL caused silent failure** - If `downloadUpdate()` was called without a valid download URL, it failed silently. Now falls back to opening the GitHub releases page in the browser

---

## [1.1.1] - 2026-02-15

### Backup System Overhaul - Production Ready

This release makes the backup/restore feature **safe and reliable** for production use. All critical data loss scenarios are now prevented.

### What's New

#### Automatic Safety Backups

- App automatically backs up current data before any restore operation
- Failed restores automatically roll back to original state
- Keeps 2 most recent safety backups in `.backup_safety/` folder

#### Smart Validation

- Corrupted or invalid backup files are detected and rejected before extraction
- Every backup includes metadata (version, timestamp, file counts)
- Security checks prevent malicious files

#### Bulletproof Restore

- Restore either completes fully or not at all - no partial corruption
- Uses atomic operations to prevent data loss during restore
- Automatic cleanup of temporary files

#### Better User Experience

- Warning dialog before backup creation to prevent accidental changes
- Clear, helpful error messages ("disk full", "permission denied", etc.)
- No more cryptic technical errors

### Bug Fixes

- Fixed: Settings could be lost due to path inconsistencies
- Fixed: Corrupted backups could destroy all user data
- Fixed: Partial restore could leave data in broken state
- Fixed: No protection against restore failures

---

## [1.1.0] - 2026-02-14

### Added

#### Full Localization (English & German)
- **App-wide localization system** - All UI strings now support English and German via JSON locale files
- **Software Updates card** - Fully translated (all update states: checking, downloading, installing, errors)
- **Skill levels** - Beginner, Intermediate, Advanced, Expert now localized (German: Anfänger, Fortgeschritten, Erfahren, Experte)
- **Language proficiency levels** - Native, Fluent, Advanced, Intermediate, Basic now localized (German: Muttersprache, Fließend, etc.)
- **Interest levels** - Casual, Moderate, Passionate now localized
- **Note types** - To-Do, Company Lead, General Note, Reminder now localized (German: Aufgabe, Firmenkontakt, etc.)
- **Note priorities** - Low, Medium, High, Urgent now localized (German: Niedrig, Mittel, Hoch, Dringend)
- **Interests section** - Added missing translations: `interests_desc`, `interests_empty_message`, `add_first_interest`

#### Profile Tab Enhancements
- **Personal Info edit/add button** - ProfileSectionCard now shows Edit button (or Add when empty) directly in the card header
- **Work Experience add button** - ProfileSectionCard now shows Add button in the card header, matching Skills/Languages/Education pattern

### Fixed

#### Provider Listen Bug
- **Fixed crash when using translations in event handlers** - `context.tr()` now uses `listen: false` to prevent `Provider.of` assertion errors when called from `onPressed`, dialogs, and other non-build contexts
- Removed fragile `tr`/`trRead` dual API in favor of single safe `context.tr()` that works everywhere

#### Settings Tab
- **About card header formatting** - Now uses shared `AppCardHeader` widget for consistent title/subtitle sizing and layout matching other cards

### Technical
- Added `localizationKey` getter to `SkillLevel`, `LanguageProficiency`, `InterestLevel`, `NoteType`, and `NotePriority` enums
- PDF generation continues to use English `displayName` — localization only affects UI
- Added static `showEditDialog` to `PersonalInfoSection` and `showAddDialog` to `WorkExperienceSection`

---

## [1.0.5] - 2026-02-11

### Added

#### Application Statistics Export
- **Bilingual Markdown Reports** - Export comprehensive job application reports in both English and German
  - Two separate markdown files generated: `Application_Statistics_EN_[date].md` and `Application_Statistics_DE_[date].md`
  - Professional report structure with executive summary, chronological history, status breakdown, and statistical overview
  - Clean, emoji-free formatting for professional documentation
  
#### Report Structure
- **Executive Summary** - Overview of total applications, active/closed counts, and key success metrics
- **Application History** - Chronological table of all applications with:
  - Application date
  - Company and position details
  - Location
  - Current status
  - Notes (truncated for readability)
- **Applications by Status** - Grouped breakdown by status (Interviewing, Applied, Draft, Successful, Rejected, No Response)
- **Statistical Overview** - Status distribution with percentages and overall statistics

### Changed

#### UI/UX Improvements
- **Export Button Redesign** - Replaced icon button with professional "Export Report" button
  - Styled to match profile tab export buttons using `AppCardActionButton`
  - Positioned at bottom of expanded statistics card
  - Only visible when statistics card is expanded
  - Consistent design language across the application

- **Job URL Links** - Removed underline decoration from job URL links in application cards for cleaner appearance
  - Links remain clickable and styled in primary color
  - Maintains link icon for visual identification

### Technical

- Created `ApplicationStatisticsMarkdownService` for markdown generation
- Implemented language-specific report generation (English/German)
- Added folder selection dialog for saving both markdown files simultaneously
- Integrated with existing `AppCardActionButton` component for consistency
- Clean, maintainable code following DRY principles

---

## [1.0.4] - 2026-02-02

### Fixed

#### German Localization for CV Templates
- **Language Proficiency Levels** - Now properly translate to German (Beginner→Anfänger, Intermediate→Fortgeschritten, Advanced→Sehr gut, Fluent→Fließend, Native→Muttersprache, Basic→Grundkenntnisse). Includes CEFR levels (A1-C2).
- **Experience Preposition** - "at" now translates to "bei" in compact layout (e.g., "Software Engineer bei Google")
- **Section Labels** - "Languages:" → "Sprachen:", "Interests:" → "Interessen:"

#### Technical
- Extended `CvTranslations` with `translateLanguageLevel()` and `translateLabel()` methods
- Centralized all translation logic following DRY principles
- Fixed in 4 files: cv_translations.dart, experience_component.dart, professional_cv_template.dart, electric_cv_template.dart

---

## [1.0.3] - 2026-01-20

### Fixed

#### UI/UX Improvements
- **Application Editor Modal** 
  - Prevent accidental dismissal by disabling outside-click and back button closing
  - Accent-colored close button (X) for better visibility
  - Only closable via explicit X button click to prevent data loss
- **PDF Preview Responsiveness**
  - Improved PDF regeneration timing for more responsive UI updates
  - Reduced debounce delay from 300ms to 150ms
  - Optimized controller change handling for immediate visual feedback
  - Fixed issues where PDF preview didn't update when toggling buttons or changing templates
  - Enhanced state management to ensure reliable PDF updates
- **PDF Settings Persistence** ✅
  - **FIXED**: PDF color and design preset settings now properly persist when reopening preview dialogs
  - **Root Cause**: Controller updates in `initState()` triggered premature PDF regeneration with default values
  - **Solution**: Deferred ALL controller updates until after saved settings load
  - Base class listener is temporarily removed during settings load to prevent interference
  - After settings load: base listener restored, subclass listener added, PDF generated once with correct settings
  - Added protected API methods in base class: `removeBaseControllerListener()`, `addBaseControllerListener()`, `generatePdf()`
  - Initial PDF generation deferred via `shouldSkipInitialGeneration()` mechanism
  - PDF now displays with saved settings from the very first render
  - No flashing, no button pressing needed
  - Clean, robust architecture following DRY principles
- **Two-Column CV Layout**
  - Fixed top margin alignment between sidebar and main column
  - Conditionally apply top padding only when no profile picture exists
  - Profile pictures now start at the very top of the accent sidebar
  - Fixed text rendering issues in accent sidebar
  - Added proper width constraints to all sidebar text elements
  - Enabled text wrapping (`softWrap`) for contact info, headers, and sections
  - Long emails and addresses now wrap properly instead of disappearing
  - Sidebar content always renders correctly regardless of content length or width

---

## [1.0.2] - 2026-01-19

### Added

#### Master Profile PDF Preview
- **PDF Preview Buttons** in Profile tab for CV and Cover Letter sections
  - Preview CV with master profile data to check formatting
  - Preview Cover Letter with default content to check formatting
  - Buttons only active when content exists
- **Style Preset Management** 
  - PDF style changes in master profile save as default presets
  - New job applications automatically inherit saved style presets
  - Separate presets for CV and Cover Letter
  - Language-specific presets (EN/DE profiles maintain separate defaults)
- **MasterProfilePdfDialog** component
  - Extends BaseTemplatePdfPreviewDialog for consistency
  - Read-only preview (no content editing)
  - Full style customization with preset saving
  - Export functionality to user's preferred location


#### Technical Improvements
- Added `loadMasterProfileCvPdfSettings()` / `saveMasterProfileCvPdfSettings()` to StorageService
- Added `loadMasterProfileClPdfSettings()` / `saveMasterProfileClPdfSettings()` to StorageService
- Preset storage: `UserData/profiles/{lang}/cv_pdf_settings.json` & `cl_pdf_settings.json`
- Clean DRY architecture reusing existing PDF editor base

### Benefits
- Users can validate PDF formatting before creating job applications
- Consistent default styling across all new job applications
- No more manual style configuration for each new application
- Quick visual check for master profile content quality

---

## [1.0.0] - 2026-01-16

### 🎉 Initial Release

The first stable release of MyJob - a comprehensive job application management tool.

### Added

#### Core Features
- **Bilingual Profile Management** - English and German profile support
- **Job Application Tracking** - Complete CRUD for job applications
- **Notes System** - Create, archive, search, and organize notes
- **PDF Generation** - Professional CV and cover letter creation
- **Backup & Restore** - Full data backup and restore functionality

#### Profile Features
- Master profile template for reuse across applications
- Personal information management
- Work experience tracking
- Education history
- Skills with proficiency levels
- Languages with proficiency levels
- Interests
- Profile summary editing
- Default cover letter template
- Profile picture support

#### Application Features
- Application status tracking (Draft, Applied, Interview, Accepted, Rejected)
- Company and position details
- Application dates
- Salary expectations
- Contact person tracking
- Notes per application
- Time-based filtering (7/30/90 days)
- Search functionality
- Statistics overview

#### Notes Features
- Multiple note types (To-Do, Company Lead, General Note, Reminder)
- Priority levels (Low, Medium, High)
- Tags for organization
- Archive system
- Search by title, description, and tags
- Collapsible sections (Active, Completed, Archived)
- Mark as complete functionality

#### PDF Features
- Multiple CV templates
- Customizable colors and fonts
- Cover letter generation
- Live preview before export
- Template-based system
- Job-specific customization

#### Settings Features
- 5 accent color themes (Blue, Green, Cyan, Orange, Red)
- Dark and Light mode
- Backup destination selection
- Data management tools
- Application statistics display

#### User Experience
- Empty profile warning system
- Smart navigation (Profile tab suggestion)
- Auto-save functionality
- Consistent Material Design 3 UI
- Custom titlebar with window controls
- Responsive design
- Collapsible sections with state persistence

### Technical Implementation
- Provider state management pattern
- Clean architecture with separation of concerns
- Centralized design system (AppTheme, AppColors, AppSpacing)
- Reusable UI components (AppCard, AppCardContainer, UIUtils)
- YAML-based data storage
- Portable UserData folder structure
- Windows-first desktop application
- Material Design 3

### Developer Experience
- Well-organized code structure
- Comprehensive error handling
- Debug logging
- Clean separation between UI and business logic
- Reusable services (StorageService, PreferencesService, BackupService)
- Consistent coding patterns

---

## [Unreleased]

### Planned for v1.1
- Additional CV templates
- Email integration for applications
- Application deadline reminders
- Enhanced statistics dashboard
- Multi-language support (beyond EN/DE)

---

## Notes

### Version Numbering
- Major version: Significant new features or breaking changes
- Minor version: New features, backwards compatible
- Patch version: Bug fixes and minor improvements

### Deprecation Policy
- Deprecated features will be marked for at least one minor version before removal
- Migration guides will be provided for breaking changes

---

**For older versions, see [GitHub Releases](https://github.com/yourusername/MyJob/releases)**
