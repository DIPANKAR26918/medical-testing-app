import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../widgets/banners.dart';
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 118),
      children: [
        const _HomeHeader(),
        const SizedBox(height: 14),
        _SearchField(onTap: onSearch),
        const SizedBox(height: 14),
        HomeBanner(onBannerTap: onBookTest),
        const SizedBox(height: 18),
        _BookingHero(
          onBookTest: onBookTest,
          onUploadPrescription: onUploadPrescription,
        ),
        const SizedBox(height: 10),
        const _TrustStrip(),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Book by concern',
          action: 'All',
          onTap: onViewCategories,
        ),
        const SizedBox(height: 10),
        _ConcernRail(onTap: onViewCategories),
        const SizedBox(height: 18),
        _ValueOfferCard(onTap: onViewCategories),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Popular lab tests',
          action: 'See all',
          onTap: onViewCategories,
        ),
        const SizedBox(height: 10),
        _PopularTests(onAdd: onBookTest),
        const SizedBox(height: 20),
        _PrescriptionCard(onTap: onUploadPrescription),
        const SizedBox(height: 18),
        const _HomeCollectionSteps(),
        const SizedBox(height: 18),
        _ReportsShortcut(onTap: onViewReports),
      ],
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
      return 'there';
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
        const SizedBox(height: 16),
        FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final firstName = _firstName(snapshot.data);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Affordable lab tests, collected safely from home.',
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _HomePalette.border),
            boxShadow: _softShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: _HomePalette.teal, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search CBC, thyroid, full body checkup',
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

class _BookingHero extends StatelessWidget {
  const _BookingHero({
    required this.onBookTest,
    required this.onUploadPrescription,
  });

  final VoidCallback onBookTest;
  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
      decoration: BoxDecoration(
        color: _HomePalette.mint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _HomePalette.mintBorder),
        boxShadow: [
          BoxShadow(
            color: _HomePalette.teal.withValues(alpha: .10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _OfferPill(text: 'Home collection included'),
                    const SizedBox(height: 12),
                    const Text(
                      'Book lab tests at home from Rs 79',
                      style: TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 23,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Certified labs, trained sample collection, secure online reports.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 12.8,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/lab_tests_at_home_image.png',
                  width: 96,
                  height: 108,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _HeroFact(icon: Icons.savings_rounded, text: 'Low cost'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _HeroFact(
                  icon: Icons.health_and_safety_rounded,
                  text: 'NABL labs',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _HeroFact(
                  icon: Icons.schedule_rounded,
                  text: 'Fast reports',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onBookTest,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Book a test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _HomePalette.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: onUploadPrescription,
                    icon: const Icon(Icons.upload_file_rounded, size: 19),
                    label: const Text('Upload Rx'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _HomePalette.teal,
                      side: const BorderSide(color: _HomePalette.mintBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _surfaceDecoration(shadow: false),
      child: const Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_rounded,
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

  static const concerns = [
    _ConcernData(Icons.bloodtype_rounded, 'Blood test', _HomePalette.red),
    _ConcernData(Icons.monitor_heart_rounded, 'Full body', _HomePalette.blue),
    _ConcernData(Icons.water_drop_rounded, 'Diabetes', _HomePalette.teal),
    _ConcernData(Icons.bolt_rounded, 'Thyroid', _HomePalette.amber),
    _ConcernData(Icons.female_rounded, 'Women care', _HomePalette.coral),
    _ConcernData(Icons.elderly_rounded, 'Senior care', _HomePalette.green),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: concerns.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = concerns[index];
          return _ConcernTile(data: item, onTap: onTap);
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
    return SizedBox(
      width: 90,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: _surfaceDecoration(shadow: false),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 11.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
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

class _ValueOfferCard extends StatelessWidget {
  const _ValueOfferCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF8F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCFEAEA)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full body checkup',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 16,
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
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Text(
                          'From Rs 999',
                          style: TextStyle(
                            color: _HomePalette.teal,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        _SmallBadge(text: 'Save 50%'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .68),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/premium_full_body_checkup.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularTests extends StatelessWidget {
  const _PopularTests({required this.onAdd});

  final VoidCallback onAdd;

  static const tests = [
    _TestData(
      title: 'CBC Complete Blood Count',
      detail: '21 tests',
      reportTime: 'Reports in 6 hrs',
      price: 'Rs 319',
      mrp: 'Rs 350',
      discount: '9% off',
    ),
    _TestData(
      title: 'Fasting Blood Sugar',
      detail: '1 test',
      reportTime: 'Reports in 6 hrs',
      price: 'Rs 79',
      mrp: 'Rs 120',
      discount: '34% off',
    ),
    _TestData(
      title: 'Thyroid Profile Total',
      detail: 'T3, T4, TSH',
      reportTime: 'Reports in 6 hrs',
      price: 'Rs 399',
      mrp: 'Rs 550',
      discount: '27% off',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < tests.length; index++) ...[
          _TestCard(data: tests[index], onAdd: onAdd),
          if (index != tests.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.data, required this.onAdd});

  final _TestData data;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _surfaceDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _HomePalette.teal.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: _HomePalette.teal,
              size: 22,
            ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.detail} | ${data.reportTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      data.price,
                      style: const TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.mrp,
                      style: const TextStyle(
                        color: _HomePalette.slate,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SmallBadge(text: data.discount),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: _HomePalette.teal,
                side: const BorderSide(color: _HomePalette.teal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _surfaceDecoration(shadow: false),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _HomePalette.coral.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: _HomePalette.coral,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload prescription',
                      style: TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We will help match the right lab tests.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _HomePalette.slate,
                size: 24,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(shadow: false),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How home collection works',
            style: TextStyle(
              color: _HomePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StepItem(
                  icon: Icons.checklist_rounded,
                  title: 'Choose',
                  subtitle: 'Pick tests',
                ),
              ),
              _StepLine(),
              Expanded(
                child: _StepItem(
                  icon: Icons.home_rounded,
                  title: 'Collect',
                  subtitle: 'At home',
                ),
              ),
              _StepLine(),
              Expanded(
                child: _StepItem(
                  icon: Icons.description_rounded,
                  title: 'Reports',
                  subtitle: 'On app',
                ),
              ),
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
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
      label: const Text('View your reports'),
      style: TextButton.styleFrom(
        foregroundColor: _HomePalette.teal,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
            foregroundColor: _HomePalette.teal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _HomePalette.mintBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _HomePalette.teal, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomePalette.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPill extends StatelessWidget {
  const _OfferPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _HomePalette.teal.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _HomePalette.teal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _HomePalette.green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _HomePalette.green,
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
        Icon(icon, color: _HomePalette.teal, size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomePalette.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _HomePalette.border,
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _HomePalette.teal.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _HomePalette.teal, size: 20),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _HomePalette.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _HomePalette.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 1,
      margin: const EdgeInsets.only(bottom: 34),
      color: _HomePalette.border,
    );
  }
}

class _ConcernData {
  const _ConcernData(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}

class _TestData {
  const _TestData({
    required this.title,
    required this.detail,
    required this.reportTime,
    required this.price,
    required this.mrp,
    required this.discount,
  });

  final String title;
  final String detail;
  final String reportTime;
  final String price;
  final String mrp;
  final String discount;
}

class _HomePalette {
  const _HomePalette._();

  static const Color mint = Color(0xFFE9FBF7);
  static const Color mintBorder = Color(0xFFBCEDE7);
  static const Color ink = Color(0xFF12343B);
  static const Color muted = Color(0xFF64748B);
  static const Color slate = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color teal = Color(0xFF0E9FA6);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF18A77D);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEA580C);
  static const Color red = Color(0xFFDC2626);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 8)),
];

BoxDecoration _surfaceDecoration({bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _HomePalette.border),
    boxShadow: shadow ? _softShadow : null,
  );
}
