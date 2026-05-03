import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload prescription image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadPrescription(File imageFile, String userId) async {
    try {
      // Create a unique filename based on timestamp
      String fileName =
          'prescriptions/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload the file
      TaskSnapshot snapshot = await _storage.ref(fileName).putFile(imageFile);

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw 'Failed to upload prescription: ${e.message}';
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw 'Failed to delete image: ${e.message}';
    }
  }

  /// Get download URL for a file
  Future<String> getDownloadUrl(String filePath) async {
    try {
      return await _storage.ref(filePath).getDownloadURL();
    } on FirebaseException catch (e) {
      throw 'Failed to get download URL: ${e.message}';
    }
  }
}
