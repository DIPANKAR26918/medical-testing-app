import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_theme.dart';

class DeleteAccountOtpScreen extends StatefulWidget {
  const DeleteAccountOtpScreen({
    required this.expectedUserId,
    required this.phoneNumber,
    required this.onDeleteAccount,
    super.key,
  });

  final String expectedUserId;
  final String phoneNumber;
  final Future<bool> Function() onDeleteAccount;

  @override
  State<DeleteAccountOtpScreen> createState() => _DeleteAccountOtpScreenState();
}

class _DeleteAccountOtpScreenState extends State<DeleteAccountOtpScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _hasSentCode = false;
  String? _errorMessage;

  bool get _isBusy => _isSending || _isVerifying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendCode();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendCode({bool isResend = false}) async {
    if (_isBusy) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null || currentUser.id != widget.expectedUserId) {
        throw StateError(
          'Your session changed. Return to Profile and try again.',
        );
      }

      final authPhone = _normalizePhone(currentUser.phone ?? '');
      final targetPhone = _normalizePhone(widget.phoneNumber);

      if (authPhone.isEmpty || authPhone != targetPhone) {
        throw StateError(
          'Account deletion requires the verified phone on this account.',
        );
      }

      await _supabase.auth.signInWithOtp(
        phone: targetPhone,
        shouldCreateUser: false,
      );

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _hasSentCode = true;
        _secondsRemaining = 60;
      });

      _startTimer();
      _otpFocusNode.requestFocus();

      if (isResend) {
        _showMessage('A new deletion verification code was sent.');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _hasSentCode = false;
        _secondsRemaining = 0;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _verifyAndDelete() async {
    final token = _otpController.text.trim();

    if (!_hasSentCode || _isBusy) return;

    if (token.length != 6) {
      _showMessage('Enter the 6 digit verification code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: _normalizePhone(widget.phoneNumber),
        token: token,
        type: OtpType.sms,
      );

      final verifiedUser = response.user ?? _supabase.auth.currentUser;

      if (verifiedUser == null || verifiedUser.id != widget.expectedUserId) {
        await _supabase.auth.signOut();
        throw StateError(
          'The verification session does not match this account.',
        );
      }

      final deleted = await widget.onDeleteAccount();

      if (!deleted && mounted) {
        setState(() => _isVerifying = false);
      }
    } catch (error) {
      if (!mounted) return;

      _otpController.clear();
      setState(() {
        _isVerifying = false;
        _errorMessage = _friendlyError(error);
      });
      _otpFocusNode.requestFocus();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 44,
      height: 54,
      textStyle: const TextStyle(
        color: _OtpPalette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: AppTheme.fontFamily,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OtpPalette.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OtpPalette.danger, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OtpPalette.danger.withValues(alpha: .45)),
      ),
    );

    return Scaffold(
      backgroundColor: _OtpPalette.background,
      appBar: AppBar(
        backgroundColor: _OtpPalette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: _OtpPalette.ink),
        ),
        title: const Text(
          'Confirm account deletion',
          style: TextStyle(
            color: _OtpPalette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.15,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: _OtpPalette.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify before deletion',
                  style: TextStyle(
                    color: _OtpPalette.ink,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'We sent a 6 digit security code to ${_maskedPhone(widget.phoneNumber)} to confirm permanent account deletion.',
                  style: const TextStyle(
                    color: _OtpPalette.muted,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD9DC)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: _OtpPalette.danger,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This code approves account deletion. Never share it with anyone.',
                          style: TextStyle(
                            color: _OtpPalette.ink,
                            fontSize: 12.8,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Pinput(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    length: 6,
                    enabled: _hasSentCode && !_isBusy,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: defaultPinTheme,
                    errorPinTheme: errorPinTheme,
                    forceErrorState: _errorMessage != null,
                    keyboardType: TextInputType.number,
                    separatorBuilder: (_) => const SizedBox(width: 6),
                    showCursor: true,
                    onCompleted: (_) => _verifyAndDelete(),
                    cursor: Container(
                      width: 2,
                      height: 21,
                      decoration: BoxDecoration(
                        color: _OtpPalette.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: _OtpPalette.danger,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _hasSentCode && !_isBusy
                        ? _verifyAndDelete
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _OtpPalette.danger,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _OtpPalette.danger.withValues(
                        alpha: .35,
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    child: _isVerifying
                        ? const _BusyButtonLabel(
                            label: 'Verifying and deleting…',
                          )
                        : _isSending
                        ? const _BusyButtonLabel(label: 'Sending code…')
                        : const Text('Verify and delete account'),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: _OtpPalette.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => _sendCode(isResend: true),
                          child: Text(
                            _hasSentCode
                                ? 'Resend deletion code'
                                : 'Send code again',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _normalizePhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s()-]'), '');
  }

  static String _maskedPhone(String value) {
    final clean = _normalizePhone(value);
    if (clean.length <= 4) return clean;

    final suffix = clean.substring(clean.length - 4);
    final prefix = clean.startsWith('+91') ? '+91' : '';

    return prefix.isEmpty ? '••••••$suffix' : '$prefix ••••• $suffix';
  }

  static String _friendlyError(Object error) {
    final message = error
        .toString()
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceAll(RegExp(r', statusCode:.*$'), '')
        .replaceAll(RegExp(r'\)$'), '')
        .trim();

    return message.isEmpty
        ? 'Verification failed. Request a new code and try again.'
        : message;
  }
}

class _BusyButtonLabel extends StatelessWidget {
  const _BusyButtonLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _OtpPalette {
  const _OtpPalette._();

  static const Color background = Color(0xFFFAFBFC);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color danger = Color(0xFFDC2626);
}
