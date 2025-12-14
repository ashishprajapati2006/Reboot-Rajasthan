import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorProvider extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _sub;

  bool _isMonitoring = false;
  String? _lastDetection;

  bool get isMonitoring => _isMonitoring;
  String? get lastDetection => _lastDetection;

  /// Naive detection based on acceleration magnitude.
  /// Useful as a starting point; tune thresholds per device.
  Future<void> startMonitoring({
    double potholeThreshold = 18.0,
    double accidentThreshold = 28.0,
  }) async {
    if (_sub != null) return;

    _isMonitoring = true;
    _lastDetection = null;
    notifyListeners();

    _sub = accelerometerEvents.listen((e) {
      final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

      if (magnitude >= accidentThreshold) {
        _lastDetection = 'accident';
        notifyListeners();
      } else if (magnitude >= potholeThreshold) {
        _lastDetection = 'road_damage';
        notifyListeners();
      }
    });
  }

  Future<void> stopMonitoring() async {
    await _sub?.cancel();
    _sub = null;
    _isMonitoring = false;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await stopMonitoring();
    super.dispose();
  }
}
