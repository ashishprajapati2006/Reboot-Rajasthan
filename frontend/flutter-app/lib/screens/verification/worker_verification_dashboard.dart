import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class WorkerVerificationDashboard extends StatefulWidget {
  const WorkerVerificationDashboard({super.key});

  @override
  State<WorkerVerificationDashboard> createState() =>
      _WorkerVerificationDashboardState();
}

class _WorkerVerificationDashboardState
    extends State<WorkerVerificationDashboard> {
  List<dynamic> _workers = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, verified, pending, rejected
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);

    try {
      final workers = await ApiService().getWorkers();
      setState(() {
        _workers = workers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workers: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<dynamic> _getFilteredWorkers() {
    return _workers.where((worker) {
      final status = worker['verification_status'] ?? 'pending';
      final name = (worker['name'] ?? '').toString().toLowerCase();
      final phone = (worker['phone'] ?? '').toString();
      final id = (worker['id'] ?? '').toString();

      // Filter by status
      if (_filterStatus != 'all' && status != _filterStatus) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return name.contains(_searchQuery.toLowerCase()) ||
            phone.contains(_searchQuery) ||
            id.contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  Future<void> _verifyWorker(String workerId, bool approved) async {
    try {
      await ApiService().verifyWorker(workerId, approved);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved
                  ? 'Worker verified successfully'
                  : 'Worker verification rejected',
            ),
            backgroundColor: approved ? AppColors.success : AppColors.warning,
          ),
        );
      }

      await _loadWorkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Verification'),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Panel
                _buildStatisticsPanel(),

                // Search and Filter Bar
                _buildSearchAndFilterBar(),

                // Workers List
                Expanded(
                  child: _getFilteredWorkers().isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _getFilteredWorkers().length,
                          itemBuilder: (context, index) {
                            return _buildWorkerCard(
                              _getFilteredWorkers()[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsPanel() {
    final verified =
        _workers.where((w) => w['verification_status'] == 'verified').length;
    final pending =
        _workers.where((w) => w['verification_status'] == 'pending').length;
    final rejected =
        _workers.where((w) => w['verification_status'] == 'rejected').length;

    return Container(
      color: AppColors.primaryGreen.withOpacity(0.1),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            'Worker Verification Overview',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildStatCard(
                label: 'Total Workers',
                value: _workers.length.toString(),
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSpacing.md),
              _buildStatCard(
                label: 'Verified',
                value: verified.toString(),
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _buildStatCard(
                label: 'Pending',
                value: pending.toString(),
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              _buildStatCard(
                label: 'Rejected',
                value: rejected.toString(),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headingL.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Verified', 'verified'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No workers found',
            style: AppTextStyles.h3.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your filters or search query',
            style: AppTextStyles.bodyM.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(dynamic worker) {
    final status = worker['verification_status'] ?? 'pending';
    final name = worker['name'] ?? 'Unknown';
    final phone = worker['phone'] ?? 'N/A';
    final department = worker['department'] ?? 'General';
    final tasksCompleted = worker['tasks_completed'] ?? 0;
    final tasksAssigned = worker['tasks_assigned'] ?? 0;
    final performance = worker['performance_score'] ?? 0.0;
    final joinDate = worker['join_date'] ?? DateTime.now().toString();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          // Worker header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: _getStatusColor(status).withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(status),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'W',
                      style: AppTextStyles.headingL.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Worker info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            phone,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildDetailRow('Department', department),
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(
                  'Task Completion',
                  '$tasksCompleted/$tasksAssigned completed',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPerformanceIndicator(performance),
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow('Joined', _formatDate(joinDate)),
              ],
            ),
          ),

          // Performance metrics
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _buildMetricBox(
                      'Completion Rate',
                      tasksAssigned > 0
                          ? ((tasksCompleted / tasksAssigned) * 100)
                              .toStringAsFixed(1)
                          : '0',
                      '%',
                      AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildMetricBox(
                      'Performance Score',
                      performance.toStringAsFixed(1),
                      '/10',
                      _getPerformanceColor(performance),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildMetricBox(
                      'Tasks Completed',
                      tasksCompleted.toString(),
                      '',
                      AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons (only for pending status)
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _verifyWorker(worker['id'], false);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _verifyWorker(worker['id'], true);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showWorkerDetailsModal(worker);
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('View Full Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                ),
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
          style: AppTextStyles.bodyM.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyM.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Performance',
              style: AppTextStyles.bodyM.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${score.toStringAsFixed(1)}/10',
              style: AppTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: _getPerformanceColor(score),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 10,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              _getPerformanceColor(score),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$value$unit',
              style: AppTextStyles.h3.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  Color _getPerformanceColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.info;
    if (score >= 4) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showWorkerDetailsModal(dynamic worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Worker Details',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Name', worker['name'] ?? 'N/A'),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow('Phone', worker['phone'] ?? 'N/A'),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow('Department', worker['department'] ?? 'N/A'),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow('Status', worker['verification_status'] ?? 'N/A'),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Task History',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Total Tasks',
                (worker['tasks_assigned'] ?? 0).toString(),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Completed',
                (worker['tasks_completed'] ?? 0).toString(),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                'Pending',
                (((worker['tasks_assigned'] ?? 0) -
                            (worker['tasks_completed'] ?? 0)) as int)
                    .toString(),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
