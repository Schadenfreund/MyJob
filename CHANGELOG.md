# Changelog

All notable changes to MyJob will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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
