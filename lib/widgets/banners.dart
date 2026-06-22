import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class BannerModel {
  final String image;
  final String title;
  final String subtitle;
  final String buttonText;

  BannerModel({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });
}

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _currentIndex = 0;

  final List<BannerModel> banners = [
    BannerModel(
      image: 'assets/images/image_without_text.png',
      title: 'Know Your Health Before Symptoms Appear',
      subtitle: 'Up to 40% OFF on preventive health checkups.',
      buttonText: 'Book Now',
    ),
    BannerModel(
      image: 'assets/images/lab_image_without_text.png',
      title: 'Home Sample Collection Available',
      subtitle: 'Safe, hygienic and convenient testing at home.',
      buttonText: 'Schedule Now',
    ),
    BannerModel(
      image: 'assets/images/cbc_image_without_text.png',
      title: 'Get Reports Within 12-24 Hours',
      subtitle: 'Fast and accurate reports from trusted labs.',
      buttonText: 'Explore Tests',
    ),
    BannerModel(
      image: 'assets/images/fullbody_checkup_banner1.jpeg',
      title: 'Most Booked Health Package',
      subtitle: 'Comprehensive full body screening at discounted prices.',
      buttonText: 'View Package',
    ),
    BannerModel(
      image: 'assets/images/diabetes_screening_banner.jpeg',
      title: 'Diabetes Screening Saves Lives',
      subtitle: 'Early detection helps prevent complications.',
      buttonText: 'Book Screening',
    ),
    BannerModel(
      image: 'assets/images/quick_reports_banner.jpeg',
      title: 'Quick Reports. Better Decisions.',
      subtitle: 'Receive digital reports directly on your phone.',
      buttonText: 'Get Started',
    ),
    BannerModel(
      image: 'assets/images/join_healthplus_banner.jpeg',
      title: 'Join HealthPlus Membership',
      subtitle: 'Unlock exclusive discounts and benefits.',
      buttonText: 'Join Now',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(banner.image, fit: BoxFit.cover),

                  // Dark Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.70),
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),

                  // Text Content
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          banner.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to booking page
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xff0E8C93),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              banner.buttonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: 200,
            viewportFraction: 1,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),

        const SizedBox(height: 14),

        // Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xff0E8C93)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
