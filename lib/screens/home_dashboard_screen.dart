import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../widgets/location_card.dart';
import '../widgets/notification_button.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.onBookTest,
    required this.onViewReports,
    required this.onUploadPrescription,
    required this.onSearch,
    required this.onViewCategories,
    super.key,
  });

  final VoidCallback onBookTest;
  final VoidCallback onViewReports;
  final VoidCallback onUploadPrescription;
  final VoidCallback onSearch;
  final VoidCallback onViewCategories;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _HomePalette.background,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 166),
        children: [
          const _HomeHeader(),
          const SizedBox(height: 16),
          _PremiumSearchCard(onTap: onSearch),
          const SizedBox(height: 14),
          _HeroCard(onBookTest: onBookTest, onViewCategories: onViewCategories),
          const SizedBox(height: 12),
          const _TrustStrip(),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Book by concern',
            action: 'View all',
            onTap: onViewCategories,
          ),
          const SizedBox(height: 10),
          _ConcernRail(onTap: onViewCategories),
          const SizedBox(height: 18),
          _ValueOfferCard(onTap: onViewCategories),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Popular tests',
            action: 'See all',
            onTap: onViewCategories,
          ),
          const SizedBox(height: 10),
          _PopularTestsList(
            onAddTest: onBookTest,
            onViewPackage: onViewCategories,
          ),
          const SizedBox(height: 18),
          _PrescriptionHelperCard(onTap: onUploadPrescription),
          const SizedBox(height: 18),
          const _HomeCollectionSteps(),
          const SizedBox(height: 18),
          _ReportsShortcut(onTap: onViewReports),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  final AuthService _authService = AuthService();
  late final Future<AppUser?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AppUser?> _loadProfile() async {
    final userId = _authService.getCurrentUserId();
    if (userId == null) return null;
    return _authService.getUserProfile(userId);
  }

  String _firstName(AppUser? profile) {
    final name = profile?.name.trim();
    if (name == null || name.isEmpty || name == 'Testified user') {
      return '';
    }

    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: LocationCard()),
            const SizedBox(width: 10),
            NotificationButton(unreadCount: 2, onTap: () {}),
          ],
        ),
        const SizedBox(height: 15),
        FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final firstName = _firstName(snapshot.data);
            final greeting = firstName.isEmpty
                ? 'Home lab testing made simple'
                : 'Hi $firstName';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Trusted lab tests at home, reports delivered securely.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomePalette.muted,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PremiumSearchCard extends StatelessWidget {
  const _PremiumSearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomePalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _HomePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomePalette.border),
            boxShadow: _softShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: _HomePalette.primary, size: 24),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Search CBC, thyroid, liver, full body checkup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomePalette.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onBookTest, required this.onViewCategories});

  final VoidCallback onBookTest;
  final VoidCallback onViewCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_HomePalette.navy, _HomePalette.primary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _HomePalette.navy.withValues(alpha: .20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -52,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: -72,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _HomePalette.coral.withValues(alpha: .18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showImage = constraints.maxWidth >= 315;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _HeroBadge(),
                          const SizedBox(height: 14),
                          const Text(
                            'Book lab tests from home',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Certified partner labs, trained sample collection, secure digital reports.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _HomePalette.heroTextMuted,
                              fontSize: 13.2,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Flexible(
                                child: _HeroActionButton(
                                  label: 'Book',
                                  icon: Icons.event_available_rounded,
                                  filled: true,
                                  onTap: onBookTest,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _HeroActionButton(
                                  label: 'Packages',
                                  icon: Icons.biotech_rounded,
                                  filled: false,
                                  onTap: onViewCategories,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showImage) ...[
                      const SizedBox(width: 12),
                      const _HeroImageShell(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: _HomePalette.success, size: 15),
          SizedBox(width: 5),
          Text(
            'Certified collection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImageShell extends StatelessWidget {
  const _HeroImageShell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 142,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .55)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Image.asset(
          'assets/images/lab_tests_at_home_image.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(
              color: _HomePalette.primarySoft,
              child: Icon(
                Icons.science_rounded,
                color: _HomePalette.primary,
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: _surfaceDecoration(radius: 20, shadow: false),
      child: const Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_user_rounded,
              label: 'Certified labs',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.clean_hands_rounded,
              label: 'Sterile kits',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(icon: Icons.lock_rounded, label: 'Private data'),
          ),
        ],
      ),
    );
  }
}

class _ConcernRail extends StatelessWidget {
  const _ConcernRail({required this.onTap});

  final VoidCallback onTap;

  static const _items = [
    _ConcernData(
      title: 'Blood test',
      subtitle: 'CBC, fever',
      icon: Icons.bloodtype_rounded,
      color: _HomePalette.blood,
      tint: Color(0xFFFFF1F2),
    ),
    _ConcernData(
      title: 'Full body',
      subtitle: '60+ tests',
      icon: Icons.monitor_heart_rounded,
      color: _HomePalette.primary,
      tint: _HomePalette.primarySoft,
    ),
    _ConcernData(
      title: 'Diabetes',
      subtitle: 'HbA1c, sugar',
      icon: Icons.water_drop_rounded,
      color: _HomePalette.diabetes,
      tint: Color(0xFFECFDFD),
    ),
    _ConcernData(
      title: 'Thyroid',
      subtitle: 'T3, T4, TSH',
      icon: Icons.bolt_rounded,
      color: _HomePalette.violet,
      tint: Color(0xFFF5F3FF),
    ),
    _ConcernData(
      title: 'Women care',
      subtitle: 'Hormones',
      icon: Icons.female_rounded,
      color: _HomePalette.coral,
      tint: _HomePalette.coralSoft,
    ),
    _ConcernData(
      title: 'Senior care',
      subtitle: 'Heart, kidney',
      icon: Icons.elderly_rounded,
      color: _HomePalette.purple,
      tint: Color(0xFFF3E8FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _ConcernTile(data: _items[index], onTap: onTap);
        },
      ),
    );
  }
}

class _ConcernTile extends StatelessWidget {
  const _ConcernTile({required this.data, required this.onTap});

  final _ConcernData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.tint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 124,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: data.tint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: data.color.withValues(alpha: .12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 21),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.ink,
                  fontSize: 13.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueOfferCard extends StatelessWidget {
  const _ValueOfferCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_HomePalette.coralSoft, Color(0xFFFFF7ED)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color(0xFFFED7AA)),
            boxShadow: _softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _OfferBadge(text: 'Save 50%'),
                    const SizedBox(height: 10),
                    const Text(
                      'Full body checkup',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '60+ essential tests with free home collection.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 12.8,
                        height: 1.34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'From Rs 999',
                          style: TextStyle(
                            color: _HomePalette.navy,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _FilledMiniButton(
                          label: 'View',
                          color: _HomePalette.coral,
                          onPressed: onTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: _HomePalette.coral,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularTestsList extends StatelessWidget {
  const _PopularTestsList({
    required this.onAddTest,
    required this.onViewPackage,
  });

  final VoidCallback onAddTest;
  final VoidCallback onViewPackage;

  static const _items = [
    _TestItemData(
      title: 'CBC Complete Blood Count',
      detail: '21 tests',
      meta: 'Reports in 6 hrs',
      price: 'Rs 319',
      mrp: 'Rs 350',
      discount: '9% off',
      button: 'Add',
      icon: Icons.bloodtype_rounded,
      color: _HomePalette.blood,
      isPackage: false,
    ),
    _TestItemData(
      title: 'Thyroid Profile Total',
      detail: 'T3, T4, TSH',
      meta: 'Reports in 6 hrs',
      price: 'Rs 399',
      mrp: 'Rs 550',
      discount: '27% off',
      button: 'Add',
      icon: Icons.bolt_rounded,
      color: _HomePalette.violet,
      isPackage: false,
    ),
    _TestItemData(
      title: 'Full Body Health Checkup',
      detail: '60+ essential tests',
      meta: 'Home sample pickup',
      price: 'Rs 999',
      mrp: 'Rs 1999',
      discount: '50% off',
      button: 'View',
      icon: Icons.monitor_heart_rounded,
      color: _HomePalette.primary,
      isPackage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _items.length; index++) ...[
          _TestItemCard(
            data: _items[index],
            onTap: _items[index].isPackage ? onViewPackage : onAddTest,
          ),
          if (index != _items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TestItemCard extends StatelessWidget {
  const _TestItemCard({required this.data, required this.onTap});

  final _TestItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actionColor = data.isPackage
        ? _HomePalette.primary
        : _HomePalette.coral;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.detail} | ${data.meta}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      data.price,
                      style: const TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      data.mrp,
                      style: const TextStyle(
                        color: _HomePalette.weak,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: _HomePalette.weak,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _DiscountBadge(text: data.discount),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: actionColor,
                side: BorderSide(color: actionColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(data.button),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionHelperCard extends StatelessWidget {
  const _PrescriptionHelperCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomePalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _HomePalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _HomePalette.border),
            boxShadow: _softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _HomePalette.coralSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: _HomePalette.coral,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecommendedBadge(),
                    SizedBox(height: 7),
                    Text(
                      'Upload prescription',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'We\'ll match the right tests for you.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 12.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FilledMiniButton(
                label: 'Upload',
                color: _HomePalette.coral,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCollectionSteps extends StatelessWidget {
  const _HomeCollectionSteps();

  static const _steps = [
    _StepData(
      title: 'Choose',
      subtitle: 'Pick tests',
      icon: Icons.search_rounded,
      color: _HomePalette.primary,
    ),
    _StepData(
      title: 'Collect',
      subtitle: 'Home visit',
      icon: Icons.home_work_rounded,
      color: _HomePalette.coral,
    ),
    _StepData(
      title: 'Reports',
      subtitle: 'Secure app',
      icon: Icons.assignment_turned_in_rounded,
      color: _HomePalette.violet,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _surfaceDecoration(radius: 22, shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Home collection steps',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _HomePalette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StepCard(data: _steps[0])),
              const _StepLine(),
              Expanded(child: _StepCard(data: _steps[1])),
              const _StepLine(),
              Expanded(child: _StepCard(data: _steps[2])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsShortcut extends StatelessWidget {
  const _ReportsShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomePalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F3FF)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _HomePalette.border),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: _HomePalette.violet,
                size: 23,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'View secure reports',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _HomePalette.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomePalette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: _HomePalette.primary,
            minimumSize: const Size(44, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return SizedBox(
      height: 42,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: _HomePalette.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .46)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class _FilledMiniButton extends StatelessWidget {
  const _FilledMiniButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _HomePalette.warning,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _HomePalette.coral,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _HomePalette.coralSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Recommended',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _HomePalette.coral,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _HomePalette.success, size: 16),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomePalette.ink,
              fontSize: 10.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.data});

  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withValues(alpha: .12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: data.color, size: 21),
          const SizedBox(height: 7),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _HomePalette.ink,
              fontSize: 11.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _HomePalette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: _HomePalette.border,
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _HomePalette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ConcernData {
  const _ConcernData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _TestItemData {
  const _TestItemData({
    required this.title,
    required this.detail,
    required this.meta,
    required this.price,
    required this.mrp,
    required this.discount,
    required this.button,
    required this.icon,
    required this.color,
    required this.isPackage,
  });

  final String title;
  final String detail;
  final String meta;
  final String price;
  final String mrp;
  final String discount;
  final String button;
  final IconData icon;
  final Color color;
  final bool isPackage;
}

class _StepData {
  const _StepData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _HomePalette {
  const _HomePalette._();

  static const Color background = Color(0xFFFFFBF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color weak = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE5E7EB);
  static const Color primary = Color(0xFF1D4ED8);
  static const Color navy = Color(0xFF172554);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color coral = Color(0xFFF97316);
  static const Color coralSoft = Color(0xFFFFF1E7);
  static const Color heroTextMuted = Color(0xFFDCEBFF);
  static const Color success = Color(0xFF16A34A);
  static const Color blood = Color(0xFFE11D48);
  static const Color diabetes = Color(0xFF0891B2);
  static const Color violet = Color(0xFF4F46E5);
  static const Color purple = Color(0xFF7C3AED);
  static const Color warning = Color(0xFFD97706);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0A172554), blurRadius: 22, offset: Offset(0, 10)),
];

BoxDecoration _surfaceDecoration({
  double radius = 20,
  bool shadow = true,
  Color color = _HomePalette.surface,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _HomePalette.border),
    boxShadow: shadow ? _softShadow : null,
  );
}
