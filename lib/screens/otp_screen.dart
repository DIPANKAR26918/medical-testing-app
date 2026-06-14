import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  final Color _primaryTeal = const Color(0xFF0F5D65);

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
      await Supabase.instance.client.auth.signInWithOtp(
        phone: widget.phoneNumber,
      );

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
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter 6 digit OTP')));
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await Supabase.instance.client.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified successfully')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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
      width: 55,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundWatermark(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _primaryTeal, width: 2),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 40,
                      color: _primaryTeal,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "TESTIFIED",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 50),

                  const Text(
                    "Verify Your Phone Number",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "We sent a 6 digit verification code to",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Pinput(
                    controller: _otpController,
                    length: 6,
                    enabled: !_isLoading,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: _primaryTeal, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Verify OTP",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _secondsRemaining > 0
                      ? Text(
                          "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.grey.shade600),
                        )
                      : TextButton(
                          onPressed: _resendOtp,
                          child: Text(
                            "Resend Code",
                            style: TextStyle(
                              color: _primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
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
          top: 450,
          left: 40,
          child: Opacity(
            opacity: 0.08,
            child: Icon(Icons.science_outlined, size: 80, color: _primaryTeal),
          ),
        ),
        Positioned(
          top: 550,
          right: 30,
          child: Opacity(
            opacity: 0.08,
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 100,
              color: _primaryTeal,
            ),
          ),
        ),
        Positioned(
          top: 150,
          left: 60,
          child: Opacity(
            opacity: 0.08,
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 60,
              color: _primaryTeal,
            ),
          ),
        ),
      ],
    );
  }
}
