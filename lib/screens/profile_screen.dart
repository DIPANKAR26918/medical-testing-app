import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/index.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<AppUser?> _profileFuture;

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

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
    await _profileFuture;
  }

  void _showAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _ProfilePalette.teal,
      onRefresh: _refreshProfile,
      child: FutureBuilder<AppUser?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              const _ProfileTopBar(),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _ProfileLoadingCard()
              else if (profile == null)
                _MissingProfileCard(onRetry: _refreshProfile)
              else ...[
                _AccountIdentityCard(
                  profile: profile,
                  onEdit: () => _showAction('Profile editing will open here'),
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(onAction: _showAction),
                const SizedBox(height: 14),
                _CarePassCard(
                  onTap: () => _showAction('Care benefits will open here'),
                ),
                const SizedBox(height: 14),
                _HealthProfileCard(profile: profile),
                const SizedBox(height: 14),
                _FamilyCareCard(
                  profile: profile,
                  onTap: () => _showAction('Family profiles will open here'),
                ),
              ],
              const SizedBox(height: 14),
              _SettingsCard(onLogout: widget.onLogout, onAction: _showAction),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My account',
          style: TextStyle(
            color: _ProfilePalette.ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Your tests, reports, addresses, and family care in one trusted place.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _ProfilePalette.muted,
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AccountIdentityCard extends StatelessWidget {
  const _AccountIdentityCard({required this.profile, required this.onEdit});

  final AppUser profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _ProfilePalette.teal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _ProfilePalette.teal.withValues(alpha: .18),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                    color: _ProfilePalette.teal,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ProfilePalette.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _VerifiedDot(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.phoneNumber ??
                          profile.email ??
                          'No contact added',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfilePalette.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('Edit profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ProfilePalette.teal,
                          side: const BorderSide(color: _ProfilePalette.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _AccountStat(value: '2', label: 'Bookings'),
              ),
              _ThinDivider(),
              Expanded(
                child: _AccountStat(value: '3', label: 'Reports'),
              ),
              _ThinDivider(),
              Expanded(
                child: _AccountStat(value: '1', label: 'Family'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.event_available_rounded,
        label: 'Bookings',
        color: _ProfilePalette.teal,
        message: 'Bookings will open here',
      ),
      _ActionData(
        icon: Icons.assignment_rounded,
        label: 'Reports',
        color: _ProfilePalette.blue,
        message: 'Reports will open here',
      ),
      _ActionData(
        icon: Icons.home_work_rounded,
        label: 'Addresses',
        color: _ProfilePalette.green,
        message: 'Saved addresses will open here',
      ),
      _ActionData(
        icon: Icons.family_restroom_rounded,
        label: 'Family',
        color: _ProfilePalette.coral,
        message: 'Family profiles will open here',
      ),
      _ActionData(
        icon: Icons.local_offer_rounded,
        label: 'Offers',
        color: _ProfilePalette.amber,
        message: 'Offers will open here',
      ),
      _ActionData(
        icon: Icons.support_agent_rounded,
        label: 'Help',
        color: _ProfilePalette.indigo,
        message: 'Help center will open here',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _surfaceDecoration(shadow: false),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.04,
        children: [
          for (final action in actions)
            _QuickActionTile(
              data: action,
              onTap: () => onAction(action.message),
            ),
        ],
      ),
    );
  }
}

class _CarePassCard extends StatelessWidget {
  const _CarePassCard({required this.onTap});

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
          child: const Row(
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: _ProfilePalette.teal,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testified care benefits',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ProfilePalette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Low-cost tests, home collection, and secure reports.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ProfilePalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _ProfilePalette.teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthProfileCard extends StatelessWidget {
  const _HealthProfileCard({required this.profile});

  final AppUser profile;

  int get _completedCount {
    var count = 0;
    if (profile.name.trim().isNotEmpty && profile.name != 'Testified user') {
      count++;
    }
    if (profile.age != null && profile.age! > 0) count++;
    if ((profile.gender ?? '').trim().isNotEmpty) count++;
    if ((profile.phoneNumber ?? profile.email ?? '').trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final count = _completedCount;
    final progress = count / 4;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Health profile',
                  style: TextStyle(
                    color: _ProfilePalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(text: '$count/4 complete'),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              color: _ProfilePalette.teal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.cake_rounded,
                  label: 'Age',
                  value: profile.age == null ? 'Not added' : '${profile.age}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailTile(
                  icon: Icons.wc_rounded,
                  label: 'Gender',
                  value: profile.gender ?? 'Not added',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: profile.phoneNumber ?? 'Not added',
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.email_rounded,
            label: 'Email',
            value: profile.email ?? 'Not added',
          ),
        ],
      ),
    );
  }
}

class _FamilyCareCard extends StatelessWidget {
  const _FamilyCareCard({required this.profile, required this.onTap});

  final AppUser profile;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Family care',
                style: TextStyle(
                  color: _ProfilePalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _FamilyMember(
                name: profile.name,
                relation: 'Self',
                initials: profile.initials,
              ),
              const Divider(height: 22, color: _ProfilePalette.border),
              const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: _ProfilePalette.teal,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add parents, spouse, or children for faster repeat bookings.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ProfilePalette.muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _ProfilePalette.slate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onLogout, required this.onAction});

  final VoidCallback onLogout;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _surfaceDecoration(shadow: false),
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.shield_rounded,
            title: 'Privacy and security',
            subtitle: 'Reports, OTP, and data controls',
            onTap: () => onAction('Privacy controls will open here'),
          ),
          const Divider(height: 1, color: _ProfilePalette.border),
          _SettingRow(
            icon: Icons.payments_rounded,
            title: 'Payments and coupons',
            subtitle: 'Invoices, offers, and saved benefits',
            onTap: () => onAction('Payments and coupons will open here'),
          ),
          const Divider(height: 1, color: _ProfilePalette.border),
          _SettingRow(
            icon: Icons.medical_information_rounded,
            title: 'Health records access',
            subtitle: 'Control who can view reports',
            onTap: () => onAction('Health records access will open here'),
          ),
          const Divider(height: 1, color: _ProfilePalette.border),
          _SettingRow(
            icon: Icons.support_agent_rounded,
            title: 'Help center',
            subtitle: 'Support for bookings and reports',
            onTap: () => onAction('Help center will open here'),
          ),
          const Divider(height: 1, color: _ProfilePalette.border),
          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: _ProfilePalette.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: _ProfilePalette.red,
                fontWeight: FontWeight.w900,
              ),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoadingLine(widthFactor: .72),
                SizedBox(height: 8),
                _LoadingLine(widthFactor: .46),
                SizedBox(height: 8),
                _LoadingLine(widthFactor: .34),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingProfileCard extends StatelessWidget {
  const _MissingProfileCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _ProfilePalette.teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile not found',
                  style: TextStyle(
                    color: _ProfilePalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'We could not load your saved profile details from Supabase.',
            style: TextStyle(color: _ProfilePalette.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ProfilePalette.teal,
              side: const BorderSide(color: _ProfilePalette.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.data, required this.onTap});

  final _ActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ProfilePalette.border),
          ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ProfilePalette.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ProfilePalette.teal, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _ProfilePalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfilePalette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _ProfilePalette.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _ProfilePalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfilePalette.ink,
                    fontWeight: FontWeight.w900,
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

class _FamilyMember extends StatelessWidget {
  const _FamilyMember({
    required this.name,
    required this.relation,
    required this.initials,
  });

  final String name;
  final String relation;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE8F6F6),
          child: Text(
            initials,
            style: const TextStyle(
              color: _ProfilePalette.teal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProfilePalette.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                relation,
                style: const TextStyle(
                  color: _ProfilePalette.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const _StatusChip(text: 'Default'),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _ProfilePalette.teal),
      title: Text(
        title,
        style: const TextStyle(
          color: _ProfilePalette.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _VerifiedDot extends StatelessWidget {
  const _VerifiedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _ProfilePalette.green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: _ProfilePalette.green, size: 13),
          SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              color: _ProfilePalette.green,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ProfilePalette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ProfilePalette.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: _ProfilePalette.border,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _ProfilePalette.teal.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ProfilePalette.teal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 13,
        decoration: BoxDecoration(
          color: _ProfilePalette.border,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String message;
}

class _ProfilePalette {
  const _ProfilePalette._();

  static const Color ink = Color(0xFF12343B);
  static const Color muted = Color(0xFF64748B);
  static const Color slate = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color teal = Color(0xFF0E9FA6);
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF18A77D);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEA580C);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color red = Color(0xFFDC2626);
}

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 8)),
];

BoxDecoration _surfaceDecoration({bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _ProfilePalette.border),
    boxShadow: shadow ? _softShadow : null,
  );
}
