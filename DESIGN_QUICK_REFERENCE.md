# 🚀 SAAF-SURKSHA Design System - Quick Reference

## 🎨 Colors - At a Glance

```dart
// Primary Actions
AppColors.primaryGreen    // #1FAA7F - Main CTA buttons, success
AppColors.primaryBlue     // #0066CC - Secondary actions, info

// Accents & Alerts
AppColors.accentOrange    // #FF8C42 - Warnings, pending items
AppColors.accentRed       // #E63946 - Errors, critical issues
AppColors.accentYellow    // #FFB703 - Attention needed
AppColors.successGreen    // #52B788 - Completed, resolved

// Neutrals
AppColors.neutralLight    // #F8F9FA - Backgrounds
AppColors.neutralDark     // #1A202C - Primary text
AppColors.gray            // #718096 - Secondary text
```

## 📝 Typography - Quick Styles

```dart
AppTextStyles.displayXL    // 48px - App title
AppTextStyles.displayL     // 36px - Screen headers
AppTextStyles.headingXL    // 28px - Section titles
AppTextStyles.headingL     // 24px - Subsections
AppTextStyles.headingM     // 20px - Card headers
AppTextStyles.bodyL        // 16px - Regular text
AppTextStyles.bodyM        // 14px - Secondary text
AppTextStyles.bodyS        // 12px - Hints, labels
AppTextStyles.caption      // 10px - Metadata
AppTextStyles.button       // 16px - Buttons
```

## 📏 Spacing - Quick Values

```dart
AppSpacing.micro   // 4px
AppSpacing.xs      // 8px
AppSpacing.sm      // 12px
AppSpacing.md      // 16px  ← Most common
AppSpacing.lg      // 20px
AppSpacing.xl      // 24px
AppSpacing.xxl     // 32px
AppSpacing.xxxl    // 48px
```

## 🔘 Border Radius

```dart
AppRadius.small      // 4px  - Small elements
AppRadius.medium     // 8px  - Buttons, inputs ← Default
AppRadius.large      // 12px - Cards
AppRadius.xLarge     // 16px - Large containers
AppRadius.xxLarge    // 24px - Extra rounded
AppRadius.circular   // 9999px - Pills/circles
```

## 🧩 Most-Used Components

### Buttons

```dart
// Primary CTA
PrimaryButton(
  text: 'Submit',
  onPressed: () {},
  icon: Icons.check,
  isLoading: false,
)

// Secondary/Cancel
SecondaryButton(
  text: 'Cancel',
  onPressed: () {},
)

// Large Home Actions
ActionButton(
  text: 'Report Issue',
  icon: Icons.add_a_photo,
  color: AppColors.primaryGreen,
  onPressed: () {},
)
```

### Cards

```dart
// Stats Display
StatsCard(
  icon: Icons.check_circle,
  value: '245',
  label: 'Resolved',
  color: AppColors.successGreen,
)

// Issue/Item Card
IssueCard(
  title: 'Pothole Detected',
  location: 'Main Street',
  status: 'pending',
  priority: 'high',
  timestamp: '2h ago',
  icon: Icons.warning,
  onTap: () {},
)
```

### Badges

```dart
StatusBadge(
  status: 'Pending',
  color: AppColors.statusPending,
)

PriorityBadge(
  priority: 'High',
  color: AppColors.priorityHigh,
)
```

### Filters

```dart
FilterChipCustom(
  label: 'All',
  isSelected: true,
  onTap: () {},
)
```

### Empty States

```dart
EmptyState(
  icon: Icons.inbox,
  title: 'No Items',
  description: 'Get started by adding one',
  actionText: 'Add Item',
  onAction: () {},
)
```

### Loading

```dart
LoadingIndicator(
  message: 'Loading...',
)
```

### Snackbar

```dart
// Success
AppSnackBar.show(context, message: 'Saved!');

// Error
AppSnackBar.show(
  context, 
  message: 'Failed', 
  isError: true,
);
```

## 🎬 Animations

```dart
// Button press effect
AnimatedButtonWrapper(
  onTap: () {},
  child: Widget(),
)

// Fade in
FadeInAnimation(child: Widget())

// Slide up
SlideUpAnimation(child: Widget())

// List stagger
StaggeredListAnimation(
  index: index,
  child: Widget(),
)

// Pulse (live indicators)
PulseAnimation(child: Widget())

// Shimmer loading
ShimmerLoading(width: 200, height: 100)

// Success animation
SuccessCheckmark(size: 100)

// Error shake
ShakeAnimation(shake: hasError, child: Widget())

// Page transition
Navigator.push(
  context,
  AppPageTransition(page: NextScreen()),
)
```

## 📱 Common Patterns

### Screen Header

```dart
Column(
  children: [
    Text(
      'Screen Title',
      style: AppTextStyles.displayL.copyWith(
        color: AppColors.primaryGreen,
      ),
    ),
    SizedBox(height: AppSpacing.micro),
    Text(
      'Subtitle or description',
      style: AppTextStyles.bodyM,
    ),
  ],
)
```

### Stats Row (3 columns)

```dart
Row(
  children: [
    Expanded(child: StatsCard(...)),
    SizedBox(width: AppSpacing.xs),
    Expanded(child: StatsCard(...)),
    SizedBox(width: AppSpacing.xs),
    Expanded(child: StatsCard(...)),
  ],
)
```

### Filter Bar

```dart
Container(
  height: 50,
  child: ListView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
    ),
    children: [
      FilterChipCustom(...),
      SizedBox(width: AppSpacing.xs),
      FilterChipCustom(...),
      SizedBox(width: AppSpacing.xs),
      FilterChipCustom(...),
    ],
  ),
)
```

### Animated List

```dart
ListView.builder(
  padding: EdgeInsets.all(AppSpacing.md),
  itemBuilder: (context, index) {
    return StaggeredListAnimation(
      index: index,
      child: IssueCard(...),
    );
  },
)
```

### Form Field

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Placeholder text',
    prefixIcon: Icon(Icons.search),
  ),
)
```

### Bottom Buttons Row

```dart
Row(
  children: [
    Expanded(
      child: SecondaryButton(
        text: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
    ),
    SizedBox(width: AppSpacing.md),
    Expanded(
      child: PrimaryButton(
        text: 'Submit',
        onPressed: () {},
      ),
    ),
  ],
)
```

### Safe Area Padding

```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: YourContent(),
    ),
  ),
)
```

### Card with Tap

```dart
Card(
  child: InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(AppRadius.large),
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Content(),
    ),
  ),
)
```

## 🎯 Status & Priority Colors

```dart
// Status Colors
AppColors.statusPending     // Orange
AppColors.statusAssigned    // Blue
AppColors.statusResolved    // Green
AppColors.statusClosed      // Gray

// Priority Colors
AppColors.priorityHigh      // Red
AppColors.priorityMedium    // Yellow
AppColors.priorityLow       // Green
```

## 🔍 Icon Sizes

```dart
AppDimensions.iconXS       // 16px
AppDimensions.iconS        // 20px
AppDimensions.iconM        // 24px - Default
AppDimensions.iconL        // 28px
AppDimensions.iconXL       // 32px
AppDimensions.iconXXL      // 40px
AppDimensions.iconXXXL     // 64px
```

## 📐 Button Heights

```dart
AppDimensions.buttonHeightSmall    // 40px
AppDimensions.buttonHeightMedium   // 48px - Default
AppDimensions.buttonHeightLarge    // 56px
AppDimensions.buttonHeightXL       // 70px - Home actions
```

## ⚡ Animation Durations

```dart
AppAnimations.fast      // 150ms
AppAnimations.normal    // 200ms - Default
AppAnimations.medium    // 300ms - Page transitions
AppAnimations.slow      // 500ms
AppAnimations.loading   // 1000ms
```

## 💡 Pro Tips

1. **Always use design system colors** - Never hardcode hex values
2. **Stick to spacing scale** - Use AppSpacing constants
3. **Consistent border radius** - Use AppRadius values
4. **Animate list items** - Use StaggeredListAnimation
5. **Show feedback** - Use AppSnackBar for user actions
6. **Loading states** - Always show LoadingIndicator
7. **Empty states** - Use EmptyState component
8. **Touch targets** - Minimum 48x48px (AppDimensions.minTouchTarget)
9. **Page transitions** - Use AppPageTransition for navigation
10. **Status badges** - Always show status with colors

## 📦 Imports

```dart
// Essential imports for every screen
import 'package:saaf_surksha/utils/constants.dart';
import 'package:saaf_surksha/utils/ui_components.dart';
import 'package:saaf_surksha/utils/animation_utils.dart';
```

## 🚀 Common Layouts

### Home Screen Layout

```dart
Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Header with title & tagline
          // Stats row (3 cards)
          // Action buttons (4 large)
          Spacer(),
          // Footer text
        ],
      ),
    ),
  ),
)
```

### List Screen Layout

```dart
Scaffold(
  appBar: CustomAppBar(title: 'Title'),
  body: Column(
    children: [
      // Filter bar
      Expanded(
        child: ListView.builder(...),
      ),
    ],
  ),
  floatingActionButton: FloatingActionButton(...),
)
```

### Form Screen Layout

```dart
Scaffold(
  appBar: CustomAppBar(title: 'Form'),
  body: SingleChildScrollView(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Column(
      children: [
        // Form fields
        SizedBox(height: AppSpacing.xl),
        // Bottom buttons
      ],
    ),
  ),
)
```

---

**Quick Reference Version:** 1.0  
**Print this for easy access while coding!**
