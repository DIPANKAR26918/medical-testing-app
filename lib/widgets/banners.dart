import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key, this.onExploreTests, this.onViewReports});

  final VoidCallback? onExploreTests;
  final VoidCallback? onViewReports;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  static const _campaigns = <_HealthCampaign>[
    _HealthCampaign(
      title: 'Stay ahead with routine health checks',
      subtitle:
          'Explore tests designed for preventive care and everyday wellbeing.',
      cta: 'Explore tests',
      icon: Icons.monitor_heart_rounded,
      action: _CampaignAction.exploreTests,
    ),
    _HealthCampaign(
      title: 'Home collection that fits your day',
      subtitle:
          'Choose an available test, address and convenient collection slot.',
      cta: 'Browse home tests',
      icon: Icons.home_work_rounded,
      action: _CampaignAction.exploreTests,
    ),
    _HealthCampaign(
      title: 'Your completed reports, kept together',
      subtitle: 'Open previous lab results whenever you need them.',
      cta: 'View reports',
      icon: Icons.description_rounded,
      action: _CampaignAction.viewReports,
    ),
  ];

  int _currentIndex = 0;

  VoidCallback? _callbackFor(_CampaignAction action) {
    switch (action) {
      case _CampaignAction.exploreTests:
        return widget.onExploreTests;
      case _CampaignAction.viewReports:
        return widget.onViewReports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _campaigns.length,
          itemBuilder: (context, index, realIndex) {
            final campaign = _campaigns[index];
            return Padding(
              padding: EdgeInsets.only(
                right: index == _campaigns.length - 1 ? 0 : 10,
              ),
              child: _CampaignCard(
                campaign: campaign,
                onTap: _callbackFor(campaign.action),
              ),
            );
          },
          options: CarouselOptions(
            height: 164,
            viewportFraction: .96,
            padEnds: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            autoPlayAnimationDuration: const Duration(milliseconds: 520),
            autoPlayCurve: Curves.easeOutCubic,
            pauseAutoPlayOnTouch: true,
            onPageChanged: (index, reason) {
              if (mounted) setState(() => _currentIndex = index);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < _campaigns.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _currentIndex == index ? 24 : 7,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? _BannerPalette.primary
                      : _BannerPalette.indicator,
                  borderRadius: BorderRadius.circular(99),
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
    return Semantics(
      button: true,
      label: '${campaign.title}. ${campaign.cta}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _BannerPalette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x07111B30),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _BannerPalette.ink,
                          fontSize: 18,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        campaign.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _BannerPalette.muted,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            campaign.cta,
                            style: const TextStyle(
                              color: _BannerPalette.primary,
                              fontSize: 12.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: _BannerPalette.primary,
                            size: 17,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _BannerPalette.primarySoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    campaign.icon,
                    color: _BannerPalette.primary,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthCampaign {
  const _HealthCampaign({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.action,
  });

  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final _CampaignAction action;
}

enum _CampaignAction { exploreTests, viewReports }

class _BannerPalette {
  const _BannerPalette._();

  static const Color ink = Color(0xFF121528);
  static const Color muted = Color(0xFF71819A);
  static const Color primary = Color(0xFF2F67F5);
  static const Color primarySoft = Color(0xFFEAF2FF);
  static const Color border = Color(0xFFE1E8F1);
  static const Color indicator = Color(0xFFD8E0EB);
}
