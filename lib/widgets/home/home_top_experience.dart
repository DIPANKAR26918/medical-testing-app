import 'package:flutter/material.dart';

import '../location_card.dart';
import '../notification_button.dart';
import '../search_bar.dart';
import 'home_constants.dart';

/// The high-priority decision area at the top of the Testified home screen.
///
/// Its hierarchy follows a care journey instead of an ecommerce dashboard:
/// location -> personal welcome -> search -> prescription help -> shortcuts.
class HomeTopExperience extends StatelessWidget {
  const HomeTopExperience({
    required this.firstName,
    required this.hour,
    required this.onNotificationTap,
    required this.onSearch,
    required this.onUploadPrescription,
    required this.onBrowseTests,
    required this.onViewBookings,
    required this.onViewReports,
    super.key,
  });

  final String firstName;
  final int hour;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearch;
  final VoidCallback onUploadPrescription;
  final VoidCallback onBrowseTests;
  final VoidCallback onViewBookings;
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
        const SizedBox(height: 20),
        _WelcomeCopy(salutation: _salutation, firstName: firstName),
        const SizedBox(height: 16),
        HomeSearchBar(onTap: onSearch),
        const SizedBox(height: 16),
        _PrescriptionHero(onTap: onUploadPrescription),
        const SizedBox(height: 14),
        _QuickActions(
          onBrowseTests: onBrowseTests,
          onUploadPrescription: onUploadPrescription,
          onViewBookings: onViewBookings,
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
        const SizedBox(width: 10),
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
            color: HomeColors.textPrimary,
            fontSize: 26,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -.55,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Let’s make your next health check simpler.',
          style: TextStyle(
            color: HomeColors.textSecondary,
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PrescriptionHero extends StatelessWidget {
  const _PrescriptionHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Upload a prescription and review the prepared test list',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: HomeColors.primarySoft,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFD5E3FD)),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -34,
                  top: -44,
                  child: _SoftCircle(size: 132, opacity: .07),
                ),
                const Positioned(
                  left: -42,
                  bottom: -62,
                  child: _SoftCircle(size: 126, opacity: .045),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 18, 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PrescriptionEyebrow(),
                                SizedBox(height: 11),
                                Text(
                                  'Not sure which tests to book?',
                                  style: TextStyle(
                                    color: HomeColors.textPrimary,
                                    fontSize: 20.5,
                                    height: 1.14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.38,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Upload your prescription. Our team prepares the test list, and you approve it before booking.',
                                  style: TextStyle(
                                    color: HomeColors.textSecondary,
                                    fontSize: 12.4,
                                    height: 1.42,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          _PrescriptionArtwork(),
                        ],
                      ),
                      const SizedBox(height: 17),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.upload_file_rounded, size: 20),
                          label: const Text('Upload prescription'),
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: HomeColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: HomeColors.textMuted,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Private and secure • No payment before your approval',
                              style: TextStyle(
                                color: HomeColors.textMuted,
                                fontSize: 10.5,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

class _PrescriptionEyebrow extends StatelessWidget {
  const _PrescriptionEyebrow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_outlined, color: HomeColors.primary, size: 15),
        SizedBox(width: 6),
        Text(
          'PRESCRIPTION ASSIST',
          style: TextStyle(
            color: HomeColors.primaryDark,
            fontSize: 10.2,
            fontWeight: FontWeight.w800,
            letterSpacing: .72,
          ),
        ),
      ],
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: HomeColors.primary.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PrescriptionArtwork extends StatelessWidget {
  const _PrescriptionArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 2,
            top: 5,
            child: Container(
              width: 70,
              height: 92,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE6F7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x142563EB),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 8,
                    decoration: BoxDecoration(
                      color: HomeColors.primary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _DocumentLine(width: 44),
                  const SizedBox(height: 7),
                  const _DocumentLine(width: 36),
                  const SizedBox(height: 7),
                  const _DocumentLine(width: 42),
                  const Spacer(),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: HomeColors.mint,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 3,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HomeColors.mintSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD2ECE4)),
              ),
              child: const Icon(
                Icons.biotech_rounded,
                color: HomeColors.mint,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE4F0),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBrowseTests,
    required this.onUploadPrescription,
    required this.onViewBookings,
    required this.onViewReports,
  });

  final VoidCallback onBrowseTests;
  final VoidCallback onUploadPrescription;
  final VoidCallback onViewBookings;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 12, 7, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: HomeColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07111B30),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.biotech_outlined,
              label: 'Book tests',
              accent: HomeColors.primary,
              soft: HomeColors.primarySoft,
              onTap: onBrowseTests,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.note_add_outlined,
              label: 'Upload Rx',
              accent: HomeColors.mint,
              soft: HomeColors.mintSoft,
              onTap: onUploadPrescription,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.calendar_month_outlined,
              label: 'Bookings',
              accent: const Color(0xFF6D5BD0),
              soft: const Color(0xFFF0EEFB),
              onTap: onViewBookings,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.description_outlined,
              label: 'Reports',
              accent: const Color(0xFF3E658C),
              soft: const Color(0xFFEDF3F8),
              onTap: onViewReports,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 10.6,
                    height: 1.14,
                    fontWeight: FontWeight.w700,
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
