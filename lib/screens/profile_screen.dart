import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../widgets/location_selector_sheet.dart';
import 'manage_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onLogout, super.key});

  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<AppUser?> _profileFuture;

  bool _isDeletingAccount = false;
  bool _isAccountCenterExpanded = false;

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

  void _openManageAccount() {
    final authUser = _supabase.auth.currentUser;

    Navigator.of(context).push(
      ManageAccountScreen.route(
        onSignOut: _signOutFromManageAccount,
        onDeleteAccount: _deleteCurrentAccount,
        expectedUserId: authUser?.id,
        phoneNumber: authUser?.phone,
      ),
    );
  }

  Future<void> _openSavedAddresses() async {
    final selected = await LocationService(client: _supabase)
        .loadSavedLocation();
    if (!mounted) return;
    await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .38),
      builder: (_) => LocationSelectorSheet(currentLocation: selected),
    );
  }

  Future<void> _signOutFromManageAccount() async {
    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    try {
      await widget.onLogout();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_friendlyError(error)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ProfilePalette.danger,
          ),
        );
    }
  }

  Future<bool> _deleteCurrentAccount() async {
    if (_isDeletingAccount) return false;

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

      final deletedUserId = session.user.id;

      final response = await _supabase.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(_deleteErrorMessage(response.data));
      }

      await _clearAccountScopedLocalData(deletedUserId);

      // The account has already been removed on the server. This call clears
      // the locally persisted Supabase session. A revoked token may make the
      // network sign-out fail, so navigation must not depend on it succeeding.
      try {
        await _supabase.auth.signOut();
      } catch (_) {
        // Intentionally ignored: the server-side deletion already succeeded.
      }
    } catch (error) {
      if (!mounted) return false;

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

      return false;
    }

    if (!mounted) return true;

    Navigator.of(context).popUntil((route) => route.isFirst);

    try {
      await widget.onLogout();
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
      }
    }

    return true;
  }

  Future<void> _clearAccountScopedLocalData(String userId) async {
    await LocationService(
      client: _supabase,
    ).clearSavedLocation(userId: userId);

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
                parent: ClampingScrollPhysics(),
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
                  _AccountActionsCard(
                    profile: profile,
                    isAccountCenterExpanded: _isAccountCenterExpanded,
                    onToggleAccountCenter: () {
                      setState(() {
                        _isAccountCenterExpanded =
                            !_isAccountCenterExpanded;
                      });
                    },
                    onAction: _showAction,
                    onSavedAddresses: _openSavedAddresses,
                    onManageAccount: _openManageAccount,
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
                child: TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: _ProfilePalette.primary,
                    backgroundColor:
                        _ProfilePalette.primary.withValues(alpha: .07),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

    if (phone != null && phone.isNotEmpty) {
      return _formatPhoneForDisplay(phone);
    }
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
      complete ? 'Ready for bookings' : '$completedCount of 4 details added',
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

class _AccountCenterPanel extends StatelessWidget {
  const _AccountCenterPanel({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final age = profile.age == null || profile.age! <= 0
        ? 'Not added'
        : '${profile.age}';

    final gender = (profile.gender ?? '').trim().isEmpty
        ? 'Not added'
        : profile.gender!.trim();

    final rawPhone = (profile.phoneNumber ?? '').trim();
    final phone = rawPhone.isEmpty
        ? 'Not added'
        : _formatPhoneForDisplay(rawPhone);

    final email = (profile.email ?? '').trim().isEmpty
        ? 'Not added'
        : profile.email!.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _DetailsGroup(
        age: age,
        gender: gender,
        phone: phone,
        email: email,
      ),
    );
  }
}

class _DetailsGroup extends StatelessWidget {
  const _DetailsGroup({
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
  });

  final String age;
  final String gender;
  final String phone;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfilePalette.subtleSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactDetailValue(label: 'Age', value: age),
              ),
              Container(
                width: 1,
                height: 42,
                color: _ProfilePalette.divider,
              ),
              Expanded(
                child: _CompactDetailValue(label: 'Gender', value: gender),
              ),
            ],
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: _ProfilePalette.divider,
          ),
          _DetailRow(label: 'Phone', value: phone),
          const Divider(
            height: 1,
            thickness: 1,
            color: _ProfilePalette.divider,
          ),
          _DetailRow(label: 'Email', value: email),
        ],
      ),
    );
  }
}

class _CompactDetailValue extends StatelessWidget {
  const _CompactDetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Not added';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ProfilePalette.muted,
              fontSize: 11.8,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Not added';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    missing ? _ProfilePalette.softMuted : _ProfilePalette.ink,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({
    required this.profile,
    required this.isAccountCenterExpanded,
    required this.onToggleAccountCenter,
    required this.onAction,
    required this.onSavedAddresses,
    required this.onManageAccount,
  });

  final AppUser profile;
  final bool isAccountCenterExpanded;
  final VoidCallback onToggleAccountCenter;
  final ValueChanged<String> onAction;
  final VoidCallback onSavedAddresses;
  final VoidCallback onManageAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _surfaceDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _AccountCenterRow(
            expanded: isAccountCenterExpanded,
            onTap: onToggleAccountCenter,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isAccountCenterExpanded
                ? _AccountCenterPanel(profile: profile)
                : const SizedBox.shrink(),
          ),
          const _ActionDivider(),
          _AccountActionRow(
            title: 'Family members',
            subtitle: 'Add profiles for repeat bookings',
            onTap: () => onAction('Family profiles will open here'),
          ),
          const _ActionDivider(),
          _AccountActionRow(
            title: 'Saved addresses',
            subtitle: 'Manage home collection locations',
            onTap: onSavedAddresses,
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
          _AccountActionRow(
            title: 'Manage account',
            subtitle: 'Sign out or permanently delete your account',
            onTap: onManageAccount,
          ),
        ],
      ),
    );
  }
}

class _AccountCenterRow extends StatelessWidget {
  const _AccountCenterRow({
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
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
                    const Text(
                      'Account center',
                      style: TextStyle(
                        color: _ProfilePalette.ink,
                        fontSize: 14.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expanded
                          ? 'Hide personal and contact details'
                          : 'View personal and contact details',
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
              AnimatedRotation(
                turns: expanded ? .25 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _ProfilePalette.softMuted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
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

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: _ProfilePalette.divider,
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

String _formatPhoneForDisplay(String value) {
  final trimmed = value.trim();
  final compact = trimmed.replaceAll(RegExp(r'[\s()-]'), '');
  final indiaNumber = RegExp(r'^\+91(\d{10})$').firstMatch(compact);

  if (indiaNumber == null) return trimmed;

  final digits = indiaNumber.group(1)!;
  return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
}

class _ProfilePalette {
  const _ProfilePalette._();

  static const Color background = Color(0xFFFAFBFC);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE6EAF0);
  static const Color divider = Color(0xFFEDF1F5);
  static const Color subtleSurface = Color(0xFFF8FAFC);

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
