import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';

/// Authentication screen for login/signup
class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Handle email authentication
  Future<void> _handleEmailAuth() async {
    setState(() => _errorMessage = null);

    String email = _emailController.text.trim();
    String password = _passwordController.text;

    // Validation
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = LocalizationKeys.pleaseFillAllFields.tr());
      return;
    }

    String? emailError = Validators.validateEmail(email);
    String? passwordError = Validators.validatePassword(password);

    if (emailError != null || passwordError != null) {
      setState(() => _errorMessage = emailError ?? passwordError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _authService.signInWithEmail(email, password);
      } else {
        String name = _nameController.text.trim();
        if (name.isEmpty) {
          setState(
            () => _errorMessage = LocalizationKeys.pleaseEnterYourName.tr(),
          );
          setState(() => _isLoading = false);
          return;
        }
        await _authService.signUpWithEmail(email, password, name);
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'wrong-password':
          message = LocalizationKeys.wrongPassword.tr();
          break;

        case 'user-not-found':
          message = LocalizationKeys.userNotFound.tr();
          break;

        case 'invalid-email':
          message = LocalizationKeys.invalidEmail.tr();
          break;

        case 'too-many-requests':
          message = LocalizationKeys.tooManyRequests.tr();
          break;

        default:
          message = e.message ?? LocalizationKeys.error.tr();
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle phone authentication
  Future<void> _handlePhoneAuth() async {
    setState(() => _errorMessage = null);

    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(
        () => _errorMessage = LocalizationKeys.pleaseEnterPhoneNumber.tr(),
      );
      return;
    }

    String? phoneError = Validators.validatePhoneNumber(phone);
    if (phoneError != null) {
      setState(() => _errorMessage = phoneError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // For demo, just do anonymous sign in
        await _authService.signInAnonymously();
      } else {
        await _authService.signUpWithPhone(phone);
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isLoginMode ? 'login'.tr() : 'sign_up'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: AppTheme.paddingMedium),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
              child: const Icon(
                Icons.medical_services,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.paddingLarge),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusLarge,
                  ),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ),
            if (_errorMessage != null)
              const SizedBox(height: AppTheme.paddingMedium),

            // Name field (signup only)
            if (!_isLoginMode)
              Column(
                children: [
                  FloatingLabelTextField(
                    controller: _nameController,
                    label: LocalizationKeys.fullName.tr(),
                    hint: LocalizationKeys.fullNameHint.tr(),
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                ],
              ),

            // Email field
            FloatingLabelTextField(
              controller: _emailController,
              label: LocalizationKeys.email.tr(),
              hint: LocalizationKeys.email.tr(),
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Password field
            FloatingLabelTextField(
              controller: _passwordController,
              label: LocalizationKeys.password.tr(),
              hint: LocalizationKeys.password.tr(),
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: AppTheme.paddingLarge),

            // Email Auth Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailAuth,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isLoginMode
                          ? LocalizationKeys.login.tr()
                          : LocalizationKeys.signUp.tr(),
                    ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppTheme.borderColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingSmall,
                  ),
                  child: Text(
                    LocalizationKeys.or.tr(),
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppTheme.borderColor),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Phone Auth Button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handlePhoneAuth,
              icon: const Icon(Icons.phone),
              label: Text(
                _isLoginMode
                    ? '${'login'.tr()} ${'phone'.tr()}'
                    : '${'sign_up'.tr()} ${'phone'.tr()}',
              ),
            ),
            const SizedBox(height: AppTheme.paddingLarge),

            // Toggle mode
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLoginMode
                      ? LocalizationKeys.dontHaveAnAccount.tr()
                      : LocalizationKeys.alreadyHaveAnAccount.tr(),
                  style: const TextStyle(color: AppTheme.textLight),
                ),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() => _isLoginMode = !_isLoginMode);
                          _errorMessage = null;
                        },
                  child: Text(
                    _isLoginMode
                        ? LocalizationKeys.signUp.tr()
                        : LocalizationKeys.login.tr(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
