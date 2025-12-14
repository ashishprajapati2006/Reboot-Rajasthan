import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _issues = [];

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final issues = await ApiService().getIssues(limit: 50);
      if (mounted) {
        setState(() {
          _issues = List<Map<String, dynamic>>.from(
            issues.map((issue) => issue as Map<String, dynamic>),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load issues: $e');
      }
    }
  }

  Future<void> _voteOnIssue(String issueId, bool upvote) async {
    try {
      await ApiService().voteOnIssue(issueId: issueId, upvote: upvote);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(upvote ? '👍 Vote recorded!' : '👎 Vote recorded!'),
            duration: const Duration(seconds: 2),
          ),
        );
        // Refresh issues to show updated vote count
        _loadIssues();
      }
    } catch (e) {
      _showError('Failed to vote: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredIssues() {
    if (_selectedFilter == 'all') return _issues;
    return _issues.where((issue) => issue['status'] == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    return IssueStatus.colors[status] ?? AppColors.gray;
  }

  String _getStatusLabel(String status) {
    return IssueStatus.labels[status] ?? status;
  }

  IconData _getIssueIcon(String type) {
    return IssueTypes.icons[type] ?? Icons.report_problem;
  }

  String _getIssueLabel(String type) {
    return IssueTypes.labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    final filteredIssues = _getFilteredIssues();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Issues Dashboard'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Assigned', 'assigned'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('Resolved', 'resolved'),
              ],
            ),
          ),

          // Issues List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredIssues.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadIssues,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filteredIssues.length,
                          itemBuilder: (context, index) {
                            final issue = filteredIssues[index];
                            return _buildIssueCard(issue);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.primary.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.gray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.gray,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: AppColors.gray.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No issues found',
            style: AppTextStyles.h3.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Issues you report will appear here',
            style: AppTextStyles.body2.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Report an Issue'),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    final issueType = issue['type'] ?? 'other';
    final status = issue['status'] ?? 'pending';
    final location = issue['location'] ?? 'Unknown location';
    final address = location is Map ? location['address'] ?? 'Unknown' : location.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(
            _getIssueIcon(issueType),
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          _getIssueLabel(issueType),
          style: AppTextStyles.h3,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              address,
              style: AppTextStyles.bodyS,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Chip(
                  label: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  issue['created_at'] ?? 'N/A',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Details
                _buildDetailRow('Issue ID', issue['id']?.toString() ?? 'N/A'),
                const SizedBox(height: AppSpacing.md),
                _buildDetailRow('Status', _getStatusLabel(status)),
                const SizedBox(height: AppSpacing.md),
                _buildDetailRow('Type', _getIssueLabel(issueType)),
                const SizedBox(height: AppSpacing.md),
                _buildDetailRow('Priority', issue['priority']?.toString() ?? 'Normal'),
                const SizedBox(height: AppSpacing.md),

                // Description if available
                if (issue['description'] != null && (issue['description'] as String).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          issue['description'],
                          style: AppTextStyles.body2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),

                // Completion Status
                if (status == 'resolved')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Issue Resolved ✓',
                                    style: AppTextStyles.h3,
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Work has been completed. Please verify and provide feedback.',
                                    style: AppTextStyles.bodyS,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),

                // Voting/Feedback Section
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                const Text('Your Feedback', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildVoteButton(
                      icon: Icons.thumb_up,
                      label: 'Helpful',
                      color: AppColors.success,
                      onPressed: () => _voteOnIssue(issue['id'], true),
                    ),
                    _buildVoteButton(
                      icon: Icons.comment,
                      label: 'Feedback',
                      color: AppColors.info,
                      onPressed: () {
                        _showFeedbackDialog(issue['id']);
                      },
                    ),
                    _buildVoteButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: AppColors.warning,
                      onPressed: () {
                        // Share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing issue...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.gray,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            padding: const EdgeInsets.all(AppSpacing.md),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }

  void _showFeedbackDialog(String issueId) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Feedback'),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us about the work quality, timeliness, and professionalism...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (feedbackController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
