import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/issue.dart';
import '../services/firestore_service.dart';

class IssueProvider extends ChangeNotifier {
  static const _cacheKey = 'cached_issues_v1';

  final FirestoreService _firestoreService;
  final Connectivity _connectivity;

  IssueProvider({
    FirestoreService? firestoreService,
    Connectivity? connectivity,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _connectivity = connectivity ?? Connectivity();

  bool _isLoading = false;
  String? _error;
  List<Issue> _issues = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Issue> get issues => _issues;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> loadUserIssues(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final connectivity = await _connectivity.checkConnectivity();
      final online = connectivity != ConnectivityResult.none;

      if (!online) {
        await _loadFromCache();
        return;
      }

      _issues = await _firestoreService.getIssuesByUser(userId);
      await _saveToCache(_issues);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshNearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? status,
    String? type,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _issues = await _firestoreService.getNearbyIssues(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        status: status,
        type: type,
      );
      await _saveToCache(_issues);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus({
    required String issueId,
    required String status,
  }) async {
    _setError(null);
    try {
      await _firestoreService.updateIssueStatus(issueId: issueId, status: status);
      _issues = _issues
          .map((i) => i.id == issueId ? i.copyWith(status: status) : i)
          .toList(growable: false);
      await _saveToCache(_issues);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // ------------------------------ Cache ----------------------------------

  Future<void> _saveToCache(List<Issue> issues) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = issues
        .map((i) => {
              'id': i.id,
              ...i.toFirestore(),
            })
        .toList(growable: false);

    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) {
      _issues = const [];
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _issues = const [];
      return;
    }

    _issues = decoded
        .whereType<Map>()
        .map((m) {
          final map = m.cast<String, dynamic>();
          final id = (map['id'] as String?) ?? '';
          // Reuse Issue.fromFirestore shape by simulating doc data.
          // For cache, we store fields exactly as toFirestore() produced.
          return Issue(
            id: id,
            userId: (map['userId'] as String?) ?? '',
            type: (map['type'] as String?) ?? '',
            description: (map['description'] as String?) ?? '',
            location: (map['location'] as String?) ?? '',
            status: (map['status'] as String?) ?? 'reported',
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
            imageUrls: ((map['imageUrls'] as List?) ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false),
            severityScore: (map['severityScore'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.now(),
            updatedAt: null,
          );
        })
        .toList(growable: false);

    notifyListeners();
  }
}
