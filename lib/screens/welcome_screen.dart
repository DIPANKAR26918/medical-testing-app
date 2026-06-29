import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'complete_profile_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  final AuthService _authService = AuthService();

  Timer? _slideTimer;
  int currentPage = 0;
  bool _isRouting = false;

  final pages = const [
    OnboardingPage(
      eyebrow: 'At your doorstep',
      title: 'Book health tests without the waiting room.',
      subtitle:
          'Schedule sample collection from home and keep the whole process simple.',
    ),
    OnboardingPage(
      eyebrow: 'Handled carefully',
      title: 'Samples go to trusted diagnostic labs.',
      subtitle:
          'Every test is processed with the checks you expect from a reliable lab.',
    ),
    OnboardingPage(
      eyebrow: 'Easy to access',
      title: 'Reports stay organized in one place.',
      subtitle: 'View results, bookings, and records whenever you need them.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startSlideTimer();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startSlideTimer() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _showNextSlide(),
    );
  }

  void _showNextSlide() {
    if (!mounted || _isRouting || !_controller.hasClients) return;

    final nextPage = (currentPage + 1) % pages.length;
    _controller.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _getStarted() async {
    if (_isRouting) return;

    _slideTimer?.cancel();
    setState(() => _isRouting = true);

    final user = _authService.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    try {
      final profile = await _authService.getUserProfile(user.id);

      if (!mounted) return;

      if (profile == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              phoneNumber: user.phone,
              email: user.email,
              initialName: _nameFromCurrentUser(),
            ),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      Navigator.pushReplacementNamed(context, '/auth');
    } finally {
      if (mounted) {
        setState(() => _isRouting = false);
      }
    }
  }

  String? _nameFromCurrentUser() {
    final metadata = _authService.currentUser?.userMetadata ?? {};
    final name =
        metadata['full_name'] ?? metadata['name'] ?? metadata['given_name'];
    final text = name?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (value) {
                        setState(() => currentPage = value);
                        _startSlideTimer();
                      },
                      itemBuilder: (_, index) {
                        return _AnimatedSlide(
                          controller: _controller,
                          index: index,
                          page: pages[index],
                        );
                      },
                    ),
                  ),
                  _ProgressBars(
                    currentPage: currentPage,
                    pageCount: pages.length,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Swipe to read. Continue anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRouting ? null : _getStarted,
                      child: _isRouting
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'TESTIFIED',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: const Color(0xFF0B2538),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Diagnostics, made calmer.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AnimatedSlide extends StatelessWidget {
  const _AnimatedSlide({
    required this.controller,
    required this.index,
    required this.page,
  });

  final PageController controller;
  final int index;
  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var pageOffset = 0.0;

        if (controller.hasClients) {
          pageOffset =
              (controller.page ?? controller.initialPage.toDouble()) - index;
        } else {
          pageOffset = controller.initialPage.toDouble() - index;
        }

        final distance = pageOffset.abs().clamp(0.0, 1.0).toDouble();
        final opacity = 1 - (distance * .36);
        final verticalOffset = 20 * distance;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, verticalOffset),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              page.eyebrow,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF087E86),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                height: 1.08,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B2538),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.55,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 3,
            margin: EdgeInsets.only(right: index == pageCount - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF087E86)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class OnboardingPage {
  final String eyebrow;
  final String title;
  final String subtitle;

  const OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
}
