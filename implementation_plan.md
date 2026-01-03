# Master Implementation Plan: Bilingual Job-Centric MyLife

**Objective:** Transform "MyLife" from a template manager into a professional, release-ready job application lifecycle tool with exceptional UX.

**Key Philosophy:** "Tailor once, store forever." Every job application gets its own dedicated folder containing a full snapshot of CV and Cover Letter, allowing complete customization without affecting the master profile.

---

## 🗺️ User Workflow Visualization

### 1. The Import (Data Entry)
- **User Action:** Clicks "Import YAML" from Profile Hub
- **Decision:** Selects "Import into **English** Profile" or "Import into **German** Profile"
- **System:** Parses data via enhanced `UnifiedImportDialog` and merges into `profiles/en/base_data.json` or `profiles/de/base_data.json`
- **Result:** Master profile populated with language-specific data

### 2. The Setup (Profile Hub)
- **User Action:** Navigates to "Profile" tab
- **Interaction:** Toggles between "English" and "Deutsch" via prominent language selector
- **Action:** Refines Work Experience, Skills, Education, Cover Letter defaults for that language
- **Visual Feedback:** Language indicator always visible, unsaved changes indicator
- **Result:** Two pristine, independent data sets as source material

### 3. The Application (Job Context)
- **User Action:** Clicks "New Application" in Jobs tab
- **Input:** Enters Company, Position, optional Location/URL/Salary
- **Critical Choice:** Selects **Base Language: German** or **English**
- **System:**
  - Creates folder `UserData/applications/[YYYY-MM-DD]_[Company]_[Position]_[UID]/`
  - **Clones** `MasterProfile (DE)` → `cv_data.json` inside that folder
  - **Clones** Default Cover Letter (DE) → `cl_data.json`
  - Creates `pdf_settings.json` with default style settings
- **Result:** Fully isolated sandbox for this job

### 4. The Tailoring (Customization)
The core workspace replacing old PDF editor fragmentation.

- **User Action:** Opens application → **Tailoring Workspace** launches
- **View:** Split-screen interface with resizable divider
  - **Left Panel (Editor):** Tabs for "CV Content" and "Cover Letter"
  - **Right Panel (Preview):** Live PDF preview with all controls (zoom, templates, styles)
- **CV Edit:** User modifies bullet points to match job keywords
  - System updates `cv_data.json` in job folder only
  - PDF preview refreshes with debounced updates
- **Cover Letter Edit:** User adapts greeting and body
  - System updates `cl_data.json`, preview refreshes
- **Visuals:** User adjusts accent color, font, template via toolbar
  - System updates `pdf_settings.json`

### 5. The Output (Export)
- **User Action:** Clicks "Export PDF" in tailoring workspace
- **System:** Renders job-specific data → `exports/[Company]_CV.pdf`
- **Bonus:** "Export Both" button for CV + Cover Letter in one click
- **Result:** Professional, tailored PDFs ready for submission

---

## 🏗️ Phase 1: Architecture & Foundation

**Goal:** Establish robust, portable file system structure with clear data separation.

### 1.1 New Portable Directory Structure

Replace current flat structure with hierarchical layout:

```text
UserData/
├── profiles/
│   ├── en/
│   │   ├── base_data.json           # Master English Profile
│   │   └── default_cover_letter.json # Default EN cover letter body
│   └── de/
│       ├── base_data.json           # Master German Profile  
│       └── default_cover_letter.json # Default DE cover letter body
├── applications/
│   └── [YYYY-MM-DD]_[Company]_[Position]_[UID]/
│       ├── application.json         # Job metadata (status, dates, salary)
│       ├── cv_data.json             # TAILORED CV content (cloned from master)
│       ├── cl_data.json             # TAILORED Cover Letter content
│       ├── pdf_settings.json        # Visual settings (fonts, colors, template)
│       └── exports/
│           ├── [Company]_CV.pdf
│           └── [Company]_CoverLetter.pdf
└── settings.json                    # App-wide settings (theme, etc.)
```

### 1.2 Data Model Changes

#### [MODIFY] job_application.dart
- Add `DocumentLanguage baseLanguage` enum field (EN/DE)
- Add `String folderPath` for direct folder reference
- Remove legacy `cvInstanceId` and `coverLetterInstanceId` (data now stored in folder)
- Add `DateTime? interviewDate`, `DateTime? followUpDate` for tracking

#### [NEW] master_profile.dart
Consolidated profile model with `PersonalInfo`, `WorkExperience`, `Education`, `Skills`, `Languages`, `Interests`, `defaultCoverLetterBody`, `language`.

#### [NEW] job_cv_data.dart
Tailored CV data for a specific job (same structure as MasterProfile but stored per-job).

#### [NEW] job_cover_letter.dart
Tailored cover letter with `recipientName`, `greeting`, `body`, `closing`, `signature`.

### 1.3 Storage Service Enhancement

#### [MODIFY] storage_service.dart
Add new methods:
- `loadMasterProfile(DocumentLanguage lang)` / `saveMasterProfile()`
- `cloneProfileToApplication(MasterProfile source, JobApplication app)`
- `loadJobCvData(folderPath)` / `saveJobCvData()`
- `loadJobPdfSettings(folderPath)` / `saveJobPdfSettings()`

---

## 🧩 Phase 2: Component Refactoring (DRY)

**Goal:** Extract reusable "presentation" widgets from existing editors that take data in and emit changes out.

### 2.1 Widget Extraction

Extract from `TabbedCvEditor` (1353 lines):

| New Widget | Replaces | Usage |
|------------|----------|-------|
| `ExperienceListEditor` | Experience tab | Profile + Tailoring |
| `EducationListEditor` | Education tab | Profile + Tailoring |
| `SkillsEditor` | Skills tab | Profile + Tailoring |
| `LanguagesEditor` | Languages section | Profile + Tailoring |
| `ContactInfoEditor` | Contact tab | Profile + Tailoring |
| `CoverLetterEditor` | CL editor | Profile + Tailoring |

**Pattern:** Each widget takes `data` in, emits `onChanged` out—no Provider dependency.

---

## 🇩🇪 Phase 3: Bilingual Profile Hub

**Goal:** Allow managing two independent profiles (EN/DE) with seamless switching.

### 3.1 Profile Screen Redesign

#### [MODIFY] profile_screen.dart
- Add prominent language toggle (segmented button: "English | Deutsch")
- Show current language with flag icon in header
- Add "Default Cover Letter" section with rich text editor
- Visual indicator when switching languages

### 3.2 Enhanced YAML Import

#### [MODIFY] unified_import_dialog.dart
- Add language target selector after file parsing
- Show preview: "Will add X experiences to German profile"
- Handle merge/replace per language independently

---

## 💼 Phase 4: Unified Job Workflow

**Goal:** Replace fragmented Documents/Tracking with unified job-centric workflow.

### 4.1 Enhanced Applications Screen

#### [MODIFY] applications_screen.dart
- Status filter tabs: All | Active | Pending | Closed
- Cards show: Company, Position, Status, Language flag, Last updated
- Quick actions: Open Tailoring | View PDFs | Archive

### 4.2 Tailoring Workspace (New Screen)

#### [NEW] tailoring_workspace.dart

Split-screen interface:
```
┌─────────────────────────────────────────────────────────────┐
│  ← Back    |  Google - Flutter Developer  |  ✓ Save        │
├──────────────────────┬──────────────────────────────────────┤
│  📝 CV Content      │     [LIVE PDF PREVIEW]               │
│  ✉️ Cover Letter    │     Templates: [Modern ▼]            │
│ ─────────────────── │     Accent: [●] Font: [Inter ▼]     │
│  [Contact Info]      │         ┌──────────────┐             │
│  [Experience]        │         │   CV Page 1   │             │
│  [Education]         │         └──────────────┘             │
│  [Skills]            │     [−] [100%] [+] [Export ▼]       │
└──────────────────────┴──────────────────────────────────────┘
```

**Left Panel:** Uses extracted editor widgets (Phase 2), auto-save, "Reset to Profile" action
**Right Panel:** Reuses `BaseTemplatePdfPreviewDialog` preview logic, toolbar, sidebar

### 4.3 Reusable PDF Preview

#### [NEW] live_pdf_preview.dart
Wraps `EnhancedPdfViewer` + toolbar + sidebar for embedding in Tailoring Workspace.

---

## 🔄 Phase 5: Import & Migration

### 5.1 Legacy Data Migration

#### [NEW] migration_service.dart
- Detect `user_data.json` on startup
- Migrate to `profiles/en/base_data.json`
- Show progress toast

### 5.2 Smart Import Enhancements
- Language target selector in import dialog
- Bulk import support
- Validation warnings for missing fields

---

## ✨ Phase 6: UX Polish

- Loading states with skeleton screens
- Smooth screen transitions
- Empty states with CTAs
- Keyboard shortcuts: `Ctrl+S` save, `Ctrl+E` export, `Ctrl+1/2` switch tabs

---

## 🧪 Verification Plan

### Manual Tests

| Test | Steps | Expected |
|------|-------|----------|
| YAML Import | Import → Select German → Verify | Data in German profile only |
| Profile Isolation | Add skill to EN → Switch to DE | Skill NOT in DE profile |
| Job Creation | New App → German → Open | Tailoring shows German data |
| Tailoring Isolation | Edit experience → Save → Check Profile | Master unchanged |
| PDF Export | Export from Tailoring | PDF has tailored content |
| Portability | Copy UserData folder → Launch | All data loads |

---

## 📋 Implementation Order

1. **Phase 1.1-1.3**: Directory structure + Storage Service
2. **Phase 3.1**: Bilingual Profile Hub 
3. **Phase 2.1**: Extract reusable editor widgets
4. **Phase 4.1-4.2**: Applications screen + Tailoring Workspace
5. **Phase 5.1**: Migration service
6. **Phase 6**: Polish and release prep
