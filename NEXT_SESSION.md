# Next Session: Critical UX Improvements

**Date:** 2026-01-04+  
**Realistic Status:** Foundation complete, UX needs significant work  
**Priority:** Fix user-facing features to match expectations

---

## 🎯 **Session Goal: Make It Actually Usable**

The architecture is solid, but users can't effectively use the app yet. This session focuses on the most critical UX improvements.

---

## 🚨 **PRIORITY 1: PDF Customization Panel (4-5 hours)**

### **Why This Is Critical:**
The old PDF editor had full customization. Users expect:
- Template selection
- Color customization
- Font selection
- Layout options
- Photo visibility control

**Current State:** PDF preview shows but can't customize anything.

### **Implementation Steps:**

#### 1. Add Customization Sidebar (1-2h)
**File:** `lib/screens/tailoring/tailoring_workspace.dart`

Add a collapsible right sidebar with:
```dart
// New widget: _buildCustomizationPanel()
- Template Selector dropdown
  - Electric (Modern 2)
  - Professional (Modern)
  - Traditional (Classic)
  
- Colors Section
  - Accent Color picker
  - Primary Color picker (optional)
  
- Typography Section
  - Font Family dropdown
    - Roboto
    - Open Sans
    - Lato
    
- Layout Section
  - Two-column toggle
  - Dark mode toggle
  - Show photo toggle
```

#### 2. Connect to State (30min)
```dart
// Update _pdfSettings when user changes options
onTemplateChanged: (TemplateType type) {
  setState(() {
    _pdfSettings = _pdfSettings!.copyWith(templateType: type);
  });
  _savePdfSettings();
}

// Trigger PDF regeneration on changes
// PdfPreview will auto-rebuild
```

#### 3. Style the UI (1h)
- Use ExpansionTile for sections
- Color picker with recent colors
- Nice dropdown styling
- Toggle switches for bools
- Real-time preview updates

#### 4. Test All Options (30min)
- Verify each template renders correctly
- Test color changes
- Test font changes
- Test layout toggles
- Ensure persistence

---

## 🚨 **PRIORITY 2: Documents Tab Overhaul (3-4 hours)**

### **Why This Is Critical:**
Users can't manage their templates effectively. Missing basic operations.

### **Current Issues:**
- Can't edit template names
- No language indicator
- Can't tell CV from Cover Letter
- Confusing workflow

### **Implementation Steps:**

#### 1. Redesign Template Cards (1-2h)
**File:** `lib/screens/templates/templates_screen.dart`

New card structure:
```dart
TemplateCard(
  header: Row(
    children: [
      // Language flag badge
      Chip(avatar: flag, label: language),
      // Type indicator
      Icon(isCv ? Icons.description : Icons.email),
      // Editable name with pencil icon
      InlineEditableText(name),
    ],
  ),
  body: Column(
    children: [
      // Preview thumbnail (optional)
      // Last modified date
      // Usage count ("Used in 3 applications")
    ],
  ),
  actions: [
    // Edit button
    // Duplicate button
    // Delete button (with confirmation)
  ],
)
```

#### 2. Add Inline Name Editing (30min)
```dart
class InlineEditableText extends StatefulWidget {
  // Click to edit
  // Enter or blur to save
  // Escape to cancel
}
```

#### 3. Add Template Creation Workflow (1h)
```dart
// "Create Template" FAB
showDialog(
  // Select language (EN/DE)
  // Select type (CV/Cover Letter)
  // Enter name
  // Select base template style
  // Creates with default data
);
```

#### 4. Add Actions (30min)
- Duplicate template (with new name)
- Delete with confirmation
- Show in file (open folder)

---

## 🚨 **PRIORITY 3: Tracking Tab Enhancement (4-5 hours)**

### **Why This Is Critical:**
Main interface for managing applications. Currently too basic.

### **Implementation Steps:**

#### 1. Add Toolbar with Filters (1h)
**File:** `lib/screens/applications/applications_screen.dart`

```dart
// Above the cards
Row(
  children: [
    // Search bar
    Expanded(
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search company or position...',
        ),
        onChanged: (query) => _filterApplications(query),
      ),
    ),
    
    // Sort dropdown
    DropdownButton<SortOption>(
      items: [
        'Date (Newest)',
        'Date (Oldest)',
        'Company A-Z',
        'Status',
      ],
    ),
    
    // Filter chips
    FilterChip(
      label: Text('Draft'),
      selected: _showDraft,
      onSelected: (val) => setState(() => _showDraft = val),
    ),
    // ... more filter chips
  ],
)
```

#### 2. Enhance Application Cards (2h)
```dart
// Add to _ApplicationCard
Row(
  children: [
    // Clickable email
    if (application.contactEmail != null)
      IconButton(
        icon: Icon(Icons.email),
        onPressed: () => launchUrl('mailto:${application.contactEmail}'),
        tooltip: application.contactEmail,
      ),
    
    // Clickable website
    if (application.companyWebsite != null)
      IconButton(
        icon: Icon(Icons.language),
        onPressed: () => launchUrl(application.companyWebsite!),
        tooltip: 'Visit website',
      ),
    
    // Interview date badge
    if (application.interviewDate != null)
      Chip(
        avatar: Icon(Icons.event),
        label: Text('Interview: ${formatDate(application.interviewDate!)}'),
        backgroundColor: Colors.blue.shade100,
      ),
  ],
),

// Quick status change
DropdownButton<ApplicationStatus>(
  value: application.status,
  onChanged: (status) => _updateStatus(application, status),
  items: ApplicationStatus.values.map((s) =>
    DropdownMenuItem(value: s, child: Text(s.label)),
  ).toList(),
),
```

#### 3. Add Statistics Summary (30min)
```dart
// At top of screen
Row(
  children: [
    _StatCard(
      title: 'Total',
      count: applications.length,
      icon: Icons.work,
    ),
    _StatCard(
      title: 'Active',
      count: activeCount,
      icon: Icons.pending_actions,
      color: Colors.blue,
    ),
    _StatCard(
      title: 'Interviews',
      count: interviewCount,
      icon: Icons.event,
      color: Colors.orange,
    ),
    _StatCard(
      title: 'Offers',
      count: offerCount,
      icon: Icons.check_circle,
      color: Colors.green,
    ),
  ],
)
```

#### 4. Implement Search & Filter (1h)
```dart
List<JobApplication> _getFilteredApplications() {
  var filtered = applications;
  
  // Apply search
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((app) =>
      app.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      app.position.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }
  
  // Apply status filters
  if (_statusFilters.isNotEmpty) {
    filtered = filtered.where((app) =>
      _statusFilters.contains(app.status)
    ).toList();
  }
  
  // Apply sort
  filtered.sort((a, b) {
    switch (_sortOption) {
      case SortOption.dateNewest:
        return b.createdAt.compareTo(a.createdAt);
      case SortOption.dateOldest:
        return a.createdAt.compareTo(b.createdAt);
      case SortOption.companyAZ:
        return a.company.compareTo(b.company);
      case SortOption.status:
        return a.status.index.compareTo(b.status.index);
    }
  });
  
  return filtered;
}
```

---

## 🎯 **PRIORITY 4: Profile Import (2-3 hours)**

### **Implementation Steps:**

#### 1. Add Import Button to Profile Screen (30min)
```dart
// In ProfileScreen header actions
IconButton(
  icon: Icon(Icons.upload_file),
  onPressed: () => _showImportDialog(context),
  tooltip: 'Import YAML',
)
```

#### 2. Create Import Dialog (1h)
**File:** `lib/dialogs/profile_import_dialog.dart`

```dart
class ProfileImportDialog extends StatefulWidget {
  // 1. Select language (EN/DE) - big choice chips
  // 2. Select file or paste YAML
  // 3. Validate YAML
  // 4. Preview what will be imported
  // 5. Confirm and import
  // 6. Show success/error
}
```

#### 3. Implement YAML Parsing (1h)
```dart
// Validate YAML structure
// Map to MasterProfile
// Handle missing fields gracefully
// Show clear error messages
```

#### 4. Update UI After Import (30min)
```dart
// Reload profile in UserDataProvider
// Refresh ProfileScreen
// Show success toast
// Scroll to imported section
```

---

## 📝 **Quick Reference: File Locations**

### **PDF Customization:**
- `lib/screens/tailoring/tailoring_workspace.dart` - Add sidebar
- `lib/models/template_customization.dart` - Already exists
- `lib/models/template_style.dart` - Already exists

### **Documents Tab:**
- `lib/screens/templates/templates_screen.dart` - Main file
- May need new widget files for template cards

### **Tracking Tab:**
- `lib/screens/applications/applications_screen.dart` - Main file
- `lib/widgets/status_badge.dart` - Already exists

### **Profile Import:**
- `lib/screens/profile/profile_screen.dart` - Add button
- `lib/dialogs/profile_import_dialog.dart` - Create new
- `lib/services/yaml_parser.dart` - May exist, check

---

## 🎯 **Session Success Criteria**

By end of session, users should be able to:
- ✅ Fully customize PDF appearance (colors, fonts, layout)
- ✅ Easily manage templates (rename, duplicate, delete)
- ✅ Effectively track applications (search, filter, sort)
- ✅ Import profile data from YAML with language selection

---

## ⚡ **Quick Wins to Start With**

If you want quick progress, start with these:

**30-Minute Wins:**
1. Add language badge to template cards
2. Add inline name editing to templates
3. Add search bar to applications
4. Add import button to profile

**1-Hour Wins:**
1. Create PDF customization sidebar structure
2. Add template creation dialog
3. Add application statistics cards
4. Create import dialog UI

---

## 💡 **Tips for Implementation**

1. **Reuse Existing Widgets**
   - Color picker: Use `flutter_colorpicker` package
   - Dropdowns: Material `DropdownButton`
   - Chips: Material `FilterChip`

2. **State Management**
   - Keep using `setState` for local state
   - Use provider only for shared data
   - Debounce search input

3. **Testing**
   - Test each feature individually
   - Use hot reload frequently
   - Check on different screen sizes

---

**Start Here:** PDF Customization Panel (biggest user impact!)  
**Total Estimated Time:** 13-17 hours for all 4 priorities  
**Realistic Session Goal:** Complete 1-2 priorities (4-10 hours)
