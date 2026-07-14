import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<AppUser?> _profileFuture;

  bool _isDeletingAccount = false;

  static const List<String> _accountScopedPreferenceKeys = [
    'saved_location_data',
    'recent_searches',
    'selected_patient_id',
    'selected_address_id',
  ];

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

  Future<void> _requestAccountDeletion(AppUser profile) async {
    if (_isDeletingAccount) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (context) {
        return _DeleteAccountConfirmationSheet(profileName: profile.name);
      },
    );

    if (confirmed != true || !mounted) return;

    await _deleteCurrentAccount();
  }

  Future<void> _deleteCurrentAccount() async {
    if (_isDeletingAccount) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        throw StateError(
          'Your session has expired. Please log in again before deleting the account.',
        );
      }

      final response = await _supabase.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(_deleteErrorMessage(response.data));
      }

      await _clearAccountScopedLocalData();

      // The account has already been removed on the server. This call clears
      // the locally persisted Supabase session. A revoked token may make the
      // network sign-out fail, so navigation must not depend on it succeeding.
      try {
        await _supabase.auth.signOut();
      } catch (_) {
        // Intentionally ignored: the server-side deletion already succeeded.
      }

      if (!mounted) return;

      widget.onLogout();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeletingAccount = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_friendlyError(error)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ProfilePalette.danger,
            duration: const Duration(seconds: 4),
          ),
        );
    }
  }

  Future<void> _clearAccountScopedLocalData() async {
    final preferences = await SharedPreferences.getInstance();

    for (final key in _accountScopedPreferenceKeys) {
      await preferences.remove(key);
    }
  }

  static String _deleteErrorMessage(dynamic data) {
    if (data is Map) {
      final message =
          data['error']?.toString().trim() ??
          data['message']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final fallback = data?.toString().trim();

    if (fallback != null &&
        fallback.isNotEmpty &&
        fallback.toLowerCase() != 'null') {
      return fallback;
    }

    return 'Account deletion failed. Please try again.';
  }

  static String _friendlyError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .trim();

    if (message.isEmpty) {
      return 'Account deletion failed. Please try again.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ProfilePalette.background,
      child: RefreshIndicator(
        color: _ProfilePalette.primary,
        onRefresh: _refreshProfile,
        child: FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
              children: [
                const _ProfileHeader(),
                const SizedBox(height: 18),
                if (isLoading)
                  const _ProfileLoadingCard()
                else if (profile == null)
                  _MissingProfileCard(onRetry: _refreshProfile)
                else ...[
                  _IdentityCard(
                    profile: profile,
                    onEdit: () => _showAction('Profile editing will open here'),
                  ),
                  const SizedBox(height: 14),
                  _HealthDetailsCard(profile: profile),
                  const SizedBox(height: 14),
                  _AccountActionsCard(
                    onAction: _showAction,
                    onLogout: widget.onLogout,
                    onDeleteAccount: () => _requestAccountDeletion(profile),
                    isDeletingAccount: _isDeletingAccount,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: _ProfilePalette.ink,
            fontSize: 26,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Manage your health account',
          style: TextStyle(
            color: _ProfilePalette.muted,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile, required this.onEdit});

  final AppUser profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final contact = _primaryContact(profile);
    final profileComplete = _completionCount(profile) == 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(initials: profile.initials),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeName(profile.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfilePalette.ink,
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfilePalette.muted,
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _VerificationChip(complete: profileComplete),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProfileQualityNote(
                  complete: profileComplete,
                  completedCount: _completionCount(profile),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ProfilePalette.primary,
                    side: const BorderSide(color: _ProfilePalette.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _safeName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.toLowerCase() == 'testified user') {
      return 'Your profile';
    }

    return name;
  }

  static String _primaryContact(AppUser profile) {
    final phone = profile.phoneNumber?.trim();
    final email = profile.email?.trim();

    if (phone != null && phone.isNotEmpty) return phone;
    if (email != null && email.isNotEmpty) return email;

    return 'No contact added';
  }

  static int _completionCount(AppUser profile) {
    var count = 0;

    if (profile.name.trim().isNotEmpty &&
        profile.name.trim().toLowerCase() != 'testified user') {
      count++;
    }

    if (profile.age != null && profile.age! > 0) count++;

    if ((profile.gender ?? '').trim().isNotEmpty) count++;

    if ((profile.phoneNumber ?? profile.email ?? '').trim().isNotEmpty) {
      count++;
    }

    return count;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final safeInitials = initials.trim().isEmpty ? 'U' : initials.trim();

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _ProfilePalette.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ProfilePalette.primary.withValues(alpha: .12),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        safeInitials,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ProfilePalette.primary,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? _ProfilePalette.success : _ProfilePalette.warning;
    final label = complete ? 'Complete' : 'Incomplete';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileQualityNote extends StatelessWidget {
  const _ProfileQualityNote({
    required this.complete,
    required this.completedCount,
  });

  final bool complete;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      complete
          ? 'Your profile is ready for bookings.'
          : '$completedCount/4 details added',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _ProfilePalette.muted,
        fontSize: 12.8,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _HealthDetailsCard extends StatelessWidget {
  const _HealthDetailsCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final age = profile.age == null || profile.age! <= 0
        ? 'Not added'
        : '${profile.age}';

    final gender = (profile.gender ?? '').trim().isEmpty
        ? 'Not added'
        : profile.gender!.trim();

    final phone = (profile.phoneNumber ?? '').trim().isEmpty
        ? 'Not added'
        : profile.phoneNumber!.trim();

    final email = (profile.email ?? '').trim().isEmpty
        ? 'Not added'
        : profile.email!.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Health details',
            subtitle: 'Used for test bookings and reports',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CompactDetailTile(label: 'Age', value: age),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactDetailTile(label: 'Gender', value: gender),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FullWidthDetailTile(label: 'Phone', value: phone),
          const SizedBox(height: 10),
          _FullWidthDetailTile(label: 'Email', value: email),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _ProfilePalette.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: _ProfilePalette.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ProfilePalette.ink,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProfilePalette.muted,
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactDetailTile extends StatelessWidget {
  const _CompactDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Not added';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ProfilePalette.muted,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: missing ? _ProfilePalette.softMuted : _ProfilePalette.ink,
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullWidthDetailTile extends StatelessWidget {
  const _FullWidthDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Not added';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ProfilePalette.muted,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: missing ? _ProfilePalette.softMuted : _ProfilePalette.ink,
              fontSize: 14.5,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({
    required this.onAction,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.isDeletingAccount,
  });

  final ValueChanged<String> onAction;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final bool isDeletingAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          _AccountActionRow(
            title: 'Family members',
            subtitle: 'Add profiles for repeat bookings',
            onTap: () => onAction('Family profiles will open here'),
          ),
          const _ActionDivider(),
          _AccountActionRow(
            title: 'Saved addresses',
            subtitle: 'Manage home collection locations',
            onTap: () => onAction('Saved addresses will open here'),
          ),
          const _ActionDivider(),
          _AccountActionRow(
            title: 'Privacy and security',
            subtitle: 'Reports, OTP, and account controls',
            onTap: () => onAction('Privacy controls will open here'),
          ),
          const _ActionDivider(),
          _AccountActionRow(
            title: 'Payments and coupons',
            subtitle: 'Invoices, offers, and saved benefits',
            onTap: () => onAction('Payments and coupons will open here'),
          ),
          const _ActionDivider(),
          _AccountActionRow(
            title: 'Help and support',
            subtitle: 'Support for bookings and reports',
            onTap: () => onAction('Help center will open here'),
          ),
          const _ActionDivider(),
          _LogoutRow(onLogout: isDeletingAccount ? null : onLogout),
          const _ActionDivider(),
          _DeleteAccountRow(
            onDeleteAccount: isDeletingAccount ? null : onDeleteAccount,
            isDeleting: isDeletingAccount,
          ),
        ],
      ),
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfilePalette.ink,
                        fontSize: 14.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfilePalette.muted,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ProfilePalette.softMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({required this.onLogout});

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onLogout,
        child: Opacity(
          opacity: onLogout == null ? .45 : 1,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: _ProfilePalette.danger,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.logout_rounded,
                  color: _ProfilePalette.danger,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow({
    required this.onDeleteAccount,
    required this.isDeleting,
  });

  final VoidCallback? onDeleteAccount;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFBFB),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: InkWell(
        onTap: onDeleteAccount,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeleting ? 'Deleting account…' : 'Delete account',
                      style: const TextStyle(
                        color: _ProfilePalette.danger,
                        fontSize: 14.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Permanently remove your profile and bookings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ProfilePalette.muted,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isDeleting)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: _ProfilePalette.danger,
                  ),
                )
              else
                const Icon(
                  Icons.delete_forever_outlined,
                  color: _ProfilePalette.danger,
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountConfirmationSheet extends StatelessWidget {
  const _DeleteAccountConfirmationSheet({required this.profileName});

  final String profileName;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeName = profileName.trim().isEmpty
        ? 'this account'
        : profileName.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _ProfilePalette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: _ProfilePalette.danger,
                size: 29,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete account permanently?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProfilePalette.ink,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The account for $safeName will be permanently deleted. '
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfilePalette.muted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD9DC)),
              ),
              child: const Column(
                children: [
                  _DeleteImpactRow(label: 'Profile and health details'),
                  SizedBox(height: 10),
                  _DeleteImpactRow(label: 'Bookings and prescription records'),
                  SizedBox(height: 10),
                  _DeleteImpactRow(label: 'Account access and sign-in session'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ProfilePalette.ink,
                        side: const BorderSide(color: _ProfilePalette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Keep account'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ProfilePalette.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Delete permanently'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteImpactRow extends StatelessWidget {
  const _DeleteImpactRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE5E7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: _ProfilePalette.danger,
            size: 13,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _ProfilePalette.ink,
              fontSize: 12.8,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: _ProfilePalette.border,
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LoadingLine(widthFactor: .70),
                SizedBox(height: 9),
                _LoadingLine(widthFactor: .48),
                SizedBox(height: 9),
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
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _ProfilePalette.primary.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: _ProfilePalette.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profile not found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProfilePalette.ink,
              fontSize: 17,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'We could not load your saved profile details right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProfilePalette.muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                onRetry();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _ProfilePalette.primary,
                side: const BorderSide(color: _ProfilePalette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Try again'),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ProfilePalette {
  const _ProfilePalette._();

  static const Color background = Color(0xFFFAFBFC);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE6EAF0);

  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .025),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

BoxDecoration _surfaceDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _ProfilePalette.border),
    boxShadow: _ProfilePalette.cardShadow,
  );
}
