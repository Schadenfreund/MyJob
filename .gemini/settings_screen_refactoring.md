# Settings Screen Refactoring

## Overview
Refactored the Settings screen to match the card design of Applications and Profile tabs, use centralized components, and remove the redundant theme selector.

## Changes Made

### 1. **Component Unification**
**Before:**
- Used `CollapsibleCard` widget (inconsistent with other tabs)
- Custom styling and layouts
- Different look and feel

**After:**
- Uses `ProfileSectionCard` (same as Profile tab)
- Consistent styling across all tabs
- Unified user experience

### 2. **Removed Redundant Theme Selector**
**Reason:** Theme toggle is already available in the app header/titlebar
**Removed:**
- Theme mode selector (Light/Dark/System segmented button)
- Theme icon and label helpers
- Related UI components

**Kept:**
- Accent color selector (unique to settings)

### 3. **Updated Sections**

#### Accent Color Section
- **Icon:** `Icons.palette_outlined`
- **Initially Expanded:** `true`
- **Features:**
  - 5 color options with labels (Blue, Green, Cyan, Orange, Red)
  - Improved color button design with labels and selection indicators
  - Descriptive text explaining the accent color purpose

**Color Button Improvements:**
- Added text labels for each color
- Better visual feedback for selected state
- Larger touch targets (better UX)
- Consistent with Material Design 3 principles

#### About Section
- **Icon:** `Icons.info_outline`
- **Initially Expanded:** `false`
- **Features:**
  - App name
  - Version number
  - Description
  - Collapsed preview shows "AppName vX.X.X"

#### Data Management Section
- **Icon:** `Icons.storage_outlined`
- **Initially Expanded:** `false`
- **Features:**
  - Reset settings button
  - Warning-styled button (red outline)
  - Confirmation dialog before reset
  - Collapsed preview text

### 4. **Header Consistency**
**Before:**
```dart
UIUtils.buildSectionHeader(
  context,
  title: 'Settings',
  subtitle: 'Customize your experience',
  icon: Icons.settings,
)
```

**After:**
```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: headlineSmall),
          Text('Customize your experience', style: bodyMedium),
        ],
      ),
    ),
  ],
)
```

Matches the header style in Applications and Profile tabs.

### 5. **Imports Cleanup**
**Removed:**
- `../../widgets/collapsible_card.dart`
- `../../utils/ui_utils.dart` (not needed)

**Added:**
- `../../constants/ui_constants.dart`
- `../../widgets/profile_section_card.dart`

## Visual Improvements

### Color Button Design
**Before:**
- Small circular buttons (36x36)
- Only showed color
- Hard to identify which color is which
- Small touch target

**After:**
- Larger button with label (e.g., "Blue", "Green")
- Color circle + text label
- Selected state with border highlight
- Better touch target (full button area)
- More accessible and user-friendly

### Card Design
**Before:**
- Custom card styling
- Different appearance from other tabs
- Status indicators (configured/needsAttention)

**After:**
- Consistent ProfileSectionCard styling
- Same look as Profile and Applications tabs
- Clean, minimal design
- Smooth AnimatedCrossFade animations

## User Experience Improvements

1. **Consistency:** All tabs now use the same card design
2. **Clarity:** Color buttons now have labels (easier to identify)
3. **Accessibility:** Larger touch targets, better labels
4. **Simplicity:** Removed redundant theme selector
5. **Animation:** Smooth expand/collapse transitions (200ms)

## File Structure

```
lib/screens/settings/
└── settings_screen.dart  (refactored)
    ├── Uses ProfileSectionCard
    ├── 3 main sections
    └── Improved color selector
```

## Testing Checklist

- [ ] Accent color selection works correctly
- [ ] All 5 colors can be selected
- [ ] Color changes reflect throughout the app
- [ ] About section shows correct app info
- [ ] Data Management reset button works
- [ ] Reset confirmation dialog appears
- [ ] Reset actually resets settings
- [ ] All sections expand/collapse smoothly
- [ ] Cards match Applications/Profile tab design
- [ ] No theme selector visible in settings
- [ ] Theme can still be changed from header

## Benefits

1. **Unified Design Language:** All tabs now share the same visual language
2. **Maintainability:** Using centralized components (ProfileSectionCard)
3. **User Experience:** Consistent behavior across the app
4. **Code Quality:** Removed duplicate styling code
5. **Reduced Confusion:** No duplicate theme controls

## Before/After Comparison

### Before
```dart
CollapsibleCard(
  cardDecoration: UIUtils.getCardDecoration(context),
  title: 'Appearance',
  subtitle: 'Theme and colors',
  status: CollapsibleCardStatus.configured,
  // Theme selector + Accent color selector
)
```

### After
```dart
ProfileSectionCard(
  title: 'Accent Color',
  icon: Icons.palette_outlined,
  count: 1,
  // Only accent color selector (theme in header)
)
```

## Migration Notes

- Old `CollapsibleCard` widget is still available for backward compatibility
- New code should use `ProfileSectionCard` for consistency
- Theme selection should be handled by the header component
- Settings screen should focus on app-specific settings only
