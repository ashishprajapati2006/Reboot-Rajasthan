import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadIssueImage({
    required String issueId,
    required XFile file,
  }) async {
    final ref = _storage
        .ref()
        .child('issues')
        .child(issueId)
        .child('${DateTime.now().millisecondsSinceEpoch}_${file.name}');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }
}
