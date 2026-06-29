import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class BannerModel {
  const BannerModel({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.offer,
    required this.buttonText,
    required this.accentColor,
    required this.softColor,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String offer;
  final String buttonText;
  final Color accentColor;
  final Color softColor;
}

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key, this.onBannerTap});

  final VoidCallback? onBannerTap;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  static const _ink = Color(0xFF12343B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  int _currentIndex = 0;

  final List<BannerModel> banners = const [
    BannerModel(
      image: 'assets/images/image_without_text.png',
      eyebrow: 'PREVENTIVE HEALTH DEAL',
      title: 'Full body screening',
      subtitle: '60+ essential checks with home collection.',
      offer: 'UP TO 40% OFF',
      buttonText: 'Book now',
      accentColor: Color(0xFF2563EB),
      softColor: Color(0xFFEFF6FF),
    ),
    BannerModel(
      image: 'assets/images/lab_image_without_text.png',
      eyebrow: 'AT-HOME COLLECTION',
      title: 'Lab tests from home',
      subtitle: 'Safe sample pickup by trained collectors.',
      offer: 'SLOTS TODAY',
      buttonText: 'Schedule',
      accentColor: Color(0xFF0E9FA6),
      softColor: Color(0xFFE9FBF7),
    ),
    BannerModel(
      image: 'assets/images/cbc_image_without_text.png',
      eyebrow: 'MOST BOOKED',
      title: 'CBC test package',
      subtitle: 'Accurate reports from trusted partner labs.',
      offer: 'FROM RS 319',
      buttonText: 'Explore',
      accentColor: Color(0xFFEA580C),
      softColor: Color(0xFFFFF7ED),
    ),
    BannerModel(
      image: 'assets/images/premium_full_body_checkup.png',
      eyebrow: 'BEST VALUE',
      title: 'Premium checkup',
      subtitle: 'Comprehensive screening at member pricing.',
      offer: 'SAVE 50%',
      buttonText: 'View deal',
      accentColor: Color(0xFF18A77D),
      softColor: Color(0xFFF0FDF4),
    ),
    BannerModel(
      image: 'assets/images/diabetes_screening_banner.jpeg',
      eyebrow: 'SMART SCREENING',
      title: 'Diabetes care tests',
      subtitle: 'Early detection for better health decisions.',
      offer: 'LOW COST',
      buttonText: 'Book test',
      accentColor: Color(0xFF4F46E5),
      softColor: Color(0xFFF5F3FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            return _PremiumBannerCard(
              banner: banners[index],
              onTap: widget.onBannerTap,
            );
          },
          options: CarouselOptions(
            height: 176,
            viewportFraction: 1,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 420),
            autoPlayCurve: Curves.easeOutCubic,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? banners[_currentIndex].accentColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumBannerCard extends StatelessWidget {
  const _PremiumBannerCard({required this.banner, required this.onTap});

  final BannerModel banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, banner.softColor],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _HomeBannerState._border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -22,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 156,
                  decoration: BoxDecoration(
                    color: banner.accentColor.withValues(alpha: .08),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(120),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 18,
                bottom: 18,
                child: Container(
                  width: 116,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .86),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: banner.accentColor.withValues(alpha: .16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(banner.image, fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 138,
                top: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DealRibbon(
                      label: banner.eyebrow,
                      color: banner.accentColor,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeBannerState._ink,
                        fontSize: 19,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      banner.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeBannerState._muted,
                        fontSize: 12.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: _OfferTag(
                            text: banner.offer,
                            color: banner.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BannerButton(
                          text: banner.buttonText,
                          color: banner.accentColor,
                          onTap: onTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DealRibbon extends StatelessWidget {
  const _DealRibbon({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _OfferTag extends StatelessWidget {
  const _OfferTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(text),
      ),
    );
  }
}
