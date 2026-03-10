# PDF Editor — Remaining Improvements

Tracked improvements identified after the v1.1.7 cleanup session.
None of these are bugs; they are quality/robustness improvements to tackle in a future pass.

---

## High Priority

### 1. `setLayoutPreset()` missing guard and persistence
**File:** `lib/widgets/pdf_editor/pdf_editor_controller.dart`

`setLayoutPreset()` neither sets `_hasExplicitCustomization = true` nor calls
`_scheduleSave()`.

- If the async global-customization load resolves *after* the user picks a preset,
  the preset choice is silently overwritten.
- Layout preset changes are also never written to disk — reopening the dialog
  always shows the previous persisted customization, not the last-applied preset.

**Fix:** Add `_hasExplicitCustomization = true` and `_scheduleSave()` to
`setLayoutPreset()`, mirroring `updateCustomization()`.

---

## Medium Priority

### 2. `updateStyle` vs `setStyle` duplicate API
**File:** `lib/widgets/pdf_editor/pdf_editor_controller.dart`

Two public methods both update the template style but with subtly different logic:

- `updateStyle()` — checks full equality, calls `_scheduleRegeneration()` (debounced).
- `setStyle()` — compares only `type`/`accentColor`/`fontFamily`, calls `regenerate()`
  (immediate, bypasses debounce).

This makes call-sites confusing and the two methods can produce different behaviour
for the same input. Consolidate into a single `updateStyle()` that debounces, and
have `regenerate()` remain as the explicit "force now" escape hatch for the rare
cases that need it.

### 3. `currentLayoutPresetName` — hardcoded English strings
**File:** `lib/widgets/pdf_editor/pdf_editor_controller.dart` (lines 112–126)

Returns `'Modern'`, `'Compact'`, `'Traditional'`, `'Two Column'` as raw English
strings. This value is shown in the sidebar sub-header. It should return a locale
key (or accept a `BuildContext`) and translate via `context.tr()`.

### 4. `PdfViewMode` — hardcoded English labels
**File:** `lib/widgets/pdf_editor/pdf_editor_controller.dart` (lines 500–517)

The `label` field on each `PdfViewMode` variant (`'Single Page'`, `'Side by Side'`,
`'Fit Width'`) is a hardcoded English string baked into the enum. If the toolbar
renders these labels, they bypass the localization system.

**Options:**
- Replace `label` with a locale key string and resolve in the widget, or
- Remove the `label` field and look up via `context.tr()` in the toolbar widget.

---

## Low Priority / Future

### 5. Cover letter `_buildLetterBody` — bullet rendering unification
**Files:** all 4 cover letter templates

Each template has its own `_buildLetterBody` implementation because bullet/paragraph
rendering differs (`IconComponent.bullet` in professional, custom inline renderers in
electric/modern_two, plain paragraphs in classic). The shared logic (paragraph
splitting, line-height, font scaling) is now handled by `CoverLetterHelpers`, but
the widget construction itself is template-specific.

No immediate action needed — the current split is intentional and documented.
Worth revisiting if a fifth template is added to avoid more divergence.

### 6. Cover letter — `twoColumn` preset sidebar case
**File:** `lib/widgets/pdf_editor/pdf_editor_sidebar.dart`

The `Show Greeting` / `Show Closing` toggles were added for the `modern`, `compact`,
and `traditional` preset cases in the sidebar. Verify that `twoColumn` is never
used as a layout preset for cover letter documents. If it can be reached for cover
letters, the toggles must be added there too.

---

## Done (v1.1.8)

- [x] Added `showGreeting` / `showClosing` fields to `TemplateCustomization`
- [x] Added sidebar toggles for Show Greeting / Show Closing (modern, compact, traditional)
- [x] Conditional greeting/closing rendering in all 4 cover letter templates
- [x] Fixed `as double?` → `(as num?)?.toDouble()` for numeric fields in `fromJson`
- [x] Fixed `_hasExplicitCustomization` race condition in `PdfEditorController`
- [x] Fixed missing `subject` field in `_saveFieldChanges()`
- [x] Extracted `CoverLetterHelpers` (`formatDate`, `splitBodyParagraphs`)
- [x] Removed dead `_formatDate` methods from all 4 cover letter templates
- [x] Added EN + DE localization keys for new toggles
