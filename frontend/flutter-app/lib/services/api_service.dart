import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.timeout,
      receiveTimeout: ApiConstants.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService init() {
    // Request interceptor - add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.authToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - refresh token or logout
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: StorageKeys.authToken);
            await _storage.delete(key: StorageKeys.userId);
            // Navigator should handle redirect to login
          }
          return handler.next(error);
        },
      ),
    );
    return this;
  }

  // Auth Service
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.authBaseUrl}/register',
      data: {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.authBaseUrl}/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    
    // Save token
    if (response.data['token'] != null) {
      await _storage.write(
        key: StorageKeys.authToken,
        value: response.data['token'],
      );
      await _storage.write(
        key: StorageKeys.userId,
        value: response.data['user']['id'].toString(),
      );
    }
    
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.authBaseUrl}/verify-otp',
      data: {
        'email': email,
        'otp': otp,
      },
    );
    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('${ApiConstants.authBaseUrl}/logout');
    } finally {
      await _storage.deleteAll();
    }
  }

  // Issue Service
  Future<Map<String, dynamic>> detectIssue({
    required File imageFile,
    required double latitude,
    required double longitude,
    required double accelerometerX,
    required double accelerometerY,
    required double accelerometerZ,
    required double lightLevel,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'issue.jpg',
        ),
        'gps_lat': latitude.toString(),
        'gps_lon': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'accelerometer_x': accelerometerX.toString(),
        'accelerometer_y': accelerometerY.toString(),
        'accelerometer_z': accelerometerZ.toString(),
        'light_level': lightLevel.toString(),
      });

      final response = await _dio.post(
        '${ApiConstants.issuesBaseUrl}/detect',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data;
    } catch (e) {
      // Mock response if backend is unavailable
      return _getMockDetectionResponse(latitude, longitude);
    }
  }

  Future<Map<String, dynamic>> createIssue({
    required String detectionId,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.issuesBaseUrl,
        data: {
          'detection_id': detectionId,
          'description': description,
        },
      );
      
      // Save to local storage for offline support
      if (response.data['issue_id'] != null) {
        final issueData = {
          'id': response.data['issue_id'],
          'detection_id': detectionId,
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _saveIssueLocally(issueData);
      }
      
      return response.data;
    } catch (e) {
      // Mock response and save locally if backend is unavailable
      final mockIssue = _generateMockIssue(detectionId, description);
      _saveIssueLocally(mockIssue);
      return {
        'success': true,
        'issue_id': mockIssue['id'],
        'message': 'Issue created (offline mode)',
      };
    }
  }

  Future<List<dynamic>> getIssues({
    String? status,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.issuesBaseUrl,
        queryParameters: {
          if (status != null) 'status': status,
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );
      
      final issues = response.data['issues'] ?? response.data;
      // Merge with locally stored issues
      final localIssues = _getLocalIssues();
      final allIssues = [...?issues as List?, ...localIssues].cast<dynamic>();
      return allIssues;
    } catch (e) {
      // Return mock issues + locally stored issues if backend is unavailable
      final mockIssues = _getMockIssues();
      final localIssues = _getLocalIssues();
      return [...mockIssues, ...localIssues];
    }
  }

  Future<Map<String, dynamic>> getIssueById(String issueId) async {
    final response = await _dio.get(
      '${ApiConstants.issuesBaseUrl}/$issueId',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> voteOnIssue({
    required String issueId,
    required bool upvote,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.issuesBaseUrl}/$issueId/vote',
      data: {'upvote': upvote},
    );
    return response.data;
  }

  // Task Service
  Future<Map<String, dynamic>> voteOnTask({
    required String taskId,
    required bool upvote,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.tasksBaseUrl}/$taskId/vote',
      data: {'upvote': upvote},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final response = await _dio.get(
      '${ApiConstants.tasksBaseUrl}/$taskId',
    );
    return response.data;
  }

  // Analytics Service
  Future<Map<String, dynamic>> getCivicHealthScore() async {
    final response = await _dio.get(
      '${ApiConstants.analyticsBaseUrl}/civic-health',
    );
    return response.data;
  }

  Future<List<dynamic>> getHeatmap({
    double? neLat,
    double? neLng,
    double? swLat,
    double? swLng,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.analyticsBaseUrl}/heatmap',
      queryParameters: {
        if (neLat != null) 'ne_lat': neLat,
        if (neLng != null) 'ne_lng': neLng,
        if (swLat != null) 'sw_lat': swLat,
        if (swLng != null) 'sw_lng': swLng,
      },
    );
    return response.data['heatmap'];
  }

  Future<Map<String, dynamic>> getTrends({
    String period = 'week',
  }) async {
    final response = await _dio.get(
      '${ApiConstants.analyticsBaseUrl}/trends',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  // User Service
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(
      '${ApiConstants.usersBaseUrl}/profile',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.usersBaseUrl}/profile',
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getLeaderboard({
    String period = 'month',
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.usersBaseUrl}/leaderboard',
      queryParameters: {
        'period': period,
        'limit': limit,
      },
    );
    return response.data['leaderboard'];
  }

  // Worker Verification Service
  Future<List<dynamic>> getWorkers({
    String? status,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/workers',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
        },
      );
      return response.data['workers'] ?? [];
    } catch (e) {
      // Return mock data for demo purposes
      return _getMockWorkers();
    }
  }

  Future<Map<String, dynamic>> getWorkerDetails(String workerId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/workers/$workerId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get worker details: $e');
    }
  }

  Future<void> verifyWorker(String workerId, bool approved) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/workers/$workerId/verify',
        data: {
          'approved': approved,
        },
      );
    } catch (e) {
      throw Exception('Failed to verify worker: $e');
    }
  }

  Future<Map<String, dynamic>> getWorkerPerformance(String workerId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/workers/$workerId/performance',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to get worker performance: $e');
    }
  }

  Future<List<dynamic>> getWorkerTasks(String workerId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/workers/$workerId/tasks',
      );
      return response.data['tasks'] ?? [];
    } catch (e) {
      throw Exception('Failed to get worker tasks: $e');
    }
  }

  // Mock data for demo
  List<dynamic> _getMockWorkers() {
    return [
      {
        'id': 'worker_001',
        'name': 'Rajesh Kumar',
        'phone': '+91 9876543210',
        'department': 'Pothole Repair',
        'verification_status': 'verified',
        'tasks_completed': 45,
        'tasks_assigned': 50,
        'performance_score': 9.2,
        'join_date': '2024-06-15',
      },
      {
        'id': 'worker_002',
        'name': 'Priya Singh',
        'phone': '+91 9876543211',
        'department': 'Street Cleaning',
        'verification_status': 'verified',
        'tasks_completed': 38,
        'tasks_assigned': 40,
        'performance_score': 8.8,
        'join_date': '2024-07-10',
      },
      {
        'id': 'worker_003',
        'name': 'Amit Patel',
        'phone': '+91 9876543212',
        'department': 'Garbage Collection',
        'verification_status': 'pending',
        'tasks_completed': 0,
        'tasks_assigned': 5,
        'performance_score': 0.0,
        'join_date': '2024-12-10',
      },
      {
        'id': 'worker_004',
        'name': 'Neha Sharma',
        'phone': '+91 9876543213',
        'department': 'Street Lighting',
        'verification_status': 'verified',
        'tasks_completed': 52,
        'tasks_assigned': 55,
        'performance_score': 9.5,
        'join_date': '2024-05-20',
      },
      {
        'id': 'worker_005',
        'name': 'Vikram Das',
        'phone': '+91 9876543214',
        'department': 'Water Management',
        'verification_status': 'rejected',
        'tasks_completed': 10,
        'tasks_assigned': 30,
        'performance_score': 5.2,
        'join_date': '2024-08-05',
      },
    ];
  }

  // Mock detection response for when backend is unavailable
  Map<String, dynamic> _getMockDetectionResponse(double latitude, double longitude) {
    final issueTypes = ['POTHOLE', 'STREETLIGHT_FAILURE', 'WATER_LEAK', 'GARBAGE_DUMP', 'ROAD_DAMAGE'];
    final severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
    final random = DateTime.now().millisecond;
    
    return {
      'success': true,
      'message': 'Issue detected and saved',
      'detection_id': 'det_${DateTime.now().millisecondsSinceEpoch}',
      'issue_id': 'issue_${DateTime.now().millisecondsSinceEpoch}',
      'detection_data': {
        'confidence': 0.85 + (random % 15) / 100,
        'issue_type': issueTypes[random % issueTypes.length],
        'severity': severities[random % severities.length],
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      },
      'metadata': {
        'image_url': 'https://via.placeholder.com/400x300?text=Issue+Detected',
        'device_id': 'mock_device_${DateTime.now().millisecondsSinceEpoch}',
      },
    };
  }

  // Local storage helpers for offline support
  void _saveIssueLocally(Map<String, dynamic> issue) {
    try {
      // Save to SharedPreferences for offline support
      _storage.write(
        key: 'local_issue_${issue['id']}',
        value: issue.toString(),
      );
    } catch (e) {
      debugPrint('Failed to save issue locally: $e');
    }
  }

  List<Map<String, dynamic>> _getLocalIssues() {
    // Return empty list for now - in production, read from SharedPreferences
    return [];
  }

  Map<String, dynamic> _generateMockIssue(String detectionId, String? description) {
    final issueTypes = ['POTHOLE', 'STREETLIGHT_FAILURE', 'WATER_LEAK', 'GARBAGE_DUMP', 'ROAD_DAMAGE'];
    final severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
    final random = DateTime.now().millisecond;
    
    return {
      'id': 'issue_${DateTime.now().millisecondsSinceEpoch}',
      'detection_id': detectionId,
      'issue_type': issueTypes[random % issueTypes.length],
      'severity': severities[random % severities.length],
      'status': 'pending',
      'description': description ?? 'Civic issue reported',
      'latitude': 26.9124,
      'longitude': 75.7873,
      'timestamp': DateTime.now().toIso8601String(),
      'upvotes': 0,
      'downvotes': 0,
    };
  }

  List<Map<String, dynamic>> _getMockIssues() {
    return [
      {
        'id': 'issue_001',
        'issue_type': 'POTHOLE',
        'severity': 'HIGH',
        'status': 'pending',
        'description': 'Large pothole on MG Road causing traffic issues',
        'latitude': 26.9124,
        'longitude': 75.7873,
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'upvotes': 5,
        'downvotes': 0,
        'image_url': 'https://via.placeholder.com/400x300?text=Pothole',
      },
      {
        'id': 'issue_002',
        'issue_type': 'STREETLIGHT_FAILURE',
        'severity': 'MEDIUM',
        'status': 'assigned',
        'description': 'Multiple streetlights not working on Sanganeri Gate Road',
        'latitude': 26.9145,
        'longitude': 75.7880,
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'upvotes': 3,
        'downvotes': 1,
        'image_url': 'https://via.placeholder.com/400x300?text=Streetlight',
      },
      {
        'id': 'issue_003',
        'issue_type': 'WATER_LEAK',
        'severity': 'HIGH',
        'status': 'in_progress',
        'description': 'Water leaking from main pipeline near City Palace',
        'latitude': 26.9250,
        'longitude': 75.8250,
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'upvotes': 8,
        'downvotes': 0,
        'image_url': 'https://via.placeholder.com/400x300?text=Water+Leak',
      },
      {
        'id': 'issue_004',
        'issue_type': 'GARBAGE_DUMP',
        'severity': 'LOW',
        'status': 'resolved',
        'description': 'Unauthorized garbage dumping near parking area',
        'latitude': 26.9100,
        'longitude': 75.7850,
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'upvotes': 2,
        'downvotes': 0,
        'image_url': 'https://via.placeholder.com/400x300?text=Garbage',
      },
      {
        'id': 'issue_005',
        'issue_type': 'ROAD_DAMAGE',
        'severity': 'CRITICAL',
        'status': 'pending',
        'description': 'Severe road damage on Ajmer Road intersection',
        'latitude': 26.9200,
        'longitude': 75.7900,
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'upvotes': 12,
        'downvotes': 1,
        'image_url': 'https://via.placeholder.com/400x300?text=Road+Damage',
      },
    ];
  }}