import 'dart:io';
import 'package:dio/dio.dart';
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
  }

  Future<Map<String, dynamic>> createIssue({
    required String detectionId,
    String? description,
  }) async {
    final response = await _dio.post(
      ApiConstants.issuesBaseUrl,
      data: {
        'detection_id': detectionId,
        'description': description,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getIssues({
    String? status,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.issuesBaseUrl,
      queryParameters: {
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        'page': page,
        'limit': limit,
      },
    );
    return response.data['issues'];
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
}
