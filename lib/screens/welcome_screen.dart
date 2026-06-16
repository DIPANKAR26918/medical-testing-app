import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      image: 'assets/images/onboarding1.png',
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

            Column(
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Text(
                        'TESTIFIED',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .06),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    page.subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SmoothPageIndicator(
                  controller: _controller,
                  count: pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: const Color(0xff0E8C93),
                    dotHeight: 10,
                    dotWidth: 10,
                    expansionFactor: 3,
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: currentPage == pages.length - 1
                          ? _getStarted
                          : () {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0E8C93),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        currentPage == pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
