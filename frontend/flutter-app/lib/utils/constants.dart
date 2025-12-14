import 'package:flutter/material.dart';

// ============================================================================
// SAAF-SURKSHA DESIGN SYSTEM
// Marketing-Ready Professional UI/UX Constants
// ============================================================================

// API Configuration
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String authBaseUrl = '$baseUrl/auth';
  static const String issuesBaseUrl = '$baseUrl/issues';
  static const String tasksBaseUrl = '$baseUrl/tasks';
  static const String analyticsBaseUrl = '$baseUrl/analytics';
  static const String usersBaseUrl = '$baseUrl/users';
  
  static const Duration timeout = Duration(seconds: 30);
}

// ============================================================================
// COLOR PALETTE - Professional Design System
// ============================================================================

class AppColors {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF1FAA7F); // Trust & Growth
  static const Color primaryBlue = Color(0xFF0066CC);  // Reliability
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF8C42); // Energy & Action
  static const Color accentRed = Color(0xFFE63946);    // Issues
  static const Color accentYellow = Color(0xFFFFB703); // Attention
  
  // Success & Status
  static const Color successGreen = Color(0xFF52B788);  // Resolution
  
  // Neutrals
  static const Color neutralLight = Color(0xFFF8F9FA);  // Background
  static const Color neutralDark = Color(0xFF1A202C);   // Text
  static const Color gray = Color(0xFF718096);          // Secondary Text
  static const Color divider = Color(0xFFE5E7EB);
  
  // Legacy/Semantic Mappings
  static const Color primary = primaryGreen;
  static const Color secondary = primaryBlue;
  static const Color accent = accentOrange;
  static const Color error = accentRed;
  static const Color warning = accentYellow;
  static const Color success = successGreen;
  static const Color info = primaryBlue; // Info color for backward compatibility
  static const Color background = neutralLight;
  static const Color surface = Colors.white;
  static const Color textPrimary = neutralDark;
  static const Color textSecondary = gray;
  
  // Status Colors for Issues
  static const Color statusPending = accentOrange;
  static const Color statusAssigned = primaryBlue;
  static const Color statusResolved = successGreen;
  static const Color statusClosed = gray;
  
  // Priority Colors
  static const Color priorityHigh = accentRed;
  static const Color priorityMedium = accentYellow;
  static const Color priorityLow = successGreen;
}

// ============================================================================
// TYPOGRAPHY SYSTEM
// ============================================================================

class AppTextStyles {
  // Font Families
  static const String primaryFont = 'Inter'; // Will fallback to system
  static const String accentFont = 'Poppins';
  
  // Display Styles
  static const TextStyle displayXL = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle displayL = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // Heading Styles
  static const TextStyle headingXL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingL = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headingM = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body Styles
  static const TextStyle bodyL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodyS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Button Styles
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  
  // Label Styles
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // ============================================================================
  // BACKWARD COMPATIBILITY - Legacy Style Names
  // ============================================================================
  
  static const TextStyle h1 = headingXL;
  static const TextStyle h2 = headingL;
  static const TextStyle h3 = headingM;
  static const TextStyle body1 = bodyL;
  static const TextStyle body2 = bodyM;
}

// ============================================================================
// SPACING SYSTEM (8px Grid)
// ============================================================================

class AppSpacing {
  static const double micro = 4.0;   // Micro-spacing
  static const double xs = 8.0;      // Small gap
  static const double sm = 12.0;     // Standard small
  static const double md = 16.0;     // Standard padding
  static const double lg = 20.0;     // Section spacing
  static const double xl = 24.0;     // Large spacing
  static const double xxl = 32.0;    // XL spacing
  static const double xxxl = 48.0;   // Page margin
}

// ============================================================================
// BORDER RADIUS
// ============================================================================

class AppRadius {
  static const double small = 4.0;        // Small elements
  static const double medium = 8.0;       // Buttons, cards
  static const double large = 12.0;       // Large cards
  static const double xLarge = 16.0;      // Large containers
  static const double xxLarge = 24.0;     // Rounded designs
  static const double circular = 9999.0;  // Circles/Pills
}

// ============================================================================
// ANIMATION DURATIONS
// ============================================================================

class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration loading = Duration(milliseconds: 1000);
  
  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve buttonCurve = Curves.easeOutQuad;
  static const Curve dialogCurve = Curves.easeOutCubic;
}

// ============================================================================
// BUTTON DIMENSIONS
// ============================================================================

class AppDimensions {
  // Button Heights
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightXL = 70.0;
  
  // Touch Targets (Minimum for accessibility)
  static const double minTouchTarget = 48.0;
  
  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 28.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 40.0;
  static const double iconXXXL = 64.0;
  
  // Card Sizes
  static const double cardMinHeight = 120.0;
  static const double statsCardSize = 100.0;
  
  // FAB
  static const double fabSize = 56.0;
  static const double fabMini = 48.0;
  
  // Map Controls
  static const double mapControlSize = 48.0;
}

// ============================================================================
// ELEVATION & SHADOWS
// ============================================================================

class AppShadows {
  static const BoxShadow small = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow medium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow large = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  
  static const BoxShadow primaryGlow = BoxShadow(
    color: Color(0x4D1FAA7F),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}

// ============================================================================
// STORAGE KEYS
// ============================================================================

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userRole = 'user_role';
  static const String onboardingComplete = 'onboarding_complete';
}

// ============================================================================
// ISSUE TYPES
// ============================================================================

class IssueTypes {
  static const String pothole = 'pothole';
  static const String garbage = 'garbage';
  static const String streetlight = 'streetlight';
  static const String drainage = 'drainage';
  static const String waterSupply = 'water_supply';
  static const String roadDamage = 'road_damage';
  static const String other = 'other';
  
  static const Map<String, String> labels = {
    pothole: 'Pothole',
    garbage: 'Garbage',
    streetlight: 'Street Light',
    drainage: 'Drainage',
    waterSupply: 'Water Supply',
    roadDamage: 'Road Damage',
    other: 'Other',
  };
  
  static const Map<String, IconData> icons = {
    pothole: Icons.warning_amber,
    garbage: Icons.delete,
    streetlight: Icons.lightbulb,
    drainage: Icons.water_damage,
    waterSupply: Icons.water_drop,
    roadDamage: Icons.construction,
    other: Icons.report_problem,
  };
}

// ============================================================================
// ISSUE STATUS
// ============================================================================

class IssueStatus {
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String assigned = 'assigned';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String completed = 'completed';
  static const String rejected = 'rejected';
  
  static const Map<String, String> labels = {
    pending: 'Pending',
    verified: 'Verified',
    assigned: 'Assigned',
    inProgress: 'In Progress',
    resolved: 'Resolved',
    completed: 'Completed',
    rejected: 'Rejected',
  };
  
  static const Map<String, Color> colors = {
    pending: AppColors.statusPending,
    verified: AppColors.primaryBlue,
    assigned: AppColors.statusAssigned,
    inProgress: AppColors.primaryBlue,
    resolved: AppColors.statusResolved,
    completed: AppColors.successGreen,
    rejected: AppColors.error,
  };
}

// ============================================================================
// RESPONSIVE BREAKPOINTS
// ============================================================================

class AppBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;
}

// ============================================================================
// APP STRINGS
// ============================================================================

class AppStrings {
  // App Identity
  static const String appName = 'SAAF-SURKSHA';
  static const String appTagline = 'Smart Civic Operating System';
  static const String appDescription = 'Using AI to Build Better Cities';
  
  // Empty States
  static const String noIssuesYet = 'No issues yet';
  static const String noIssuesDescription = 'Start by reporting your first civic issue';
  static const String noDataAvailable = 'No data available';
  
  // Actions
  static const String reportIssue = 'Report Issue';
  static const String viewDashboard = 'View Dashboard';
  static const String liveMap = 'Live Map';
  static const String workerVerification = 'Worker Verification';
  static const String submit = 'Submit';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String done = 'Done';
  
  // Loading & Error States
  static const String loading = 'Loading...';
  static const String pleaseWait = 'Please wait';
  static const String error = 'Error';
  static const String tryAgain = 'Try Again';
  static const String success = 'Success';
}
