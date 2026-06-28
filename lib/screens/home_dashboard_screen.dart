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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 118),
      children: [
        const _HomeHeader(),
        const SizedBox(height: 14),
        _ClinicalSearchBar(onTap: onSearch),
        const SizedBox(height: 16),
        _HeroPanel(
          onBookTest: onBookTest,
          onUploadPrescription: onUploadPrescription,
        ),
        const SizedBox(height: 14),
        const _HealthSnapshot(),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Quick care',
          action: 'All services',
          onTap: onViewCategories,
        ),
        const SizedBox(height: 10),
        _PrimaryActions(
          onBookTest: onBookTest,
          onViewReports: onViewReports,
          onUploadPrescription: onUploadPrescription,
          onViewCategories: onViewCategories,
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Recommended for you',
          action: 'View all',
          onTap: onViewCategories,
        ),
        const SizedBox(height: 10),
        const _CheckupList(),
        const SizedBox(height: 18),
        const _MembershipCard(),
        const SizedBox(height: 18),
        const _CareSummary(),
        const SizedBox(height: 18),
        const _TrustedCareStrip(),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Health essentials',
          action: 'Explore',
          onTap: onViewCategories,
        ),
        const SizedBox(height: 10),
        const _EssentialsGrid(),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<AppUser?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final firstName = _firstName(snapshot.data);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()}, $firstName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _HomePalette.ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your health dashboard is ready for today.',
                        style: TextStyle(
                          color: _HomePalette.muted,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _HomePalette.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle_rounded,
                    color: _HomePalette.teal,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Self',
                    style: TextStyle(
                      color: _HomePalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClinicalSearchBar extends StatelessWidget {
  const _ClinicalSearchBar({required this.onTap});

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
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _HomePalette.border),
            boxShadow: _softShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: _HomePalette.teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search tests, packages, symptoms',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomePalette.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.tune_rounded, color: _HomePalette.slate, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.onBookTest,
    required this.onUploadPrescription,
  });

  final VoidCallback onBookTest;
  final VoidCallback onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomePalette.deep,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _HomePalette.deep.withValues(alpha: .18),
            blurRadius: 24,
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
                    const _Pill(label: 'Premium diagnostics'),
                    const SizedBox(height: 12),
                    const Text(
                      'At-home lab care with verified clinical partners.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Book tests, upload prescriptions, and track reports from one private care space.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 13,
                        height: 1.35,
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
                  width: 104,
                  height: 128,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _HeroMetric(value: '45 min', label: 'slot pickup'),
              ),
              SizedBox(width: 8),
              Expanded(child: _HeroMetric(value: '6 hr', label: 'quick report')),
              SizedBox(width: 8),
              Expanded(child: _HeroMetric(value: '4.8', label: 'lab rating')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroButton(label: 'Book test', onTap: onBookTest),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroGhostButton(
                  label: 'Upload Rx',
                  onTap: onUploadPrescription,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthSnapshot extends StatelessWidget {
  const _HealthSnapshot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Health snapshot',
                  style: TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(label: 'Updated today', color: _HomePalette.teal),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _ScoreRing(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _SnapshotLine(
                      label: 'CBC markers',
                      value: 'Normal',
                      color: _HomePalette.green,
                    ),
                    SizedBox(height: 10),
                    _SnapshotLine(
                      label: 'Vitamin D',
                      value: 'Review',
                      color: _HomePalette.amber,
                    ),
                    SizedBox(height: 10),
                    _SnapshotLine(
                      label: 'Next test',
                      value: 'Today',
                      color: _HomePalette.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({
    required this.onBookTest,
    required this.onViewReports,
    required this.onUploadPrescription,
    required this.onViewCategories,
  });

  final VoidCallback onBookTest;
  final VoidCallback onViewReports;
  final VoidCallback onUploadPrescription;
  final VoidCallback onViewCategories;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.78,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ActionTile(
          icon: Icons.biotech_rounded,
          title: 'Book lab test',
          subtitle: 'Home or lab visit',
          color: _HomePalette.teal,
          onTap: onBookTest,
        ),
        _ActionTile(
          icon: Icons.medication_rounded,
          title: 'Upload Rx',
          subtitle: 'We suggest tests',
          color: _HomePalette.coral,
          onTap: onUploadPrescription,
        ),
        _ActionTile(
          icon: Icons.description_rounded,
          title: 'View reports',
          subtitle: 'Secure records',
          color: _HomePalette.blue,
          onTap: onViewReports,
        ),
        _ActionTile(
          icon: Icons.family_restroom_rounded,
          title: 'Family care',
          subtitle: 'Profiles and history',
          color: _HomePalette.green,
          onTap: onViewCategories,
        ),
      ],
    );
  }
}

class _CheckupList extends StatelessWidget {
  const _CheckupList();

  static const items = [
    _CheckupData(
      title: 'Complete Blood Count',
      subtitle: '42 parameters',
      price: 'Rs 349',
      tag: 'Popular',
      color: _HomePalette.teal,
    ),
    _CheckupData(
      title: 'Diabetes Care',
      subtitle: 'HbA1c + glucose',
      price: 'Rs 499',
      tag: 'Fasting',
      color: _HomePalette.blue,
    ),
    _CheckupData(
      title: 'Full Body Wellness',
      subtitle: '82 parameters',
      price: 'Rs 999',
      tag: 'Best value',
      color: _HomePalette.green,
    ),
    _CheckupData(
      title: 'Thyroid Profile',
      subtitle: 'T3, T4, TSH',
      price: 'Rs 399',
      tag: 'Quick',
      color: _HomePalette.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 178,
            child: _CheckupCard(data: item),
          );
        },
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: _softShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/premium_health_plus.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Testified Plus',
                  style: TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Priority slots, free home collection, and member pricing.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8A5A10),
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    _MiniBenefit(text: '20% off'),
                    SizedBox(width: 8),
                    _MiniBenefit(text: 'Priority'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: Color(0xFFB45309)),
        ],
      ),
    );
  }
}

class _CareSummary extends StatelessWidget {
  const _CareSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: _HomePalette.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Care timeline',
                  style: TextStyle(
                    color: _HomePalette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(label: '2 active', color: _HomePalette.blue),
            ],
          ),
          const SizedBox(height: 14),
          _TimelineItem(
            title: 'CBC sample collection',
            subtitle: 'Today, 7:30 PM - Phlebotomist assigned',
            status: 'Confirmed',
            color: _HomePalette.teal,
          ),
          const SizedBox(height: 12),
          _TimelineItem(
            title: 'Thyroid report review',
            subtitle: 'Tomorrow, 10:00 AM - Care desk follow-up',
            status: 'Pending',
            color: _HomePalette.amber,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: _HomePalette.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Care coordinator available for booking or report questions.',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustedCareStrip extends StatelessWidget {
  const _TrustedCareStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: const [
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_rounded,
              label: 'NABL labs',
              color: _HomePalette.teal,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.clean_hands_rounded,
              label: 'Sterile kits',
              color: _HomePalette.green,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.lock_rounded,
              label: 'Private data',
              color: _HomePalette.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialsGrid extends StatelessWidget {
  const _EssentialsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.75,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _EssentialTile(icon: Icons.favorite_rounded, label: 'Heart health'),
        _EssentialTile(icon: Icons.water_drop_rounded, label: 'Blood tests'),
        _EssentialTile(icon: Icons.monitor_heart_rounded, label: 'Vitals'),
        _EssentialTile(icon: Icons.coronavirus_rounded, label: 'Fever panel'),
        _EssentialTile(icon: Icons.female_rounded, label: 'Women care'),
        _EssentialTile(icon: Icons.elderly_rounded, label: 'Senior care'),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 11.5,
                      ),
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

class _CheckupCard extends StatelessWidget {
  const _CheckupCard({required this.data});

  final _CheckupData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.science_rounded, color: data.color, size: 22),
              ),
              const Spacer(),
              _StatusChip(label: data.tag, color: data.color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomePalette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _HomePalette.muted, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                data.price,
                style: TextStyle(
                  color: data.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, size: 18, color: data.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: .78,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: _HomePalette.teal,
              strokeCap: StrokeCap.round,
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '78',
                style: TextStyle(
                  color: _HomePalette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Score',
                style: TextStyle(
                  color: _HomePalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotLine extends StatelessWidget {
  const _SnapshotLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomePalette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StatusChip(label: value, color: color),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusChip(label: status, color: color),
      ],
    );
  }
}

class _EssentialTile extends StatelessWidget {
  const _EssentialTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: _HomePalette.teal, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomePalette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _HomePalette.deep,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _HeroGhostButton extends StatelessWidget {
  const _HeroGhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: .36)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniBenefit extends StatelessWidget {
  const _MiniBenefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _HomePalette.ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
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
      height: 44,
      color: _HomePalette.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

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
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CheckupData {
  const _CheckupData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.tag,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String price;
  final String tag;
  final Color color;
}

class _HomePalette {
  const _HomePalette._();

  static const Color deep = Color(0xFF063B4C);
  static const Color ink = Color(0xFF0B2538);
  static const Color muted = Color(0xFF64748B);
  static const Color slate = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color teal = Color(0xFF087E86);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF0F766E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEA580C);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Color(0x09000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
];

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _HomePalette.border),
    boxShadow: _softShadow,
  );
}
