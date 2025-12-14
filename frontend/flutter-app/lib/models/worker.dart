import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerProfile {
  final String uid;
  final String name;
  final String department;
  final bool isVerified;
  final DateTime createdAt;

  const WorkerProfile({
    required this.uid,
    required this.name,
    required this.department,
    required this.isVerified,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'nameLower': name.toLowerCase(),
      'department': department,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static WorkerProfile fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return WorkerProfile(
      uid: (data['uid'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      department: (data['department'] as String?) ?? 'general',
      isVerified: (data['isVerified'] as bool?) ?? false,
      createdAt: toDate(data['createdAt']),
    );
  }
}
