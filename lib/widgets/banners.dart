import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key, this.onBannerTap});

  final VoidCallback? onBannerTap;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  static const _campaigns = <_HealthCampaign>[
    _HealthCampaign(
      eyebrow: 'SMART PREVENTIVE CARE',
      title: 'Know more before symptoms begin',
      subtitle: 'Curated full-body checks with home collection.',
      cta: 'Explore checkups',
      icon: Icons.monitor_heart_rounded,
      accent: Color(0xFF124FC4),
      gradient: [Color(0xFFE2EEFF), Color(0xFFBFD8FF)],
    ),
    _HealthCampaign(
      eyebrow: 'PRESCRIPTION ASSIST',
      title: 'Upload once. Review every test.',
      subtitle: 'A verified team prepares the list; you approve it.',
      cta: 'Upload prescription',
      icon: Icons.fact_check_rounded,
      accent: Color(0xFF086B58),
      gradient: [Color(0xFFDFF8EF), Color(0xFFBDECDC)],
    ),
    _HealthCampaign(
      eyebrow: 'HOME COLLECTION',
      title: 'Your address, your collection window',
      subtitle: 'Save locations and choose the right pickup point.',
      cta: 'Check availability',
      icon: Icons.home_health_rounded,
      accent: Color(0xFF9B3D0B),
      gradient: [Color(0xFFFFEBDD), Color(0xFFFFD4B7)],
    ),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          itemCount: _campaigns.length,
          itemBuilder: (context, index, realIndex) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == _campaigns.length - 1 ? 0 : 8,
              ),
              child: _CampaignCard(
                campaign: _campaigns[index],
                onTap: widget.onBannerTap,
              ),
            );
          },
          options: CarouselOptions(
            height: 190,
            viewportFraction: .96,
            padEnds: false,
            autoPlay: true,
            autoPlayInterval: const Duration(milliseconds: 4600),
            autoPlayAnimationDuration: const Duration(milliseconds: 620),
            autoPlayCurve: Curves.easeOutCubic,
            pauseAutoPlayOnTouch: true,
            onPageChanged: (index, reason) {
              if (mounted) setState(() => _currentIndex = index);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var index = 0; index < _campaigns.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                width: _currentIndex == index ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? _campaigns[index].accent
                      : const Color(0xFFD7DEE9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            const Spacer(),
            Text(
              '${_currentIndex + 1}/${_campaigns.length}',
              style: const TextStyle(
                color: Color(0xFF7C8AA3),
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

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onTap});

  final _HealthCampaign campaign;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: campaign.gradient,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: campaign.accent.withValues(alpha: .14)),
            boxShadow: [
              BoxShadow(
                color: campaign.accent.withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              Positioned(
                right: -32,
                top: -48,
                child: Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .27),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 17,
                top: 27,
                child: _CampaignIllustration(campaign: campaign),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 128, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: campaign.accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      campaign.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .72),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              campaign.cta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: campaign.accent,
                                fontSize: 9.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: campaign.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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

class _CampaignIllustration extends StatelessWidget {
  const _CampaignIllustration({required this.campaign});

  final _HealthCampaign campaign;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 5,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .70),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .80),
                  width: 2,
                ),
              ),
              child: Icon(campaign.icon, color: campaign.accent, size: 43),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: campaign.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: campaign.accent.withValues(alpha: .25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCampaign {
  const _HealthCampaign({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.accent,
    required this.gradient,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Color accent;
  final List<Color> gradient;
}
