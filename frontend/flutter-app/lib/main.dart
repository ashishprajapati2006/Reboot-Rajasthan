import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/examples/design_system_examples.dart'; // NEW DESIGN SYSTEM

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAAF-SURKSHA',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreenExample(), // TEMPORARY: Show design examples
        '/demo': (context) => const DesignSystemDemo(), // Demo navigator
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigator(),
        '/camera': (context) => const CameraScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/design-home': (context) => const HomeScreenExample(),
        '/design-dashboard': (context) => const DashboardScreenExample(),
        '/design-verification': (context) => const WorkerVerificationExample(),
      },
    );
  }
}

// ============================================================================
// DESIGN SYSTEM DEMO NAVIGATOR
// ============================================================================
class DesignSystemDemo extends StatelessWidget {
  const DesignSystemDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🎨 Design System Demo'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'SAAF-SURKSHA',
            style: AppTextStyles.displayL.copyWith(
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Professional Design System Examples',
            style: AppTextStyles.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          
          _buildDemoCard(
            context,
            'Home Dashboard',
            'Professional home screen with stats and action buttons',
            Icons.home,
            AppColors.primaryGreen,
            () => Navigator.pushNamed(context, '/design-home'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildDemoCard(
            context,
            'Dashboard with Filters',
            'Issue list with filters, animations, and empty states',
            Icons.dashboard,
            AppColors.primaryBlue,
            () => Navigator.pushNamed(context, '/design-dashboard'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _buildDemoCard(
            context,
            'Worker Verification',
            'Multi-step form with progress stepper',
            Icons.verified_user,
            AppColors.accentOrange,
            () => Navigator.pushNamed(context, '/design-verification'),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/splash'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Original App'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingM.copyWith(color: color),
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      description,
                      style: AppTextStyles.bodyS,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Skip authentication - go directly to home
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 100,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'SAAF-SURKSHA',
              style: AppTextStyles.h1,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Civic Issue Tracking',
              style: AppTextStyles.body2,
            ),
            SizedBox(height: AppSpacing.xl),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CameraScreen(),
    const MapPlaceholder(),
    const IssuesPlaceholder(),
    const ProfilePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: const Center(child: Text('Map Screen - Coming Soon')),
    );
  }
}

class IssuesPlaceholder extends StatelessWidget {
  const IssuesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Issues')),
      body: const Center(child: Text('My Issues - Coming Soon')),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile Screen - Coming Soon'),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                await ApiService().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
