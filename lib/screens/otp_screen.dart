import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../services/auth_service.dart';
import 'complete_profile_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  final Color _primaryTeal = const Color(0xFF0F5D65);
  final Color _buttonColor = const Color(0xFF167A84);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.sendPhoneOtp(widget.phoneNumber);

      _startTimer();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent again')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter 6 digit OTP')));
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final authResponse = await _authService.verifyPhoneOtpWithToken(
        widget.phoneNumber,
        _otpController.text.trim(),
      );

      final user = authResponse.user ?? _authService.currentUser;

      if (user == null) {
        throw Exception('Authentication failed. User not found.');
      }

      final existingUser = await _authService.hasExistingProfile(user.id);

      if (!mounted) return;

      if (existingUser) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 54,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E5E7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryTeal, width: 2),
        boxShadow: [
          BoxShadow(
            color: _primaryTeal.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDCDD), width: 1.2),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFC),
      body: Stack(
        children: [
          _buildBackgroundWatermark(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: _primaryTeal.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 40,
                      color: _primaryTeal,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "TESTIFIED",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE6F0F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Verify Your Phone Number",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "We sent a 6 digit verification code to",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F8F8),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE0ECEC)),
                          ),
                          child: Text(
                            widget.phoneNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Pinput(
                          controller: _otpController,
                          length: 6,
                          enabled: !_isLoading,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: submittedPinTheme,
                          keyboardType: TextInputType.number,
                          showCursor: true,
                          cursor: Container(
                            width: 2,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _primaryTeal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonColor,
                              elevation: 3,
                              shadowColor: _buttonColor.withValues(alpha: 0.28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              disabledBackgroundColor: _buttonColor.withValues(
                                alpha: 0.55,
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Verify OTP",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        _secondsRemaining > 0
                            ? Text(
                                "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: _primaryTeal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              )
                            : TextButton(
                                onPressed: _isLoading ? null : _resendOtp,
                                child: Text(
                                  "Resend Code",
                                  style: TextStyle(
                                    color: _primaryTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundWatermark() {
    return Stack(
      children: [
        Positioned(
          top: 160,
          left: 20,
          child: Opacity(
            opacity: 0.06,
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: _primaryTeal,
            ),
          ),
        ),
        Positioned(
          top: 340,
          right: 18,
          child: Opacity(
            opacity: 0.06,
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 96,
              color: _primaryTeal,
            ),
          ),
        ),
        Positioned(
          top: 560,
          left: 36,
          child: Opacity(
            opacity: 0.06,
            child: Icon(Icons.science_outlined, size: 86, color: _primaryTeal),
          ),
        ),
      ],
    );
  }
}
