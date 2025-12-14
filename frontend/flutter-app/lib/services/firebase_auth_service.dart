import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';

class FirebaseAuthService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  fb.User? get currentFirebaseUser => _auth.currentUser;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
    String role = 'citizen',
  }) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = creds.user!.uid;
    final now = DateTime.now();

    final appUser = AppUser(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      role: role,
      isVerified: role == 'citizen',
      createdAt: now,
      lastLoginAt: now,
    );

    await _firestore.collection('users').doc(uid).set(appUser.toFirestore());

    return appUser;
  }

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final creds = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = creds.user!.uid;
    await _firestore.collection('users').doc(uid).set(
      {
        'lastLoginAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      // If the user existed in Auth but not in Firestore, backfill minimal profile.
      final now = DateTime.now();
      final backfill = AppUser(
        uid: uid,
        email: email,
        name: creds.user?.displayName ?? 'User',
        role: 'citizen',
        isVerified: false,
        createdAt: now,
        lastLoginAt: now,
      );
      await _firestore.collection('users').doc(uid).set(backfill.toFirestore());
      return backfill;
    }

    return AppUser.fromFirestore(userDoc);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
