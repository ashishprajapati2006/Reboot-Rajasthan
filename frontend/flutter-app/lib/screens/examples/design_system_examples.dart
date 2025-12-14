import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/ui_components.dart';
import '../../utils/animation_utils.dart';

// ============================================================================
// SAAF-SURKSHA HOME SCREEN - DESIGN SYSTEM EXAMPLE
// Professional Marketing-Ready Implementation
// ============================================================================

class HomeScreenExample extends StatelessWidget {
  const HomeScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // HEADER SECTION
              // ============================================================
              FadeInAnimation(
                duration: AppAnimations.medium,
                child: Column(
                  children: [
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.displayXL.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    const Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.bodyM,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // ============================================================
              // STATS CARDS (3 Columns)
              // ============================================================
              const SlideUpAnimation(
                delay: Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        icon: Icons.report_problem,
                        value: '523',
                        label: 'Total Issues',
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatsCard(
                        icon: Icons.check_circle,
                        value: '245',
                        label: 'Resolved',
                        color: AppColors.successGreen,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatsCard(
                        icon: Icons.pending,
                        value: '278',
                        label: 'Active',
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // ============================================================
              // ACTION BUTTONS
              // ============================================================
              SlideUpAnimation(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    ActionButton(
                      text: AppStrings.reportIssue,
                      icon: Icons.add_a_photo,
                      color: AppColors.primaryGreen,
                      onPressed: () {
                        Navigator.pushNamed(context, '/camera');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ActionButton(
                      text: AppStrings.viewDashboard,
                      icon: Icons.dashboard,
                      color: AppColors.primaryBlue,
                      onPressed: () {
                        Navigator.pushNamed(context, '/dashboard');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ActionButton(
                      text: AppStrings.liveMap,
                      icon: Icons.map,
                      color: const Color(0xFF7C3AED),
                      onPressed: () {
                        AppSnackBar.show(
                          context,
                          message: 'Loading Map...',
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ActionButton(
                      text: AppStrings.workerVerification,
                      icon: Icons.verified_user,
                      color: AppColors.accentOrange,
                      onPressed: () {
                        Navigator.pushNamed(context, '/worker-verification');
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // ============================================================
              // FOOTER
              // ============================================================
              FadeInAnimation(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  AppStrings.appDescription,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.gray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN EXAMPLE
// ============================================================================

class DashboardScreenExample extends StatefulWidget {
  const DashboardScreenExample({super.key});

  @override
  State<DashboardScreenExample> createState() => _DashboardScreenExampleState();
}

class _DashboardScreenExampleState extends State<DashboardScreenExample> {
  String _selectedFilter = 'all';
  final bool _isLoading = false;

  // Sample data
  final List<Map<String, dynamic>> _sampleIssues = [
    {
      'title': 'Pothole on Main Street',
      'location': 'Main Street, Jaipur',
      'status': 'pending',
      'priority': 'high',
      'timestamp': '2 hours ago',
      'icon': Icons.warning_amber,
    },
    {
      'title': 'Garbage Pile Near Park',
      'location': 'Central Park, Jaipur',
      'status': 'assigned',
      'priority': 'medium',
      'timestamp': '5 hours ago',
      'icon': Icons.delete,
    },
    {
      'title': 'Street Light Not Working',
      'location': 'Park Road, Jaipur',
      'status': 'resolved',
      'priority': 'low',
      'timestamp': '1 day ago',
      'icon': Icons.lightbulb,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // FILTER CHIPS
          // ============================================================
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                FilterChipCustom(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChipCustom(
                  label: 'Pending',
                  isSelected: _selectedFilter == 'pending',
                  onTap: () => setState(() => _selectedFilter = 'pending'),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChipCustom(
                  label: 'Assigned',
                  isSelected: _selectedFilter == 'assigned',
                  onTap: () => setState(() => _selectedFilter = 'assigned'),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChipCustom(
                  label: 'Resolved',
                  isSelected: _selectedFilter == 'resolved',
                  onTap: () => setState(() => _selectedFilter = 'resolved'),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilterChipCustom(
                  label: 'High Priority',
                  isSelected: _selectedFilter == 'high',
                  onTap: () => setState(() => _selectedFilter = 'high'),
                ),
              ],
            ),
          ),
          
          // ============================================================
          // ISSUE LIST
          // ============================================================
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading issues...')
                : _sampleIssues.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox,
                        title: AppStrings.noIssuesYet,
                        description: AppStrings.noIssuesDescription,
                        actionText: AppStrings.reportIssue,
                        onAction: () {
                          Navigator.pushNamed(context, '/camera');
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _sampleIssues.length,
                        itemBuilder: (context, index) {
                          final issue = _sampleIssues[index];
                          return StaggeredListAnimation(
                            index: index,
                            child: IssueCard(
                              title: issue['title'],
                              location: issue['location'],
                              status: issue['status'],
                              priority: issue['priority'],
                              timestamp: issue['timestamp'],
                              icon: issue['icon'],
                              onTap: () {
                                AppSnackBar.show(
                                  context,
                                  message: 'Opening ${issue['title']}',
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppSnackBar.show(
            context,
            message: 'Report new issue',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// WORKER VERIFICATION EXAMPLE
// ============================================================================

class WorkerVerificationExample extends StatefulWidget {
  const WorkerVerificationExample({super.key});

  @override
  State<WorkerVerificationExample> createState() => _WorkerVerificationExampleState();
}

class _WorkerVerificationExampleState extends State<WorkerVerificationExample> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        // Show success
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SuccessCheckmark(size: 100),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verification Submitted!',
                    style: AppTextStyles.headingL.copyWith(
                      color: AppColors.successGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Your application will be reviewed within 24-48 hours.',
                    style: AppTextStyles.bodyM,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    text: 'Done',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Worker Verification'),
      body: Column(
        children: [
          // ============================================================
          // PROGRESS STEPPER
          // ============================================================
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ProgressStepper(
              currentStep: _currentStep,
              totalSteps: 3,
              stepLabels: const ['Personal', 'Documents', 'Submit'],
            ),
          ),
          
          // ============================================================
          // FORM CONTENT
          // ============================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 0) ..._buildPersonalInfoForm(),
                    if (_currentStep == 1) ..._buildDocumentsForm(),
                    if (_currentStep == 2) ..._buildReviewForm(),
                  ],
                ),
              ),
            ),
          ),
          
          // ============================================================
          // NAVIGATION BUTTONS
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [AppShadows.medium],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: SecondaryButton(
                      text: AppStrings.previous,
                      onPressed: _previousStep,
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    text: _currentStep < 2 
                        ? AppStrings.next 
                        : AppStrings.submit,
                    onPressed: _nextStep,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPersonalInfoForm() {
    return [
      const Text('Personal Information', style: AppTextStyles.headingL),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icon(Icons.person),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          hintText: 'Enter your phone number',
          prefixIcon: Icon(Icons.phone),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icon(Icons.email),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildDocumentsForm() {
    return [
      const Text('Upload Documents', style: AppTextStyles.headingL),
      const SizedBox(height: AppSpacing.md),
      _buildUploadBox('Government ID', Icons.badge),
      const SizedBox(height: AppSpacing.md),
      _buildUploadBox('Work Certificate', Icons.work),
      const SizedBox(height: AppSpacing.md),
      _buildUploadBox('Profile Photo', Icons.camera_alt),
    ];
  }

  Widget _buildUploadBox(String label, IconData icon) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.divider,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppSnackBar.show(context, message: 'Upload $label');
          },
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppDimensions.iconXXXL, color: AppColors.gray),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap to upload $label',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReviewForm() {
    return [
      const Text('Review & Submit', style: AppTextStyles.headingL),
      const SizedBox(height: AppSpacing.md),
      _buildInfoRow('Name', _nameController.text),
      _buildInfoRow('Phone', _phoneController.text),
      _buildInfoRow('Email', _emailController.text),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.primaryGreen,
              size: AppDimensions.iconL,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Please review your information carefully before submitting.',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.label.copyWith(color: AppColors.gray),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: AppTextStyles.bodyL,
            ),
          ),
        ],
      ),
    );
  }
}
