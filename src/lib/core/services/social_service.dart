// lib/core/services/social_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Uint8List?> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1080,
      minHeight: 1080,
      quality: 20,
    );
    return result;
  }

  Future<void> postToCommunity({
    required File imageFile,
    required bool hasAllergyRisk,
    required List<String> ingredients,
    List<String>? labelContains,
    List<String>? mayContain,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final Uint8List? compressedData = await _compressImage(imageFile);
    if (compressedData == null) throw Exception("Image compression failed");

    final String postId = const Uuid().v4();
    final String filePath = 'community_posts/$postId.jpg';

    final Reference storageRef = _storage.ref().child(filePath);
    final UploadTask uploadTask = storageRef.putData(
      compressedData,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    await _firestore.collection('posts').doc(postId).set({
      'postId': postId,
      'userId': user.uid,
      'userEmail': user.email ?? 'Anonymous',
      'imageUrl': downloadUrl,
      'hasAllergyRisk': hasAllergyRisk,
      'ingredients': ingredients,
      'labelContains': labelContains ?? [],
      'mayContain': mayContain ?? [],

      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'commentCount': 0,
    });
  }
}