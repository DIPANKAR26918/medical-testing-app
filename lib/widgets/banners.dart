import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({
    super.key,
    this.onExploreTests,
    this.onViewReports,
  });

  final VoidCallback? onExploreTests;
  final VoidCallback? onViewReports;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  static const _campaigns = <_HealthCampaign>[
    _HealthCampaign(
      eyebrow: 'PREVENTIVE CARE',
      title: 'Know more before symptoms begin',
      subtitle: 'Explore thoughtful health checks for everyday wellbeing.',
      cta: 'Explore health checks',
      accent: Color(0xFF3D7568),
      gradient: [Color(0xFFF5F8F4), Color(0xFFE5F0E9)],
      artwork: _CampaignArtwork.preventive,
      action: _CampaignAction.exploreTests,
    ),
    _HealthCampaign(
      eyebrow: 'AT-HOME COLLECTION',
      title: 'Home collection, on your schedule',
      subtitle: 'Pick an address and choose a test available for home pickup.',
      cta: 'Browse home tests',
      accent: Color(0xFF708158),
      gradient: [Color(0xFFF8F9F2), Color(0xFFE8EEDB)],
      artwork: _CampaignArtwork.homeCollection,
      action: _CampaignAction.exploreTests,
    ),
    _HealthCampaign(
      eyebrow: 'REPORTS & RECORDS',
      title: 'Every lab report, in one place',
      subtitle: 'Open completed results whenever you need them.',
      cta: 'Open my reports',
      accent: Color(0xFF706982),
      gradient: [Color(0xFFF8F6FA), Color(0xFFECE8F1)],
      artwork: _CampaignArtwork.reports,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          itemCount: _campaigns.length,
          itemBuilder: (context, index, realIndex) {
            final campaign = _campaigns[index];

            return Padding(
              padding: EdgeInsets.only(
                right: index == _campaigns.length - 1 ? 0 : 8,
              ),
              child: _CampaignCard(
                campaign: campaign,
                onTap: _callbackFor(campaign.action),
              ),
            );
          },
          options: CarouselOptions(
            height: 196,
            viewportFraction: .955,
            padEnds: false,
            autoPlay: true,
            autoPlayInterval: const Duration(milliseconds: 5200),
            autoPlayAnimationDuration: const Duration(milliseconds: 680),
            autoPlayCurve: Curves.easeOutCubic,
            pauseAutoPlayOnTouch: true,
            onPageChanged: (index, reason) {
              if (mounted) setState(() => _currentIndex = index);
            },
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            for (var index = 0; index < _campaigns.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: _currentIndex == index ? 26 : 7,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? _campaigns[_currentIndex].accent
                      : const Color(0xFFD8DFDA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            const Spacer(),
            const Icon(
              Icons.swipe_rounded,
              color: Color(0xFF8B9892),
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '${_currentIndex + 1} of ${_campaigns.length}',
              style: const TextStyle(
                color: Color(0xFF738079),
                fontSize: 10.2,
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
    return Semantics(
      button: true,
      label: '${campaign.title}. ${campaign.cta}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: campaign.gradient,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: campaign.accent.withValues(alpha: .13),
              ),
              boxShadow: [
                BoxShadow(
                  color: campaign.accent.withValues(alpha: .08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                Positioned(
                  right: -52,
                  top: -62,
                  child: Container(
                    width: 194,
                    height: 194,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .32),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 11,
                  top: 36,
                  child: _ClinicalCampaignArtwork(campaign: campaign),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 16, 116, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .66),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: campaign.accent.withValues(alpha: .10),
                          ),
                        ),
                        child: Text(
                          campaign.eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: campaign.accent,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        campaign.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172521),
                          fontSize: 19.2,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        campaign.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF586962),
                          fontSize: 11.2,
                          height: 1.38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              campaign.cta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: campaign.accent,
                                fontSize: 11.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: campaign.accent,
                            size: 17,
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
      ),
    );
  }
}

class _ClinicalCampaignArtwork extends StatelessWidget {
  const _ClinicalCampaignArtwork({required this.campaign});

  final _HealthCampaign campaign;

  @override
  Widget build(BuildContext context) {
    Widget artwork;

    switch (campaign.artwork) {
      case _CampaignArtwork.preventive:
        artwork = _PreventiveArtwork(accent: campaign.accent);
        break;
      case _CampaignArtwork.homeCollection:
        artwork = _HomeCollectionArtwork(accent: campaign.accent);
        break;
      case _CampaignArtwork.reports:
        artwork = _ReportsArtwork(accent: campaign.accent);
        break;
    }

    return SizedBox(width: 102, height: 142, child: artwork);
  }
}

class _PreventiveArtwork extends StatelessWidget {
  const _PreventiveArtwork({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _ArtworkSurface(accent: accent),
        Container(
          width: 69,
          height: 69,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .14),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(Icons.monitor_heart_rounded, color: accent, size: 35),
        ),
        Positioned(
          right: 1,
          top: 20,
          child: _ArtworkBadge(
            accent: accent,
            icon: Icons.shield_rounded,
          ),
        ),
        Positioned(
          left: 5,
          bottom: 19,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'CHECK',
              style: TextStyle(
                color: accent,
                fontSize: 7.6,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeCollectionArtwork extends StatelessWidget {
  const _HomeCollectionArtwork({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _ArtworkSurface(accent: accent),
        Container(
          width: 73,
          height: 73,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .13),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(Icons.home_rounded, color: accent, size: 39),
        ),
        Positioned(
          right: 0,
          bottom: 21,
          child: _ArtworkBadge(
            accent: accent,
            icon: Icons.vaccines_rounded,
          ),
        ),
        Positioned(
          left: 1,
          top: 23,
          child: _ArtworkBadge(
            accent: accent,
            icon: Icons.schedule_rounded,
            light: true,
          ),
        ),
      ],
    );
  }
}

class _ReportsArtwork extends StatelessWidget {
  const _ReportsArtwork({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _ArtworkSurface(accent: accent),
        Transform.rotate(
          angle: .045,
          child: Container(
            width: 69,
            height: 91,
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .14),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_rounded, color: accent, size: 17),
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .22),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                _ReportLine(accent: accent, width: 45),
                const SizedBox(height: 7),
                _ReportLine(accent: accent, width: 38),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ReportBar(accent: accent, height: 13),
                    const SizedBox(width: 4),
                    _ReportBar(accent: accent, height: 22),
                    const SizedBox(width: 4),
                    _ReportBar(accent: accent, height: 17),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 17,
          child: _ArtworkBadge(accent: accent, icon: Icons.check_rounded),
        ),
      ],
    );
  }
}

class _ArtworkSurface extends StatelessWidget {
  const _ArtworkSurface({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: .08)),
      ),
    );
  }
}

class _ArtworkBadge extends StatelessWidget {
  const _ArtworkBadge({
    required this.accent,
    required this.icon,
    this.light = false,
  });

  final Color accent;
  final IconData icon;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: light ? Colors.white : accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .16),
            blurRadius: 11,
          ),
        ],
      ),
      child: Icon(icon, color: light ? accent : Colors.white, size: 15),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.accent, required this.width});

  final Color accent;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({required this.accent, required this.height});

  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .62),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
    required this.accent,
    required this.gradient,
    required this.artwork,
    required this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final Color accent;
  final List<Color> gradient;
  final _CampaignArtwork artwork;
  final _CampaignAction action;
}

enum _CampaignArtwork { preventive, homeCollection, reports }

enum _CampaignAction { exploreTests, viewReports }
