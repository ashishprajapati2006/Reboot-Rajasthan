import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _issues = [];
  bool _isLoading = true;
  Map<String, dynamic>? _civicHealth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final issues = await ApiService().getIssues(limit: 10);
      final health = await ApiService().getCivicHealthScore();
      
      setState(() {
        _issues = issues;
        _civicHealth = health;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAAF-SURKSHA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Civic Health Score Card
                  if (_civicHealth != null) _buildCivicHealthCard(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Recent Issues
                  const Text('Recent Issues', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  ..._issues.map((issue) => _buildIssueCard(issue)),
                ],
              ),
      ),
    );
  }

  Widget _buildCivicHealthCard() {
    final score = _civicHealth?['civic_health_score'] ?? 0;
    final scoreInt = (score * 100).toInt();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const Text('Civic Health Score', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$scoreInt%',
              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                label: 'Report Issue',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/camera'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionCard(
                icon: Icons.dashboard,
                label: 'My Dashboard',
                color: AppColors.info,
                onTap: () => Navigator.pushNamed(context, '/dashboard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.map,
                label: 'View Map',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.pushNamed(context, '/map'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionCard(
                icon: Icons.verified_user,
                label: 'Leaderboard',
                color: AppColors.warning,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leaderboard coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: AppTextStyles.body2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard(dynamic issue) {
    final type = issue['type'] ?? 'other';
    final status = issue['status'] ?? 'pending';
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: IssueStatus.colors[status],
          child: Icon(
            IssueTypes.icons[type] ?? Icons.report_problem,
            color: Colors.white,
          ),
        ),
        title: Text(IssueTypes.labels[type] ?? type),
        subtitle: Text(
          '${issue['location']?['address'] ?? 'Unknown location'}\n${issue['created_at'] ?? ''}',
        ),
        trailing: Chip(
          label: Text(IssueStatus.labels[status] ?? status),
          backgroundColor: IssueStatus.colors[status]?.withOpacity(0.2),
          labelStyle: TextStyle(
            color: IssueStatus.colors[status],
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Navigate to issue details
        },
      ),
    );
  }
}
