import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getFcmToken() => _messaging.getToken();

  Stream<RemoteMessage> onForegroundMessage() => FirebaseMessaging.onMessage;

  Future<void> saveTokenForUser({
    required String uid,
    required String token,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> subscribeToTopic(String topic) => _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Client apps generally should NOT send push notifications directly.
  /// Implement this via a secure backend (Cloud Functions / server) instead.
  Future<void> sendNotification() {
    throw UnsupportedError('Use a backend/Cloud Function to send notifications.');
  }
}
