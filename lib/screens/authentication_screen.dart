import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      await _authService.signInWithGoogle();
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Indian mobile number')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final fullPhoneNumber = '+91$phone';
      await _authService.sendPhoneOtp(fullPhoneNumber);

      if (!mounted) return;

      Navigator.pushNamed(context, '/otp', arguments: fullPhoneNumber);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'TESTIFIED',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: const Color(0xFF0B2538),
                      ),
                    ),
                  ),
                  const SizedBox(height: 72),
                  const Text(
                    'Enter your phone number',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B2538),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We will send a 6 digit code to verify your account.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPhoneField(),
                  const SizedBox(height: 14),
                  const Text(
                    'Standard SMS charges may apply.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GoogleLogo(size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      enabled: !_isLoading,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _sendOtp(),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: const InputDecoration(
        labelText: 'Phone number',
        prefixText: '+91 ',
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    Paint fill(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(23.49, 12.27)
        ..relativeCubicTo(0, -.79, -.07, -1.54, -.19, -2.27)
        ..lineTo(12, 10)
        ..lineTo(12, 14.51)
        ..lineTo(18.47, 14.51)
        ..relativeCubicTo(-.29, 1.48, -1.14, 2.73, -2.4, 3.58)
        ..lineTo(16.07, 21.07)
        ..lineTo(19.96, 21.07)
        ..relativeCubicTo(2.27, -2.09, 3.58, -5.17, 3.58, -8.8)
        ..close(),
      fill(const Color(0xFF4285F4)),
    );

    canvas.drawPath(
      Path()
        ..moveTo(12, 24)
        ..relativeCubicTo(3.24, 0, 5.95, -1.08, 7.93, -2.93)
        ..relativeLineTo(-3.89, -2.98)
        ..relativeCubicTo(-1.08, .72, -2.45, 1.15, -4.04, 1.15)
        ..relativeCubicTo(-3.1, 0, -5.73, -2.09, -6.67, -4.9)
        ..lineTo(1.3, 14.34)
        ..lineTo(1.3, 17.41)
        ..cubicTo(3.27, 21.3, 7.3, 24, 12, 24)
        ..close(),
      fill(const Color(0xFF34A853)),
    );

    canvas.drawPath(
      Path()
        ..moveTo(5.33, 14.34)
        ..relativeCubicTo(-.24, -.72, -.38, -1.49, -.38, -2.34)
        ..cubicTo(4.95, 11.15, 5.09, 10.38, 5.33, 9.66)
        ..lineTo(5.33, 6.59)
        ..lineTo(1.3, 6.59)
        ..cubicTo(.47, 8.24, 0, 10.07, 0, 12)
        ..cubicTo(0, 13.93, .47, 15.76, 1.3, 17.41)
        ..relativeLineTo(4.03, -3.07)
        ..close(),
      fill(const Color(0xFFFBBC05)),
    );

    canvas.drawPath(
      Path()
        ..moveTo(12, 4.75)
        ..relativeCubicTo(1.77, 0, 3.35, .61, 4.61, 1.8)
        ..relativeLineTo(3.44, -3.44)
        ..cubicTo(17.95, 1.16, 15.24, 0, 12, 0)
        ..cubicTo(7.3, 0, 3.27, 2.7, 1.3, 6.59)
        ..relativeLineTo(4.03, 3.07)
        ..relativeCubicTo(.94, -2.81, 3.57, -4.91, 6.67, -4.91)
        ..close(),
      fill(const Color(0xFFEA4335)),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
