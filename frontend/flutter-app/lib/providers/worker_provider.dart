import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';

class WorkerProvider extends ChangeNotifier {
  final FirestoreService _firestore;

  WorkerProvider({FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  Future<void> verifyWorker({
    required String workerUid,
    required String name,
    required String department,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firestore.verifyWorker(
        workerUid: workerUid,
        name: name,
        department: department,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
