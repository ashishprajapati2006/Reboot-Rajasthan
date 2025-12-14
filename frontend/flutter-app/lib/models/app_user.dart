import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String role; // citizen | worker | admin
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isVerified,
    required this.createdAt,
    this.phone,
    this.lastLoginAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'emailLower': email.toLowerCase(),
      'name': name,
      'nameLower': name.toLowerCase(),
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt == null ? null : Timestamp.fromDate(lastLoginAt!),
    };
  }

  static AppUser fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return AppUser(
      uid: (data['uid'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      phone: data['phone'] as String?,
      role: (data['role'] as String?) ?? 'citizen',
      isVerified: (data['isVerified'] as bool?) ?? false,
      createdAt: toDate(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] == null ? null : toDate(data['lastLoginAt']),
    );
  }
}
