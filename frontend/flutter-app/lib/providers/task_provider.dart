import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestore;

  TaskProvider({FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService();

  bool _isLoading = false;
  String? _error;
  final List<Task> _tasks = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Task> get tasks => _tasks;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  Stream<List<Task>> streamWorkerTasks(String workerUid) {
    return _firestore.streamWorkerTasks(workerUid);
  }

  Future<void> assignTask({
    required String issueId,
    required String workerUid,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firestore.assignTask(issueId: issueId, workerUid: workerUid);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeTask({
    required String taskId,
    required String issueId,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firestore.completeTask(taskId: taskId, issueId: issueId);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
