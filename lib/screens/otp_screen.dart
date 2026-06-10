import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/painters.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Using 4 separate controllers for the square boxes
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp(String phone) async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 4) return;

    try {
      setState(() => _isLoading = true);

      // Standard SMS verification for Twilio
      await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      // Note: Navigation to Home is handled by the listener in main.dart
    } on AuthException catch (e) {
      // Fallback for new signups if 'sms' type isn't sufficient in your config
      try {
        await Supabase.instance.client.auth.verifyOTP(
          phone: phone,
          token: otp,
          type: OtpType.signup,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve phone number passed from Login or Register
    final phone = ModalRoute.of(context)!.settings.arguments as String;
    final primaryTeal = const Color(0xFF04727B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Polished Teal Header Section
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(),
                  const Spacer(),
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // 2. Input Section with Background Painter
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: WelcomeBackgroundPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Code sent to $phone',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF10242B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Row of 4 Square OTP Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => _buildOtpBox(index, primaryTeal),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _ResendTimer(
                        seconds: _secondsRemaining,
                        teal: primaryTeal,
                      ),

                      const Spacer(),

                      // Large Verify Button
                      _PrimaryButton(
                        label: 'Verify',
                        onPressed: _isLoading ? null : () => _verifyOtp(phone),
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index, Color activeColor) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? activeColor
              : const Color(0xFFBDD8D7),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}

// --- Internal Helper Widgets ---

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'Verify OTP',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ResendTimer extends StatelessWidget {
  const _ResendTimer({required this.seconds, required this.teal});
  final int seconds;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    String time = seconds < 10 ? '00:0$seconds' : '00:$seconds';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Resend OTP in ',
          style: TextStyle(color: Color(0xFF10242B)),
        ),
        Text(
          time,
          style: TextStyle(
            color: teal,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF04727B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
