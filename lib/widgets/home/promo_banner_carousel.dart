import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'home_constants.dart';

class _BannerData {
  const _BannerData({
    required this.imagePath,
    required this.label,
  });

  final String imagePath;
  final String label;
}

class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({
    this.onBannerTap,
    super.key,
  });

  final ValueChanged<int>? onBannerTap;

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  int _currentIndex = 0;

  static const _banners = [
    _BannerData(
      imagePath: 'assets/images/testified_banner_fullbody.png',
      label: 'Full Body Checkup',
    ),
    _BannerData(
      imagePath: 'assets/images/testified_banner_cbc.png',
      label: 'Complete Blood Count',
    ),
    _BannerData(
      imagePath: 'assets/images/testified_banner_money_saving (1).png',
      label: 'Save on lab tests',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Promotional banner carousel',
          child: CarouselSlider.builder(
            itemCount: _banners.length,
            options: CarouselOptions(
              height: 180,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              enableInfiniteScroll: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
              scrollPhysics: const BouncingScrollPhysics(),
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Semantics(
                  label: 'Promotional banner: ${banner.label}',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onBannerTap != null) {
                        widget.onBannerTap!(index);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        banner.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: HomeColors.surfaceTeal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 40, color: HomeColors.textMuted),
                              const SizedBox(height: 8),
                              Text(
                                banner.label,
                                style: TextStyle(fontSize: 14, color: HomeColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Carousel indicator, page ${_currentIndex + 1} of ${_banners.length}',
          child: AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: _banners.length,
            effect: ExpandingDotsEffect(
              activeDotColor: HomeColors.primary,
              dotColor: HomeColors.border,
              dotHeight: 6,
              dotWidth: 6,
              radius: 3,
              expansionFactor: 20 / 6,
            ),
          ),
        ),
      ],
    );
  }
}
