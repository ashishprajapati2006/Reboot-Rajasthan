import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  /// Best-effort init:
  /// - Returns `true` if Firebase initialized
  /// - Returns `false` if initialization failed (missing config, etc.)
  ///
  /// This keeps the current app usable even before adding
  /// `google-services.json` / iOS GoogleService-Info.plist.
  static Future<bool> tryInitialize() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: $e');
      }
      return false;
    }
  }
}
