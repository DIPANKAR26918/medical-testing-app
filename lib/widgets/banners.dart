import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'home/home_constants.dart';

/// A calm, manually controlled care carousel inspired by the supplied home
/// reference. The prescription route opens by default and adjacent content
/// peeks into view to make the horizontal interaction discoverable.
class HomeBanner extends StatefulWidget {
  const HomeBanner({
    required this.onUploadPrescription,
    required this.onExploreTests,
    required this.onViewReports,
    super.key,
  });

  final VoidCallback onUploadPrescription;
  final VoidCallback onExploreTests;
  final VoidCallback onViewReports;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final slides = [
      _CareSlideData(
        eyebrow: 'BOOK DIRECTLY',
        title: 'Find a test by health need',
        body: 'Browse clear categories and compare the essentials first.',
        actionLabel: 'Explore tests',
        icon: Icons.biotech_outlined,
        accent: HomeColors.primary,
        background: const Color(0xFFE8F1FF),
        onTap: widget.onExploreTests,
      ),
      _CareSlideData(
        eyebrow: 'PRESCRIPTION ASSIST',
        title: 'Upload once. Review every test.',
        body: 'A verified team prepares the list; you approve it before booking.',
        actionLabel: 'Upload prescription',
        icon: Icons.note_add_outlined,
        accent: HomeColors.mint,
        background: const Color(0xFFDFF6EE),
        onTap: widget.onUploadPrescription,
      ),
      _CareSlideData(
        eyebrow: 'YOUR HEALTH RECORDS',
        title: 'Reports, ready when you are',
        body: 'Keep completed lab reports together and easy to revisit.',
        actionLabel: 'View reports',
        icon: Icons.description_outlined,
        accent: const Color(0xFF5259A8),
        background: const Color(0xFFEEF0FF),
        onTap: widget.onViewReports,
      ),
    ];

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: slides.length,
          itemBuilder: (context, index, realIndex) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CareSlide(data: slides[index]),
            );
          },
          options: CarouselOptions(
            height: 194,
            initialPage: 1,
            viewportFraction: .91,
            padEnds: false,
            enableInfiniteScroll: false,
            autoPlay: false,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, reason) {
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < slides.length; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: index == _currentIndex ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? HomeColors.primary
                      : const Color(0xFFDCE4EF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
            const Spacer(),
            Text(
              '${_currentIndex + 1} / ${slides.length}',
              style: const TextStyle(
                color: HomeColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CareSlide extends StatelessWidget {
  const _CareSlide({required this.data});

  final _CareSlideData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${data.title}. ${data.actionLabel}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 17),
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: data.accent.withValues(alpha: .12)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -42,
                  top: -52,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: data.accent.withValues(alpha: .055),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: data.accent,
                                  fontSize: 9.4,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .72,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                data.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: HomeColors.textPrimary,
                                  fontSize: 19,
                                  height: 1.13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.32,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .86),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .9),
                            ),
                          ),
                          child: Icon(data.icon, color: data.accent, size: 25),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      data.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeColors.textSecondary,
                        fontSize: 11.1,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .86),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            data.actionLabel,
                            style: TextStyle(
                              color: data.accent,
                              fontSize: 10.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: data.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CareSlideData {
  const _CareSlideData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String actionLabel;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback onTap;
}
