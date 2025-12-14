# 🎨 SAAF-SURKSHA Design System - Visual Cheat Sheet

## Colors

```
PRIMARY COLORS
🟢 primaryGreen   #1FAA7F   AppColors.primaryGreen
🔵 primaryBlue    #0066CC   AppColors.primaryBlue

ACCENT COLORS
🟠 accentOrange   #FF8C42   AppColors.accentOrange
🔴 accentRed      #E63946   AppColors.accentRed
🟡 accentYellow   #FFB703   AppColors.accentYellow
🟢 successGreen   #52B788   AppColors.successGreen

NEUTRALS
⬜ neutralLight   #F8F9FA   AppColors.neutralLight
⬛ neutralDark    #1A202C   AppColors.neutralDark
⬜ gray           #718096   AppColors.gray
```

## Typography

```
📱 DISPLAY
displayXL     48px  bold    App Title
displayL      36px  bold    Screen Headers

📝 HEADINGS
headingXL     28px  bold    Section Titles
headingL      24px  bold    Subsections
headingM      20px  semi    Card Headers

💬 BODY
bodyL         16px  regular  Main Text
bodyM         14px  regular  Secondary Text
bodyS         12px  regular  Hints

🏷️ LABELS
caption       10px  regular  Metadata
button        16px  bold     Buttons
```

## Spacing (8px Grid)

```
micro   4px    ▪
xs      8px    ▪▪
sm      12px   ▪▪▪
md      16px   ▪▪▪▪        ← MOST COMMON
lg      20px   ▪▪▪▪▪
xl      24px   ▪▪▪▪▪▪
xxl     32px   ▪▪▪▪▪▪▪▪
xxxl    48px   ▪▪▪▪▪▪▪▪▪▪▪▪
```

## Border Radius

```
small     4px    ╭─╮  Small Elements
medium    8px    ╭──╮ Buttons, Cards (DEFAULT)
large     12px   ╭───╮ Large Cards
xLarge    16px   ╭────╮ Containers
xxLarge   24px   ╭─────╮ Extra Rounded
circular  9999px ⬭     Pills, Circles
```

## Components Quick Access

```dart
// BUTTONS
PrimaryButton(text: 'Text', onPressed: () {})
SecondaryButton(text: 'Text', onPressed: () {})
ActionButton(text: 'Text', icon: Icons.add, onPressed: () {})

// CARDS
StatsCard(icon: Icons.check, value: '100', label: 'Label')
IssueCard(title: 'Title', location: 'Loc', status: 'pending', 
          priority: 'high', timestamp: '2h', icon: Icons.warning)

// BADGES
StatusBadge(status: 'Pending', color: AppColors.statusPending)
PriorityBadge(priority: 'High', color: AppColors.priorityHigh)

// FILTERS
FilterChipCustom(label: 'All', isSelected: true, onTap: () {})

// STATES
EmptyState(icon: Icons.inbox, title: 'No Data', 
          description: 'Description', actionText: 'Action', onAction: () {})
LoadingIndicator(message: 'Loading...')

// FEEDBACK
AppSnackBar.show(context, message: 'Success!')
AppSnackBar.show(context, message: 'Error', isError: true)

// ANIMATIONS
FadeInAnimation(child: Widget())
SlideUpAnimation(child: Widget())
StaggeredListAnimation(index: i, child: Widget())
PulseAnimation(child: Widget())
```

## Common Patterns

```dart
// STATS ROW (3 columns)
Row(
  children: [
    Expanded(child: StatsCard(...)),
    SizedBox(width: AppSpacing.xs),
    Expanded(child: StatsCard(...)),
    SizedBox(width: AppSpacing.xs),
    Expanded(child: StatsCard(...)),
  ],
)

// FILTER BAR
Container(
  height: 50,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      FilterChipCustom(...),
      SizedBox(width: AppSpacing.xs),
      FilterChipCustom(...),
    ],
  ),
)

// ANIMATED LIST
ListView.builder(
  itemBuilder: (context, index) {
    return StaggeredListAnimation(
      index: index,
      child: IssueCard(...),
    );
  },
)

// BOTTOM BUTTONS
Row(
  children: [
    Expanded(child: SecondaryButton(...)),
    SizedBox(width: AppSpacing.md),
    Expanded(child: PrimaryButton(...)),
  ],
)

// SAFE AREA CONTAINER
SafeArea(
  child: Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Content(),
  ),
)
```

## Status & Priority

```dart
// STATUS COLORS
statusPending    🟠 Orange
statusAssigned   🔵 Blue
statusResolved   🟢 Green
statusClosed     ⬜ Gray

// PRIORITY COLORS
priorityHigh     🔴 Red
priorityMedium   🟡 Yellow
priorityLow      🟢 Green
```

## Icons Sizes

```
iconXS     16px  ▪
iconS      20px  ▫
iconM      24px  ▫  ← DEFAULT
iconL      28px  ◻
iconXL     32px  ◻
iconXXL    40px  ◼
iconXXXL   64px  ◼
```

## Button Heights

```
buttonHeightSmall    40px  ─
buttonHeightMedium   48px  ═  ← DEFAULT
buttonHeightLarge    56px  ━
buttonHeightXL       70px  ┃  Home Actions
```

## Animation Speeds

```
fast      150ms  ⚡
normal    200ms  →  ← DEFAULT
medium    300ms  ⟹  Page Transitions
slow      500ms  ⟹⟹
loading   1000ms ⟲
```

## Import Statement

```dart
import 'package:saaf_surksha/utils/constants.dart';
import 'package:saaf_surksha/utils/ui_components.dart';
import 'package:saaf_surksha/utils/animation_utils.dart';
```

## Rules of Thumb

✅ Always use design system constants
✅ Never hardcode colors or sizes
✅ Minimum 48px touch targets
✅ Use animations for state changes
✅ Show loading and empty states
✅ Provide user feedback (snackbars)
✅ Follow 8px grid for spacing
✅ Use semantic color names

## Screen Template

```dart
Scaffold(
  backgroundColor: AppColors.background,
  appBar: CustomAppBar(title: 'Title'),
  body: SafeArea(
    child: Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Title', style: AppTextStyles.headingXL),
        ),
        
        // Content
        Expanded(
          child: ListView(...),
        ),
      ],
    ),
  ),
  floatingActionButton: FloatingActionButton(...),
)
```

---

**Print this for quick reference while coding!**

Version 1.0 | December 2025 | SAAF-SURKSHA Design System
