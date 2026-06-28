import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';

///import 'package:google_sign_in/google_sign_in.dart';

// import '../services/index.dart'; // Uncomment if using your service

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  // Controllers
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  // State
  bool _isLoading = false;

  // Colors from your design
  final Color _primaryTeal = const Color(0xFF087E86);
  ///final Color _accentTeal = const Color(0xFFE0F2F1); // Light background teal

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.signInWithGoogle();
    } catch (e) {
      debugPrint(e.toString());
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

  Future<void> _sendOtp() async {
    try {
      setState(() {
        _isLoading = true;
      });

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
        setState(() {
          _isLoading = false;
        });
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
      backgroundColor: const Color(0xFFF7FAFC),
      body: Stack(
        children: [
          // 1. Background Medical Watermarks (Faded Icons)
          _buildBackgroundWatermark(),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _primaryTeal.withValues(alpha: .22),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.science_outlined,
                        size: 40,
                        color: _primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "TESTIFIED",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tests you need, care you trust.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Phone Number Field
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      icon: Icons.phone_outlined, // Changed to phone icon
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 24),

                    // Main Action Button (Log In / Sign Up)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _sendOtp, // Add your auth logic here
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryTeal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Continue",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("OR"),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Google Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 20,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for input fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),

          prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),

          prefix: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              '+91',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _primaryTeal, width: 1.5),
          ),

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  ///Builds the faded medical icons in the background
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
