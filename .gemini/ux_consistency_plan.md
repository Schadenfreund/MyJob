# UX Analysis & Consistency Plan

## Current State Analysis

### Profile Tab (Master Data)
**Purpose:** Maintain bilingual master profiles (EN/DE) that feed all applications

**UI Elements:**
- Header with language toggle (EN/DE buttons)
- Quick Actions row (Import/Export buttons)
- Vertical sections using specialized components:
  - PersonalInfoSection
  - WorkExperienceSection  
  - EducationSection
  - SkillsSection
  - LanguagesSection
  - _buildInterestsSection (local method)
  - _buildProfileSummarySection (local method)
  - _buildDefaultCoverLetterSection (local method)

**Interaction Patterns:**
- Each section has dedicated dialogs/screens for editing
- Some sections editable inline (Interests, Profile Summary, Cover Letter)
- Collapsed/Expanded states (CollapsibleCard)

---

### Applications Tab (Job-Specific Data)
**Purpose:** Manage individual job applications with cloned+tailored data

**UI Elements:**
- Application cards organized by status (Draft, Applied, Interview, etc.)
- Each card shows:
  - Company/Position
  - Language badge (🇬🇧 EN / 🇩🇪 DE)  
  - Status badge
  - Application date, location, salary
  - Action buttons: Edit, CV Style, Cover Letter, Folder, Delete

**Interaction Patterns:**
- Edit button → Opens JobCvEditorWidget (8-tab editor)
- CV Style → PDF preview/customization dialog
- Cover Letter → Cover Letter PDF dialog
- New Application → Dialog → Auto-opens PDF editor

---

### Job CV Editor Widget (Edit Content)
**8 Tabs:**
1. Details - Application metadata + Profile Summary
2. Personal Info - Contact details
3. Experience - Work history (cards with add/edit/delete)
4. Education - Academic history (cards with add/edit/delete)
5. Skills - Chip-based editor
6. Languages - List with add/edit/delete
7. Interests - Chip-based editor  
8. Cover Letter - Full form editor

**Interaction:**
- Tabbed interface for navigation
- Mixed edit patterns (inline, dialogs, cards)
- Auto-save on changes

---

## Identified Issues

### 1. Inconsistent Edit Patterns
**Profile Tab:**
- Personal Info → Separate screen
- Experience → Separate screen/dialog
- Education → Dialog
- Skills → Inline chips → Dialog for add/edit
- Languages → Inline list → Dialog
- Interests → Inline with dialog
- Profile Summary → Inline text field
- Cover Letter → Inline text field

**Job Editor:**
- Details → Inline fields + Profile Summary inline
- Personal Info → Inline fields
- Experience → Cards → Dialog
- Education → Cards → Dialog
- Skills → Tabs/chips → Dialogs
- Languages → Tabs/list → Dialogs
- Interests → Tabs/chips
- Cover Letter → Inline form

**Problem:** No consistent pattern for "how to edit a section"

### 2. Data Duplication
- Profile tab has "Profile Summary" 
- Job editor has "Profile Summary" 
- Both should be clear which is master vs. job-specific

### 3. Navigation Confusion
- Profile: Vertical scroll through sections
- Job Editor: Horizontal tabs
- Unclear when changes apply to master vs. job

### 4. Missing Edit Capability
- Profile tab sections (Experience, Education, etc.) use read-only component views
- User cannot easily edit imported YAML data without re-importing

---

## Proposed UX Improvements

### Goal: Unified, Consistent Interaction Model

### Design Principle
**"Collapsible Sections → Inline View/Edit → Dedicated Dialogs for Complex Items"**

Apply this pattern to BOTH tabs for consistency.

---

## Solution 1: Unified Section Component Pattern

### Pattern Structure:
```
CollapsibleCard (Section Container)
├─ Header (Title + Summary + Actions)
├─ Collapsed View: Brief summary
└─ Expanded View:
   ├─ Simple Data: Inline edit (text fields, chips)
   └─ Complex Items: Cards with Edit/Delete buttons → Dialog
```

### Implementation:

**For Simple Sections (Skills, Languages, Interests):**
- Expanded shows chips/tags
- "+ Add" button → Simple inline form or small dialog
- Click chip → Edit in small dialog
- Delete icon on chip/tag

**For Complex Sections (Experience, Education):**
- Expanded shows cards (one per item)
- Each card has Edit/Delete actions
- "+ Add" button → Full dialog
- Edit → Full dialog

**For Text Sections (Profile Summary, Cover Letter):**
- Expanded shows large text field
- Edit inline with auto-save
- Character/word count feedback

---

## Solution 2: Consistent Tab Structure

### Profile Tab Redesign:
Keep current structure BUT make sections editable:

```
Profile Tab
├─ Header (Language Toggle, Import/Export)
└─ Scrollable Content:
   ├─ Personal Information (Collapsible → Inline Edit)
   ├─ Profile Summary (Collapsible → Inline Edit)  
   ├─ Work Experience (Collapsible → Cards → Dialog)
   ├─ Education (Collapsible → Cards → Dialog)
   ├─ Skills (Collapsible → Chips → Dialog)
   ├─ Languages (Collapsible → List → Dialog)
   ├─ Interests (Collapsible → Chips → Dialog)
   └─ Default Cover Letter (Collapsible → Inline Edit)
```

### Job Editor Redesign:
Keep tabs BUT standardize content within each tab:

```
Job CV Editor (8 Tabs remain)
Tab 1: Application & Summary
  ├─ Application Details Section (Collapsible → Inline)
  └─ Profile Summary Section (Collapsible → Inline)
  
Tab 2: Personal Info Section (Collapsible → Inline)
Tab 3: Experience Section (Collapsible → Cards → Dialog)
Tab 4: Education Section (Collapsible → Cards → Dialog)  
Tab 5: Skills Section (Collapsible → Chips → Dialog)
Tab 6: Languages Section (Collapsible → List → Dialog)
Tab 7: Interests Section (Collapsible → Chips → Dialog)
Tab 8: Cover Letter Section (Collapsible → Inline Form)
```

---

## Solution 3: Visual Consistency

### Common Component Library:
1. **SectionCard** - Wrapper for all sections
2. **ItemCard** - For Experience, Education entries  
3. **ChipEditor** - For Skills, Interests
4. **ListEditor** - For Languages
5. **LargeTextField** - For Profile Summary, Cover Letter

### Common Styling:
- Same padding, borders, shadows
- Consistent action button styles
- Unified color scheme
- Same animations (expand/collapse)

---

## Solution 4: Clear Data Ownership

### Labels:
**Profile Tab:**
- "Master Profile Summary" (feeds all jobs)
- "Default Cover Letter Template"

**Job Editor:**
- "Profile Summary (Job-Specific)" 
- "Cover Letter (This Application)"

### Visual Distinction:
- Profile tab: Blue accent (Master data)
- Job editor: Green/Orange accent (Job-specific)

---

## Implementation Plan

### Phase 1: Component Standardization
1. Create `EditableSectionCard` component
2. Create `ItemCard` component with edit/delete
3. Create `ChipEditor` component
4. Create `ListItemEditor` component
5. Create `InlineTextField` component

### Phase 2: Profile Tab Refactor
1. Replace PersonalInfoSection with EditableSectionCard
2. Replace WorkExperienceSection with EditableSectionCard + ItemCards
3. Replace EducationSection with EditableSectionCard + ItemCards
4. Replace SkillsSection with EditableSectionCard + ChipEditor
5. Replace LanguagesSection with EditableSectionCard + ListItemEditor
6. Standardize Interests section
7. Enhance Profile Summary section
8. Enhance Cover Letter section

### Phase 3: Job Editor Refinement
1. Wrap each tab content in EditableSectionCard
2. Standardize all dialogs
3. Ensure consistent spacing/padding
4. Add clear labels for master vs. job-specific

### Phase 4: Testing & Polish
1. Test all CRUD operations
2. Verify data flow (master → job)
3. Check keyboard navigation
4. Validate auto-save
5. UI/UX polish

---

## Benefits

✅ **Consistent UX** - Same interaction pattern everywhere
✅ **Editable Profile** - Can now edit imported YAML data
✅ **Clear Data Flow** - Obvious what's master vs. job-specific
✅ **Maintainable** - Shared components, less duplication
✅ **Scalable** - Easy to add new sections
✅ **Professional** - Polished, unified interface

---

## No Functionality Lost

All current features preserved:
- ✅ Bilingual profiles (EN/DE)
- ✅ Import/Export YAML
- ✅ Full CRUD for all sections
- ✅ Job application management  
- ✅ PDF generation/customization
- ✅ Cover letter creation
- ✅ Auto-save
- ✅ Folder organization

---

## Next Steps

1. User approval of plan
2. Create shared component library
3. Implement Profile tab edits
4. Refine Job editor
5. Test & iterate
