import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/issue.dart';
import '../models/task.dart';
import '../models/worker.dart';
import '../utils/geo_utils.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _issues =>
      _firestore.collection('issues');

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _workers =>
      _firestore.collection('workers');

  Future<String> createIssue(Issue issue) async {
    final doc = await _issues.add(issue.toFirestore());
    return doc.id;
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
  }) async {
    await _issues.doc(issueId).set(
      {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addIssueImages({
    required String issueId,
    required List<String> imageUrls,
  }) async {
    await _issues.doc(issueId).set(
      {
        'imageUrls': FieldValue.arrayUnion(imageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<Issue>> getIssuesByUser(String userId) async {
    final snap = await _issues
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map(Issue.fromFirestore).toList(growable: false);
  }

  Stream<List<Issue>> streamIssuesByUser(String userId) {
    return _issues
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(Issue.fromFirestore).toList(growable: false));
  }

  /// Prefix search on location (case-insensitive). Firestore doesn't support
  /// true contains/substring search without extra indexing strategy.
  Future<List<Issue>> searchIssuesByLocationPrefix(String prefixLower) async {
    final start = prefixLower.trim().toLowerCase();
    if (start.isEmpty) return <Issue>[];

    final end = '$start\uf8ff';
    final snap = await _issues
        .orderBy('locationLower')
        .startAt([start])
        .endAt([end])
        .limit(50)
        .get();

    return snap.docs.map(Issue.fromFirestore).toList(growable: false);
  }

  Future<List<Issue>> getNearbyIssues({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? status,
    String? type,
  }) async {
    final box = GeoUtils.boundingBox(lat: lat, lng: lng, radiusKm: radiusKm);

    Query<Map<String, dynamic>> q = _issues
        .where('latitude', isGreaterThanOrEqualTo: box.minLat)
        .where('latitude', isLessThanOrEqualTo: box.maxLat)
        .where('longitude', isGreaterThanOrEqualTo: box.minLng)
        .where('longitude', isLessThanOrEqualTo: box.maxLng)
        .limit(200);

    if (status != null) q = q.where('status', isEqualTo: status);
    if (type != null) q = q.where('type', isEqualTo: type);

    final snap = await q.get();

    final results = snap.docs
        .map(Issue.fromFirestore)
        .map((issue) {
          final d = GeoUtils.distanceKm(
            lat1: lat,
            lng1: lng,
            lat2: issue.latitude,
            lng2: issue.longitude,
          );
          return (issue: issue, distKm: d);
        })
        .where((x) => x.distKm <= radiusKm)
        .toList(growable: false);

    results.sort((a, b) => a.distKm.compareTo(b.distKm));
    return results.map((x) => x.issue).toList(growable: false);
  }

  Stream<List<Issue>> streamNearbyIssues({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? status,
    String? type,
  }) {
    final box = GeoUtils.boundingBox(lat: lat, lng: lng, radiusKm: radiusKm);

    Query<Map<String, dynamic>> q = _issues
        .where('latitude', isGreaterThanOrEqualTo: box.minLat)
        .where('latitude', isLessThanOrEqualTo: box.maxLat)
        .where('longitude', isGreaterThanOrEqualTo: box.minLng)
        .where('longitude', isLessThanOrEqualTo: box.maxLng)
        .limit(200);

    if (status != null) q = q.where('status', isEqualTo: status);
    if (type != null) q = q.where('type', isEqualTo: type);

    return q.snapshots().map((snap) {
      final results = snap.docs
          .map(Issue.fromFirestore)
          .where((issue) {
            final d = GeoUtils.distanceKm(
              lat1: lat,
              lng1: lng,
              lat2: issue.latitude,
              lng2: issue.longitude,
            );
            return d <= radiusKm;
          })
          .toList(growable: false);

      return results;
    });
  }

  // ---------------------------- Tasks / Workers ----------------------------

  Future<String> assignTask({
    required String issueId,
    required String workerUid,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: '',
      issueId: issueId,
      assignedTo: workerUid,
      status: 'assigned',
      assignedAt: now,
    );

    final doc = await _tasks.add(task.toFirestore());
    await updateIssueStatus(issueId: issueId, status: 'in_progress');
    return doc.id;
  }

  Stream<List<Task>> streamWorkerTasks(String workerUid) {
    return _tasks
        .where('assignedTo', isEqualTo: workerUid)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(Task.fromFirestore).toList(growable: false));
  }

  Future<void> completeTask({
    required String taskId,
    required String issueId,
  }) async {
    await _tasks.doc(taskId).set(
      {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await updateIssueStatus(issueId: issueId, status: 'resolved');
  }

  Future<void> verifyWorker({
    required String workerUid,
    required String department,
    required String name,
  }) async {
    final profile = WorkerProfile(
      uid: workerUid,
      name: name,
      department: department,
      isVerified: true,
      createdAt: DateTime.now(),
    );

    await _workers.doc(workerUid).set(profile.toFirestore(), SetOptions(merge: true));
    await _firestore.collection('users').doc(workerUid).set(
      {
        'role': 'worker',
        'isVerified': true,
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, int>> getAnalyticsCounts() async {
    final snap = await _issues.get();
    final issues = snap.docs.map(Issue.fromFirestore);

    final counts = <String, int>{};
    for (final i in issues) {
      counts[i.status] = (counts[i.status] ?? 0) + 1;
    }
    return counts;
  }
}
