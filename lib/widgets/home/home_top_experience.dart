import 'package:flutter/material.dart';

import '../location_card.dart';
import '../notification_button.dart';
import '../search_bar.dart';

/// The complete decision area above the medical-test feed.
///
/// The hierarchy intentionally follows the rest of the Testified app:
/// location -> greeting -> search -> prescription upload -> secondary actions.
class HomeTopExperience extends StatelessWidget {
  const HomeTopExperience({
    required this.firstName,
    required this.hour,
    required this.onNotificationTap,
    required this.onSearch,
    required this.onUploadPrescription,
    required this.onBrowseTests,
    required this.onViewReports,
    super.key,
  });

  final String firstName;
  final int hour;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearch;
  final VoidCallback onUploadPrescription;
  final VoidCallback onBrowseTests;
  final VoidCallback onViewReports;

  String get _salutation {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UtilityRow(onNotificationTap: onNotificationTap),
        const SizedBox(height: 22),
        _WelcomeCopy(salutation: _salutation, firstName: firstName),
        const SizedBox(height: 18),
        HomeSearchBar(onTap: onSearch),
        const SizedBox(height: 18),
        _PrescriptionCard(onTap: onUploadPrescription),
        const SizedBox(height: 14),
        _QuickActionRow(
          onBrowseTests: onBrowseTests,
          onViewReports: onViewReports,
        ),
      ],
    );
  }
}

class _UtilityRow extends StatelessWidget {
  const _UtilityRow({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: LocationCard()),
        const SizedBox(width: 12),
        NotificationButton(unreadCount: 0, onTap: onNotificationTap),
      ],
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy({required this.salutation, required this.firstName});

  final String salutation;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final title = firstName.isEmpty ? salutation : '$salutation, $firstName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _HomeTopPalette.ink,
            fontSize: 27,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -.55,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'What would you like to take care of today?',
          style: TextStyle(
            color: _HomeTopPalette.muted,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Upload prescription and review the prepared test list',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _HomeTopPalette.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08111B30),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrescriptionIcon(),
                SizedBox(width: 14),
                Expanded(child: _PrescriptionCopy()),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.upload_file_rounded, size: 21),
                label: const Text('Upload prescription'),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _HomeTopPalette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            const _PrescriptionTrustLine(),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionIcon extends StatelessWidget {
  const _PrescriptionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: _HomeTopPalette.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.note_add_rounded,
        color: _HomeTopPalette.primary,
        size: 29,
      ),
    );
  }
}

class _PrescriptionCopy extends StatelessWidget {
  const _PrescriptionCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload your prescription',
          style: TextStyle(
            color: _HomeTopPalette.ink,
            fontSize: 19,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.25,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'We prepare the required test list. You review and approve it before booking.',
          style: TextStyle(
            color: _HomeTopPalette.muted,
            fontSize: 13,
            height: 1.42,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PrescriptionTrustLine extends StatelessWidget {
  const _PrescriptionTrustLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: _HomeTopPalette.textSoft,
          size: 17,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Private and secure. Nothing is booked or charged without your approval.',
            style: TextStyle(
              color: _HomeTopPalette.textSoft,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.onBrowseTests,
    required this.onViewReports,
  });

  final VoidCallback onBrowseTests;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.biotech_rounded,
            title: 'Browse tests',
            subtitle: 'Find by health need',
            onTap: onBrowseTests,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.description_rounded,
            title: 'My reports',
            subtitle: 'Results in one place',
            onTap: onViewReports,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 94,
          padding: const EdgeInsets.fromLTRB(14, 14, 11, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _HomeTopPalette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06111B30),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _HomeTopPalette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _HomeTopPalette.primary, size: 22),
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
                        color: _HomeTopPalette.ink,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeTopPalette.muted,
                        fontSize: 10.4,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _HomeTopPalette.textSoft,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopPalette {
  const _HomeTopPalette._();

  static const Color ink = Color(0xFF121528);
  static const Color muted = Color(0xFF71819A);
  static const Color textSoft = Color(0xFF91A1B7);
  static const Color border = Color(0xFFE1E8F1);
  static const Color primary = Color(0xFF2F67F5);
  static const Color primarySoft = Color(0xFFEAF2FF);
}
