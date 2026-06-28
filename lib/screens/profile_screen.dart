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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF087E86),
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
              const Text(
                'Profile',
                style: TextStyle(
                  color: Color(0xFF0B2538),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage care preferences, personal details, and account settings.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _ProfileLoadingCard()
              else if (profile == null)
                _MissingProfileCard(onRetry: _refreshProfile)
              else ...[
                _ProfileCard(profile: profile),
                const SizedBox(height: 14),
                _PersonalDetailsCard(profile: profile),
                const SizedBox(height: 14),
                _FamilyCard(profile: profile),
              ],
              const SizedBox(height: 14),
              _SettingsCard(onLogout: widget.onLogout),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: Color(0xFF087E86),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B2538),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phoneNumber ?? profile.email ?? 'No contact added',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded),
            color: const Color(0xFF087E86),
          ),
        ],
      ),
    );
  }
}

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal details',
            style: TextStyle(
              color: Color(0xFF0B2538),
              fontSize: 16,
              fontWeight: FontWeight.w900,
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
            label: 'Phone number',
            value: profile.phoneNumber ?? 'Not added',
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family members',
            style: TextStyle(
              color: Color(0xFF0B2538),
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
          const Divider(height: 22),
          const Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: Color(0xFF087E86)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add family members when family profiles are connected.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoadingLine(widthFactor: .72),
                SizedBox(height: 8),
                _LoadingLine(widthFactor: .46),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF087E86)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile not found',
                  style: TextStyle(
                    color: Color(0xFF0B2538),
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
            style: TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF087E86), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0B2538),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF087E86), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B2538),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const _SettingRow(
            icon: Icons.home_work_rounded,
            title: 'Saved addresses',
            subtitle: 'Home and lab preferences',
          ),
          const Divider(height: 1),
          const _SettingRow(
            icon: Icons.lock_rounded,
            title: 'Privacy and security',
            subtitle: 'Reports, OTP, and data controls',
          ),
          const Divider(height: 1),
          const _SettingRow(
            icon: Icons.support_agent_rounded,
            title: 'Help center',
            subtitle: 'Support for bookings and reports',
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFDC2626),
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
              color: Color(0xFF087E86),
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
                  color: Color(0xFF0B2538),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                relation,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF087E86)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0B2538),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
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
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
