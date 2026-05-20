import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';

/// Service for handling authentication with Supabase
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Create user account with Supabase Auth
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Failed to create user account');
      }

      // Create user profile in public.users table
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'সাইন আপ ব্যর্থ হয়েছে: $e';
    }
  }

  /// Sign up with phone number
  Future<void> signUpWithPhone(String phoneNumber) async {
    try {
      // Verify phone number first
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'ফোন সাইন আপ ব্যর্থ হয়েছে: $e';
    }
  }

  /// Verify phone OTP
  Future<void> verifyPhoneOtp(String phoneNumber, String token) async {
    try {
      await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );

      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        // Create user profile
        await _supabase.from('users').insert({
          'id': userId,
          'phone_number': phoneNumber,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'ফোন যাচাইকরণ ব্যর্থ হয়েছে: $e';
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw e.message;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw e.message;
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Get user ID
  String? getUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Get user profile from database
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return AppUser(
        userId: data['id'] ?? '',
        email: data['email'],
        phoneNumber: data['phone_number'],
        displayName: data['display_name'],
        createdAt: DateTime.parse(
          data['created_at'] ?? DateTime.now().toIso8601String(),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, String displayName) async {
    try {
      await _supabase
          .from('users')
          .update({'display_name': displayName})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw 'Failed to update profile: ${e.message}';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw e.message;
    }
  }

  /// Stream auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}
