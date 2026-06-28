import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/index.dart';

enum AuthProfileStatus { complete, incomplete, missing }

class AuthProfileResolution {
  const AuthProfileResolution({
    required this.user,
    required this.status,
    this.profile,
    this.email,
    this.phoneNumber,
    this.displayName,
  });

  final User user;
  final AuthProfileStatus status;
  final AppUser? profile;
  final String? email;
  final String? phoneNumber;
  final String? displayName;

  bool get needsProfileCompletion => status != AuthProfileStatus.complete;
}

/// Service for handling authentication with Supabase.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current logged-in user.
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user.
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get current user ID.
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Sign up with email and password.
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final cleanDisplayName = displayName.trim();

      if (normalizedEmail == null) {
        throw 'Enter a valid email address';
      }

      final AuthResponse response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': cleanDisplayName,
        },
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Failed to create user account');
      }

      await upsertUserProfile(
        userId: userId,
        email: normalizedEmail,
        fullName: cleanDisplayName,
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Sign up failed: $e';
    }
  }

  /// Sign up with phone number.
  Future<void> signUpWithPhone(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Phone sign up failed: $e';
    }
  }

  /// Send a phone OTP for sign-in or sign-up.
  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'OTP resend failed: $e';
    }
  }

  /// Start the Supabase Google OAuth PKCE flow.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  /// Verify a phone OTP and return the auth response.
  Future<AuthResponse> verifyPhoneOtpWithToken(
    String phoneNumber,
    String token,
  ) async {
    try {
      return await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Phone verification failed: $e';
    }
  }

  /// Check whether a user already has a profile row.
  Future<bool> hasExistingProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Verify phone OTP.
  Future<void> verifyPhoneOtp(String phoneNumber, String token) async {
    try {
      await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );

      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await upsertUserProfile(userId: userId, phoneNumber: phoneNumber);
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Phone verification failed: $e';
    }
  }

  /// Resolve whether the authenticated user can enter the app or must finish
  /// onboarding. This checks the users table by id first, then by email.
  Future<AuthProfileResolution> resolveCurrentAuthProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'Authentication expired. Please sign in again.';
    }

    final email = _normalizeEmail(user.email);
    final phoneNumber = _cleanText(user.phone);
    final displayName = _displayNameFromAuthUser(user);

    AppUser? profile = await getUserProfile(user.id);

    if (profile == null && email != null) {
      profile = await getUserProfileByEmail(email);
    }

    if (profile == null) {
      return AuthProfileResolution(
        user: user,
        status: AuthProfileStatus.missing,
        email: email,
        phoneNumber: phoneNumber,
        displayName: displayName,
      );
    }

    if (profile.userId.isNotEmpty && profile.userId != user.id) {
      await _supabase.auth.signOut();
      throw 'An account with this email already exists. Please sign in with the original method.';
    }

    await _syncAuthProfileFields(
      userId: user.id,
      profile: profile,
      email: email,
      phoneNumber: phoneNumber,
      displayName: displayName,
    );

    final refreshedProfile = await getUserProfile(user.id) ?? profile;

    return AuthProfileResolution(
      user: user,
      status: isUserProfileComplete(refreshedProfile)
          ? AuthProfileStatus.complete
          : AuthProfileStatus.incomplete,
      profile: refreshedProfile,
      email: refreshedProfile.email ?? email,
      phoneNumber: refreshedProfile.phoneNumber ?? phoneNumber,
      displayName: refreshedProfile.name == 'Testified user'
          ? displayName
          : refreshedProfile.name,
    );
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      if (normalizedEmail == null) {
        throw 'Enter a valid email address';
      }

      await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
    } on AuthException catch (e) {
      throw e.message;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw e.message;
    }
  }

  /// Check if user is logged in.
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Get user ID.
  String? getUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Get user profile from database.
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Get user profile from database by normalized email.
  Future<AppUser?> getUserProfileByEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return null;

    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (data == null) return null;

      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  bool isUserProfileComplete(AppUser? profile) {
    if (profile == null) return false;

    final name = profile.name.trim();
    final hasName = name.isNotEmpty && name != 'Testified user';
    final hasAge = profile.age != null && profile.age! > 0;
    final hasGender = (profile.gender ?? '').trim().isNotEmpty;

    return hasName && hasAge && hasGender;
  }

  Future<void> upsertUserProfile({
    required String userId,
    String? email,
    String? phoneNumber,
    String? fullName,
    int? age,
    String? gender,
  }) async {
    try {
      final cleanFullName = _cleanText(fullName);
      final cleanGender = _cleanText(gender);
      final profile = <String, dynamic>{'id': userId};

      final normalizedEmail = _normalizeEmail(email);
      if (normalizedEmail != null) {
        profile['email'] = normalizedEmail;
      }

      final cleanPhoneNumber = _cleanText(phoneNumber);
      if (cleanPhoneNumber != null) {
        profile['phone_number'] = cleanPhoneNumber;
      }

      if (cleanFullName != null) {
        profile['full_name'] = cleanFullName;
      }

      if (age != null) {
        profile['age'] = age;
      }

      if (cleanGender != null) {
        profile['gender'] = cleanGender;
      }

      await _supabase.from('users').upsert(profile, onConflict: 'id');
    } on PostgrestException catch (e) {
      throw 'Failed to save profile: ${e.message}';
    }
  }

  /// Update user profile.
  Future<void> updateUserProfile(String userId, String displayName) async {
    try {
      await _supabase.from('users').update({
        'full_name': displayName,
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      throw 'Failed to update profile: ${e.message}';
    }
  }

  /// Reset password.
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw e.message;
    }
  }

  /// Stream auth state changes.
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  Future<void> _syncAuthProfileFields({
    required String userId,
    required AppUser profile,
    required String? email,
    required String? phoneNumber,
    required String? displayName,
  }) async {
    final updates = <String, dynamic>{};

    if (email != null && profile.email != email) {
      updates['email'] = email;
    }

    if (phoneNumber != null && (profile.phoneNumber ?? '').trim().isEmpty) {
      updates['phone_number'] = phoneNumber;
    }

    if (displayName != null && (profile.fullName ?? '').trim().isEmpty) {
      updates['full_name'] = displayName;
    }

    if (updates.isEmpty) return;

    await _supabase.from('users').update(updates).eq('id', userId);
  }

  String? _displayNameFromAuthUser(User user) {
    final metadata = user.userMetadata ?? {};
    final metadataName = _cleanText(
      metadata['full_name'] ??
          metadata['name'] ??
          metadata['display_name'] ??
          metadata['given_name'],
    );

    if (metadataName != null) return metadataName;

    final email = _normalizeEmail(user.email);
    if (email == null) return null;

    final nameFromEmail = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ');
    return _cleanText(nameFromEmail);
  }

  static String? _normalizeEmail(String? email) {
    final cleanEmail = _cleanText(email)?.toLowerCase();
    if (cleanEmail == null || !cleanEmail.contains('@')) return null;
    return cleanEmail;
  }

  static String? _cleanText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
