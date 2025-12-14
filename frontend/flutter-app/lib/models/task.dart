import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String issueId;
  final String assignedTo; // worker uid
  final String status; // assigned | in_progress | completed
  final DateTime assignedAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.issueId,
    required this.assignedTo,
    required this.status,
    required this.assignedAt,
    this.completedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'issueId': issueId,
      'assignedTo': assignedTo,
      'status': status,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
    };
  }

  static Task fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime? toNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Task(
      id: doc.id,
      issueId: (data['issueId'] as String?) ?? '',
      assignedTo: (data['assignedTo'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'assigned',
      assignedAt: toDate(data['assignedAt']),
      completedAt: toNullableDate(data['completedAt']),
    );
  }
}
