import 'dart:math';

class SeverityUtils {
  /// Computes a severity score 0..100 based on:
  /// - priority: 1..5 (if you have it)
  /// - ageHours: how long pending
  /// - hasInjury: accident-like event
  /// - confidence: model confidence 0..1
  static int computeSeverityScore({
    int? priority,
    double? ageHours,
    bool hasInjury = false,
    double? confidence,
  }) {
    final p = (priority ?? 3).clamp(1, 5);
    final age = max(0.0, ageHours ?? 0);
    final conf = (confidence ?? 0.5).clamp(0.0, 1.0);

    // Base from priority
    var score = (p - 1) * 15.0; // 0..60

    // Add urgency over time (cap)
    score += min(30.0, age * 1.5);

    // Add injury/accident boost
    if (hasInjury) score += 15.0;

    // Weight by confidence
    score *= (0.6 + 0.4 * conf);

    return score.round().clamp(0, 100);
  }
}
