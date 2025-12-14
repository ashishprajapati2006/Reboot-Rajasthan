import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<dynamic> _issues = [];
  bool _isLoading = true;
  Position? _currentLocation;
  String _mapProvider = 'openstreetmap';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get all issues
      final issues = await ApiService().getIssues(limit: 100);

      setState(() {
        _currentLocation = position;
        _issues = issues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map: $e'),
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
        title: const Text('Live Map'),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _mapProvider = value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'openstreetmap',
                child: Text('OpenStreetMap'),
              ),
              const PopupMenuItem(
                value: 'satellite',
                child: Text('Satellite View'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map placeholder (using a simple container with instructions)
                Expanded(
                  child: Container(
                    color: Colors.blue[50],
                    child: Stack(
                      children: [
                        // Map background
                        Container(
                          color: Colors.blue[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 80,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Interactive Map View',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_currentLocation != null)
                                Text(
                                  'Current: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                                  style: AppTextStyles.bodyS,
                                ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Map Provider: $_mapProvider',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Issue markers
                        ..._buildIssueMarkers(),

                        // Current location indicator
                        if (_currentLocation != null)
                          Positioned(
                            bottom: 100,
                            right: 20,
                            child: FloatingActionButton.small(
                              onPressed: () {
                                // Center map on current location
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Map centered on current location'),
                                  ),
                                );
                              },
                              backgroundColor: AppColors.primaryGreen,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Issues list panel
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_issues.length} Issues Found',
                              style: AppTextStyles.h3,
                            ),
                            Chip(
                              label: Text('${_issues.length}'),
                              backgroundColor: AppColors.primaryGreen,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      if (_issues.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No issues reported yet',
                            style: AppTextStyles.body1.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: _issues.length,
                            itemBuilder: (context, index) {
                              return _buildIssueCard(_issues[index]);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildIssueMarkers() {
    // Simple marker positioning (simplified for demo purposes)
    return _issues
        .asMap()
        .entries
        .map(
          (entry) => Positioned(
            left: 50.0 + (entry.key % 3) * 80,
            top: 100.0 + (entry.key ~/ 3) * 80,
            child: GestureDetector(
              onTap: () {
                _showIssueDetails(entry.value);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIssueColor(entry.value['status'] ?? 'pending'),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getIssueIcon(entry.value['type'] ?? 'other'),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Color _getIssueColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'assigned':
        return AppColors.info;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  IconData _getIssueIcon(String type) {
    switch (type) {
      case 'pothole':
        return Icons.circle;
      case 'streetlight':
        return Icons.lightbulb;
      case 'garbage':
        return Icons.delete;
      case 'water':
        return Icons.water;
      default:
        return Icons.report_problem;
    }
  }

  Widget _buildIssueCard(dynamic issue) {
    final type = issue['type'] ?? 'other';
    final status = issue['status'] ?? 'pending';
    final location = issue['location'] ?? {};
    final address = location is Map ? location['address'] ?? 'Unknown' : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIssueIcon(type),
                  size: 16,
                  color: _getIssueColor(status),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    IssueTypes.labels[type] ?? type,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _getIssueColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: _getIssueColor(status),
                  fontSize: 9,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Text(
                address,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(dynamic issue) {
    final type = issue['type'] ?? 'unknown';
    final status = issue['status'] ?? 'pending';
    final location = issue['location'] ?? {};
    final address = location is Map ? location['address'] ?? 'Unknown' : 'Unknown';
    final severity = issue['severity'] ?? 'medium';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIssueIcon(type),
                  size: 32,
                  color: _getIssueColor(status),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        IssueTypes.labels[type] ?? type,
                        style: AppTextStyles.h3,
                      ),
                      Text(
                        'Status: ${status.toUpperCase()}',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Location', address),
            _buildDetailRow('Severity', severity.toUpperCase()),
            _buildDetailRow('Reported By', issue['reported_by'] ?? 'Anonymous'),
            if (issue['created_at'] != null)
              _buildDetailRow('Reported At', _formatDate(issue['created_at'])),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigating to issue details...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text('View Full Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
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
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
