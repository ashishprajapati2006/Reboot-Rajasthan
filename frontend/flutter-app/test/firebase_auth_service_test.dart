import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saaf_surksha/services/firebase_auth_service.dart';

void main() {
  test('FirebaseAuthService signUp creates user doc', () async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();

    final service = FirebaseAuthService(auth: auth, firestore: firestore);

    final user = await service.signUpWithEmailPassword(
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      phone: '+919876543210',
      role: 'citizen',
    );

    final doc = await firestore.collection('users').doc(user.uid).get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['email'], 'test@example.com');
    expect(doc.data()?['name'], 'Test User');
  });
}
