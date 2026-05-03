import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

/// Service for handling authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Create user account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();

      // Create user document in Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(
            AppUser(
              userId: credential.user!.uid,
              email: email,
              displayName: displayName,
              createdAt: DateTime.now(),
            ).toJson(),
          );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'সাইন আপ ব্যর্থ হয়েছে';
    }
  }

  /// Sign up with phone number (mock implementation)
  Future<void> signUpWithPhone(String phoneNumber) async {
    try {
      // For demo purposes, we'll create an anonymous user
      // In production, you'd implement proper phone authentication
      UserCredential credential = await _auth.signInAnonymously();

      // Create user document in Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(
            AppUser(
              userId: credential.user!.uid,
              phoneNumber: phoneNumber,
              createdAt: DateTime.now(),
            ).toJson(),
          );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'ফোন সাইন আপ ব্যর্থ হয়েছে';
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'সাইন ইন ব্যর্থ হয়েছে';
    }
  }

  /// Anonymous sign in (for demo)
  Future<void> signInAnonymously() async {
    try {
      UserCredential credential = await _auth.signInAnonymously();

      // Create user document in Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(
            AppUser(
              userId: credential.user!.uid,
              createdAt: DateTime.now(),
            ).toJson(),
          );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'অনামিকা সাইন ইন ব্যর্থ হয়েছে';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign out failed';
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }
}
