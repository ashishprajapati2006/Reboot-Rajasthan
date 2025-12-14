import 'package:cloud_firestore/cloud_firestore.dart';

class Issue {
  final String id;
  final String userId;
  final String type;
  final String description;
  final String location;
  final String status;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final int severityScore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Issue({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.location,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.severityScore,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'description': description,
      'location': location,
      'locationLower': location.toLowerCase(),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'severityScore': severityScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static Issue fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? toNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Issue(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      type: (data['type'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'reported',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      imageUrls: ((data['imageUrls'] as List?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      severityScore: (data['severityScore'] as num?)?.toInt() ?? 0,
      createdAt: toNullableDate(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: toNullableDate(data['updatedAt']),
    );
  }

  Issue copyWith({
    String? status,
    DateTime? updatedAt,
    List<String>? imageUrls,
    int? severityScore,
    String? description,
    String? location,
  }) {
    return Issue(
      id: id,
      userId: userId,
      type: type,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      latitude: latitude,
      longitude: longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      severityScore: severityScore ?? this.severityScore,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
