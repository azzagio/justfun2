import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const uuid = Uuid(); // Utilisation de const si le constructeur Uuid() est const

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      String userId = _auth.currentUser!.uid;
      String imageId = uuid.v4();
      String path = 'profile_images/$userId/$imageId.jpg';

      UploadTask uploadTask = _storage.ref().child(path).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      // Utiliser print temporairement (à remplacer par un logger en production)
      print('Error deleting image: $e');
      // OU utiliser debugPrint si vous voulez le garder pour le développement :
      // debugPrint('Error deleting image: $e');
    }
  }
}