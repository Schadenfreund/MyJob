## Critical Issue Found

The JobCvEditorWidget is designed to edit CV DATA (experiences, skills, etc.), not the Job Application METADATA (status, dates, etc.).

**Two separate concerns:**
1. **CV Content** - Personal info, experience, skills (JobCvEditorWidget handles this) ✅
2. **Application Metadata** - Status, dates, notes (Needs ApplicationEditorDialog) ❌

**Solution:**
The "Details" tab in JobCvEditorWidget should be **read-only and informational**, showing:
- What job this is for
- Current status
- Key dates
- Link to edit these details via the main ApplicationEditorDialog

Attempting to edit application metadata here creates architectural issues because:
- JobCvEditorWidget doesn't have access to save application changes
- Mixing concerns makes the code confusing
- ApplicationsProvider handles application updates, not this widget

**Recommendation:**
Make the Details tab a beautiful, read-only summary with a button to "Edit Application Details" that closes this screen and opens the ApplicationEditorDialog.
