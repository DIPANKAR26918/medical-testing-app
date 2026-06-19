import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();

  int currentPage = 0;

  final pages = const [
    OnboardingPage(
      image: 'assets/images/onboardingImageEnhanced.png',
      title: 'Home Sample Collection',
      subtitle:
          'Certified healthcare professionals collect blood, urine and other samples right at your doorstep.',
    ),
    OnboardingPage(
      image: 'assets/images/onboarding2.png',
      title: 'Trusted Laboratory Analysis',
      subtitle:
          'Every sample is processed in accredited labs with strict quality and safety standards.',
    ),
    OnboardingPage(
      image: 'assets/images/onboarding3.png',
      title: 'Reports Delivered',
      subtitle:
          'Receive accurate reports digitally and access them anytime from the app.',
    ),
  ];

  void _getStarted() {
    final user = Supabase.instance.client.auth.currentUser;

    Navigator.pushReplacementNamed(context, user != null ? '/home' : '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7FCFC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xff0E8C93).withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xff0E8C93).withValues(alpha: .06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: 20,
              child: Icon(
                Icons.favorite,
                size: 40,
                color: const Color(0xff0E8C93).withValues(alpha: .05),
              ),
            ),

            Positioned(
              bottom: 250,
              right: 30,
              child: Icon(
                Icons.biotech,
                size: 50,
                color: const Color(0xff0E8C93).withValues(alpha: .05),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'TESTIFIED',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: const Color(0xFF16353D),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _getStarted,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (value) {
                      setState(() {
                        currentPage = value;
                      });
                    },
                    itemBuilder: (_, index) {
                      final page = pages[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),

                            Expanded(
                              child: Hero(
                                tag: page.image,
                                child: Image.asset(
                                  page.image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .95),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .04),
                                    blurRadius: 40,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF16353D),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    page.subtitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _trustChip(Icons.verified_user, "Secure"),
                    _trustChip(Icons.biotech, "NABL Labs"),
                    _trustChip(Icons.health_and_safety, "Certified"),
                  ],
                ),

                const SizedBox(height: 22),

                SmoothPageIndicator(
                  controller: _controller,
                  count: pages.length,
                  effect: WormEffect(
                    activeDotColor: const Color(0xff0E8C93),
                    dotColor: Colors.grey.shade300,
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 10,
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: currentPage == pages.length - 1
                            ? _getStarted
                            : () {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff10A2AB), Color(0xff0B7D86)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff0E8C93,
                                ).withValues(alpha: .25),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              currentPage == pages.length - 1
                                  ? 'Get Started'
                                  : 'Next →',
                              style: GoogleFonts.manrope(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xff0E8C93).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xff0E8C93)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String image;
  final String title;
  final String subtitle;

  const OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
