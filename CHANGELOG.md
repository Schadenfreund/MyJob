# Changelog

All notable changes to MyJob will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
