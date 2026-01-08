# UX Consistency Plan - Revised

## Clear Purpose Definition

### Profile Tab = **TEMPLATE**
**Purpose:** Import and maintain master template data that feeds all job applications
**Use Case:** "I want to set up my base CV template once, then customize it for each job"

### Applications Tab = **CUSTOMIZED INSTANCES**  
**Purpose:** Create job applications with tailored CVs/Cover Letters and track status
**Use Case:** "I'm applying to Google - let me customize my CV for this specific role"

---

## User Workflow (Current State)

### Profile Tab Workflow
```
1. Import YAML → 
2. Data appears in sections → 
3. ❌ Can't edit! Must re-import YAML to fix errors
```

### Applications Tab Workflow ✅ (User Likes This)
```
1. Create Application (company, position, language) →
2. Template data cloned →
3. Click "Edit" → 8-tab editor opens →
4. Customize CV content for this job →
5. Click "CV Style" → Customize PDF appearance →
6. Click "Cover Letter" → Customize cover letter PDF →
7. Export PDFs for application →
8. Track status (Draft → Applied → Interview → Offer)
```

**This workflow is good! Keep it.**

---

## Key Differences Between Tabs

### What's Different & Why

| Aspect | Profile Tab (Template) | Applications Tab (Instances) |
|--------|------------------------|----------------------------|
| **Data Type** | Master template | Job-specific customized copies |
| **Language** | Switch EN/DE to edit that template | Each application has ONE language |
| **Editing** | ❌ Currently read-only | ✅ Full editing via 8-tab editor |
| **Actions** | Import/Export YAML | Edit, PDF Style, Cover Letter, Track Status |
| **Organization** | Vertical scroll, all sections visible | Cards grouped by status |
| **Volume** | 2 profiles max (EN + DE) | Many applications |

---

## Problem Summary

### Profile Tab Issues:
1. **Can't edit imported data** - Must re-import entire YAML to fix typos
2. **No visual feedback** - Sections just display data, no interaction
3. **Inconsistent with app workflow** - Different editing experience

### Current Experience:
```
User imports YAML with typo in job title →
"Senior Sofware Engineer" (missing 't') →
❌ Can't fix in UI →
Must edit YAML file →
Re-import entire file
```

**This is frustrating!**

---

## Solution: Add Editing to Profile Tab

### Principle:
**"Profile tab should feel like editing ONE job application"**

Use the **same 8-tab editor** that users already know from Applications tab!

---

## Proposed Profile Tab UI

### Current:
```
Profile Screen
├─ Header (Language toggle, Import/Export)
└─ Vertical sections (read-only components)
   ├─ PersonalInfoSection
   ├─ WorkExperienceSection  
   ├─ EducationSection
   ├─ SkillsSection
   ├─ LanguagesSection
   ├─ Interests
   ├─ Profile Summary
   └─ Default Cover Letter
```

### New:
```
Profile Screen
├─ Header
│  ├─ Language Toggle: [🇬🇧 EN] [🇩🇪 DE]
│  ├─ "Editing: English Template" or "Editing: German Template"
│  └─ Actions: [Import YAML] [Export YAML] [Edit Template →]
│
└─ Content:
   Option A: Same vertical sections BUT with "Edit" buttons
   Option B: Click "Edit Template" → Opens SAME 8-tab editor
```

### Recommended: **Option B** (Reuse existing editor)

**Why:**
- ✅ Zero new code - reuse JobCvEditorWidget
- ✅ Familiar UX - users already know this editor
- ✅ Consistent - same editing experience everywhere
- ✅ Maintainable - one editor to update, not two

---

## Clear Labeling Solution

### Profile Tab:
- Title: **"Profile Templates"** (not "Profile")
- Subtitle: "Master CV data for all your job applications"
- When editing: **"Editing English Template"** or **"Editing German Template"**
- Sections: Just "Profile Summary", "Cover Letter" (no extra labels)

### Applications Tab:
- Title: **"Job Applications"** (current)
- Card titles: Company name (e.g., "Google - Software Engineer")
- When editing: **"Editing CV for Google"**
- Sections: "Profile Summary", "Cover Letter" (no "job-specific" label - it's obvious from context!)

**Context makes it clear** - no confusing labels needed!

---

## Implementation Plan

### Phase 1: Enable Profile Editing

**Option 1 (Minimal Work):** Add "Edit" button to Profile screen
```dart
// In ProfileScreen._buildHeader()
FilledButton.icon(
  onPressed: () => _editTemplate(context),
  icon: Icon(Icons.edit),
  label: Text('Edit Template'),
)

// Opens same editor with master profile
void _editTemplate(BuildContext context) async {
  final provider = context.read<UserDataProvider>();
  final profile = provider.currentProfile;
  
  // Convert MasterProfile → JobCvData for editing
  final cvData = JobCvData.fromMasterProfile(profile);
  
  // Open SAME editor widget
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Edit ${profile.language.label} Template')),
        body: JobCvEditorWidget(
          cvData: cvData,
          onUpdate: (updated) {
            // Convert back: JobCvData → MasterProfile
            provider.updateFromCvData(updated);
          },
          applicationContext: null, // No job context for templates
        ),
      ),
    ),
  );
}
```

**Option 2 (Better UX):** Inline editing per section
- Add edit icon to each CollapsibleCard header
- Click → Expand + show inline edit fields
- Same experience as job editor tabs, but vertical scroll

### Phase 2: Improve Labels

**Profile Screen:**
```dart
AppBar(
  title: Text('Profile Templates'),
  subtitle: Text('Base CV data for all applications'),
)

// Language toggle shows:
"Editing: ${language.label} Template"
```

**Job Editor:**
```dart
AppBar(
  title: Text('Edit CV for ${application.company}'),
  subtitle: Text('${application.position} (${application.language.flag} ${application.language.code.toUpperCase()})'),
)
```

### Phase 3: Visual Consistency

**Shared Components:**
- Use same `_buildProfessionalSummarySection()` code
- Use same dialog styles (ExperienceEditDialog, EducationEditDialog)
- Same card designs
- Same spacing/padding

**Different Styling:**
- Profile tab: Neutral/blue theme → "This is your template"
- Application tab: Keep current → "These are real applications"

---

## Workflows Comparison

### Profile Template Workflow (NEW):
```
1. Import YAML (or start fresh)
2. Click "Edit Template" button
3. Same 8-tab editor opens
4. Make changes (fix typos, update content)
5. Changes auto-save to master profile
6. Switch language toggle → Edit other template
7. Export YAML if needed
```

### Job Application Workflow (UNCHANGED):
```
1. Create Application
2. Template cloned automatically  
3. Click "Edit" → Same 8-tab editor
4. Customize for this job
5. Generate PDFs
6. Track status
```

**Same editor, same UX, different data source!**

---

## What Does NOT Change

✅ Applications tab stays exactly as-is (user likes it)
✅ 8-tab editor stays exactly as-is  
✅ PDF generation stays as-is
✅ Status tracking stays as-is
✅ All current features preserved

---

## What DOES Change

### Profile Tab Only:
1. ✅ Add "Edit Template" button → Opens familiar 8-tab editor
2. ✅ Better labels: "Profile Templates" not "Profile"
3. ✅ Clear indication: "Editing English Template"
4. ✅ Can now edit imported data without re-importing YAML

### Benefits:
- **For users:** Can fix typos, update content easily
- **For developers:** Reuse existing editor code
- **For maintenance:** One editor to maintain, not two
- **For UX:** Consistent editing experience

---

## Implementation Effort

### Minimal Approach (Recommended):
**~4 hours of work**

1. Add `updateFromCvData()` method to UserDataProvider (1 hour)
2. Add "Edit Template" button + navigation (30 min)
3. Update labels in both tabs (30 min)  
4. Handle MasterProfile ↔ JobCvData conversion (1 hour)
5. Testing (1 hour)

### Comprehensive Approach:
**~2-3 days**

- Create shared component library
- Rebuild both tabs with shared components
- Complete visual overhaul

**Recommend: Start with Minimal, iterate later if needed**

---

## User Experience Before/After

### Before (Current):
**Profile Tab:**
"I imported my CV but there's a typo... I can't edit it. I have to edit the YAML file and re-import everything. Frustrating!"

**Apply

 Tab:**
"This is nice! I can edit everything easily!"

### After (Proposed):
**Profile Tab:**
"I imported my CV and there's a typo. Let me click 'Edit Template' and fix it. Done! Same editor I use for jobs - familiar and easy!"

**Applications Tab:**
"Still nice! Same workflow I'm used to!"

---

## Decision Point

**Do you want:**

**Option A (Minimal):** Add "Edit Template" button that opens same 8-tab editor?
- Reuses existing code
- Fast to implement
- Familiar UX

**Option B (Comprehensive):** Rebuild both tabs with shared component library?
- More work
- Prettier UI
- Better long-term maintainability

**Recommendation: Start with Option A, iterate to Option B later if desired.**
