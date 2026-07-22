import 'package:flutter/material.dart';

import 'delete_account_otp_screen.dart';

class ManageAccountScreen extends StatelessWidget {
  const ManageAccountScreen({
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.expectedUserId,
    required this.phoneNumber,
    super.key,
  });

  final Future<void> Function() onSignOut;
  final Future<bool> Function() onDeleteAccount;
  final String? expectedUserId;
  final String? phoneNumber;

  static Route<void> route({
    required Future<void> Function() onSignOut,
    required Future<bool> Function() onDeleteAccount,
    required String? expectedUserId,
    required String? phoneNumber,
  }) {
    return _slideRoute<void>(
      ManageAccountScreen(
        onSignOut: onSignOut,
        onDeleteAccount: onDeleteAccount,
        expectedUserId: expectedUserId,
        phoneNumber: phoneNumber,
      ),
    );
  }

  Future<void> _requestSignOut(BuildContext context) async {
    final confirmed = await _showAccountConfirmation(
      context: context,
      title: 'Sign out of Testified?',
      description: 'This ends the active session on this device.',
      bullets: const [
        'You will need your phone or email to sign in again.',
        'Your bookings, reports, and saved details stay in your account.',
        'This device will stop receiving account notifications.',
      ],
      icon: Icons.logout_rounded,
      confirmLabel: 'Sign out',
      cancelLabel: 'Stay signed in',
    );

    if (confirmed != true) return;

    await onSignOut();
  }

  Future<void> _requestAccountDeletion(BuildContext context) async {
    final confirmed = await _showAccountConfirmation(
      context: context,
      title: 'Delete account permanently?',
      description:
          'Review what will happen before starting phone verification.',
      bullets: const [
        'Your profile and personal health details will be removed.',
        'Bookings, prescriptions, reports, and saved records will be deleted.',
        'This action cannot be undone after verification.',
      ],
      icon: Icons.delete_forever_outlined,
      confirmLabel: 'Delete account',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final userId = expectedUserId?.trim();
    final phone = phoneNumber?.trim();

    if (userId == null ||
        userId.isEmpty ||
        phone == null ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A verified phone number is required to delete this account.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    await Navigator.of(context).push(
      _slideRoute<void>(
        DeleteAccountOtpScreen(
          expectedUserId: userId,
          phoneNumber: phone,
          onDeleteAccount: onDeleteAccount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccountPalette.background,
      appBar: AppBar(
        backgroundColor: _AccountPalette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _AccountPalette.ink,
          ),
        ),
        title: const Text(
          'Manage account',
          style: TextStyle(
            color: _AccountPalette.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            const Text(
              'Control access to your account or permanently remove it.',
              style: TextStyle(
                color: _AccountPalette.muted,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            _AccountActionCard(
              title: 'Sign out',
              subtitle: 'End this session on this device',
              icon: Icons.logout_rounded,
              onTap: () => _requestSignOut(context),
            ),
            const SizedBox(height: 12),
            _AccountActionCard(
              title: 'Delete account permanently',
              subtitle: 'Remove your account and associated records',
              icon: Icons.delete_forever_outlined,
              isDanger: true,
              onTap: () => _requestAccountDeletion(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final accent = isDanger
        ? _AccountPalette.danger
        : _AccountPalette.primary;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDanger
              ? _AccountPalette.danger.withValues(alpha: .16)
              : _AccountPalette.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDanger
                            ? _AccountPalette.danger
                            : _AccountPalette.ink,
                        fontSize: 15.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _AccountPalette.muted,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _AccountPalette.softMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showAccountConfirmation({
  required BuildContext context,
  required String title,
  required String description,
  required List<String> bullets,
  required IconData icon,
  required String confirmLabel,
  required String cancelLabel,
  bool isDanger = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .42),
    builder: (context) {
      return _AccountConfirmationSheet(
        title: title,
        description: description,
        bullets: bullets,
        icon: icon,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      );
    },
  );
}

class _AccountConfirmationSheet extends StatelessWidget {
  const _AccountConfirmationSheet({
    required this.title,
    required this.description,
    required this.bullets,
    required this.icon,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDanger,
  });

  final String title;
  final String description;
  final List<String> bullets;
  final IconData icon;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final accent = isDanger
        ? _AccountPalette.danger
        : _AccountPalette.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _AccountPalette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AccountPalette.ink,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AccountPalette.muted,
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
                color: isDanger
                    ? const Color(0xFFFFF8F8)
                    : _AccountPalette.subtleSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDanger
                      ? const Color(0xFFFFD9DC)
                      : _AccountPalette.border,
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < bullets.length; index++) ...[
                    _ConfirmationBullet(
                      label: bullets[index],
                      color: accent,
                    ),
                    if (index != bullets.length - 1)
                      const SizedBox(height: 11),
                  ],
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
                        foregroundColor: _AccountPalette.ink,
                        side: const BorderSide(
                          color: _AccountPalette.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(cancelLabel),
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
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(confirmLabel),
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

class _ConfirmationBullet extends StatelessWidget {
  const _ConfirmationBullet({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _AccountPalette.ink,
              fontSize: 12.7,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final position = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

      return SlideTransition(position: position, child: child);
    },
  );
}

class _AccountPalette {
  const _AccountPalette._();

  static const Color background = Color(0xFFFAFBFC);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color softMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE6EAF0);
  static const Color subtleSurface = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
}
