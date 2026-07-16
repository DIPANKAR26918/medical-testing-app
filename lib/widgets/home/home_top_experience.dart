import 'package:flutter/material.dart';

import '../location_card.dart';
import '../notification_button.dart';
import '../search_bar.dart';

/// The complete decision area above the home feed.
///
/// Keeping this composition outside the dashboard screen leaves that screen
/// responsible for data and navigation only. The hierarchy here deliberately
/// gives the prescription flow one clear primary action and keeps catalogue
/// and reports as secondary choices.
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
        const SizedBox(height: 18),
        _WelcomeCopy(salutation: _salutation, firstName: firstName),
        const SizedBox(height: 15),
        HomeSearchBar(onTap: onSearch),
        const SizedBox(height: 18),
        _PrescriptionCareCard(onTap: onUploadPrescription),
        const SizedBox(height: 12),
        _QuickCareRow(
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
    final title = firstName.isEmpty
        ? salutation
        : '$salutation, $firstName';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeTopPalette.ink,
              fontSize: 25,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.55,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'What would you like to take care of today?',
            style: TextStyle(
              color: _HomeTopPalette.muted,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCareCard extends StatelessWidget {
  const _PrescriptionCareCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Upload a prescription and review the prepared test list',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: _HomeTopPalette.primary.withValues(alpha: .07),
          highlightColor: _HomeTopPalette.primary.withValues(alpha: .035),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0F8F4), Color(0xFFFBF7EF)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD9E8E1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x101A5147),
                  blurRadius: 26,
                  offset: Offset(0, 11),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                const Positioned(
                  right: -70,
                  top: -88,
                  child: _SoftOrb(
                    size: 190,
                    color: Color(0x66FFFFFF),
                  ),
                ),
                Positioned(
                  left: -62,
                  bottom: -86,
                  child: _SoftOrb(
                    size: 170,
                    color: _HomeTopPalette.primary.withValues(alpha: .035),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PrescriptionMetaRow(),
                      const SizedBox(height: 12),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _PrescriptionCopy()),
                          SizedBox(width: 8),
                          _PrescriptionArtwork(),
                        ],
                      ),
                      const SizedBox(height: 13),
                      _PrescriptionButton(onTap: onTap),
                      const SizedBox(height: 11),
                      const _AssuranceRow(),
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

class _PrescriptionMetaRow extends StatelessWidget {
  const _PrescriptionMetaRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _CareLabel(),
        Spacer(),
        _PrivacyLabel(),
      ],
    );
  }
}

class _CareLabel extends StatelessWidget {
  const _CareLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFD6E5DE)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.health_and_safety_rounded,
            color: _HomeTopPalette.primary,
            size: 13,
          ),
          SizedBox(width: 5),
          Text(
            'TESTIFIED CARE',
            style: TextStyle(
              color: _HomeTopPalette.primary,
              fontSize: 8.7,
              fontWeight: FontWeight.w900,
              letterSpacing: .62,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyLabel extends StatelessWidget {
  const _PrivacyLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: _HomeTopPalette.muted,
          size: 14,
        ),
        SizedBox(width: 4),
        Text(
          'Private',
          style: TextStyle(
            color: _HomeTopPalette.muted,
            fontSize: 10.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
          'Your prescription\nis enough.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _HomeTopPalette.ink,
            fontSize: 21.5,
            height: 1.07,
            fontWeight: FontWeight.w900,
            letterSpacing: -.48,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'We prepare the test list. You review everything before booking.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _HomeTopPalette.body,
            fontSize: 11.7,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrescriptionButton extends StatelessWidget {
  const _PrescriptionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _HomeTopPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 13.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.upload_file_rounded, size: 20),
            SizedBox(width: 9),
            Expanded(child: Text('Upload prescription')),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AssuranceRow extends StatelessWidget {
  const _AssuranceRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _AssuranceItem(
            icon: Icons.lock_outline_rounded,
            label: 'Secure upload',
          ),
        ),
        _AssuranceDivider(),
        Expanded(
          child: _AssuranceItem(
            icon: Icons.fact_check_outlined,
            label: 'Team reviewed',
          ),
        ),
        _AssuranceDivider(),
        Expanded(
          child: _AssuranceItem(
            icon: Icons.touch_app_outlined,
            label: 'You approve',
          ),
        ),
      ],
    );
  }
}

class _AssuranceItem extends StatelessWidget {
  const _AssuranceItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _HomeTopPalette.primary, size: 12.5),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeTopPalette.body,
              fontSize: 8.9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssuranceDivider extends StatelessWidget {
  const _AssuranceDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 13,
      color: const Color(0xFFD4E1DC),
    );
  }
}

class _PrescriptionArtwork extends StatelessWidget {
  const _PrescriptionArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 103,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0x8FFFFFFF),
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -.045,
            child: Container(
              width: 63,
              height: 82,
              padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE1E9E4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1812473F),
                    blurRadius: 15,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rx',
                        style: TextStyle(
                          color: _HomeTopPalette.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.medical_services_rounded,
                        color: _HomeTopPalette.sage,
                        size: 12,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _PaperLine(width: 39),
                  SizedBox(height: 5),
                  _PaperLine(width: 45),
                  SizedBox(height: 8),
                  _PaperCheckLine(width: 27),
                  SizedBox(height: 5),
                  _PaperCheckLine(width: 34),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 2,
            bottom: 3,
            child: _ArtworkCheck(),
          ),
          const Positioned(
            right: 5,
            top: 6,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _HomeTopPalette.warm,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperLine extends StatelessWidget {
  const _PaperLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3.5,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE6E1),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _PaperCheckLine extends StatelessWidget {
  const _PaperCheckLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: _HomeTopPalette.sage,
          size: 8,
        ),
        const SizedBox(width: 3),
        _PaperLine(width: width),
      ],
    );
  }
}

class _ArtworkCheck extends StatelessWidget {
  const _ArtworkCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: _HomeTopPalette.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
    );
  }
}

class _QuickCareRow extends StatelessWidget {
  const _QuickCareRow({
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
          child: _QuickCareCard(
            icon: Icons.biotech_rounded,
            title: 'Browse tests',
            subtitle: 'Find by health need',
            accent: _HomeTopPalette.primary,
            tint: const Color(0xFFEAF5F0),
            onTap: onBrowseTests,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _QuickCareCard(
            icon: Icons.description_rounded,
            title: 'My reports',
            subtitle: 'Results in one place',
            accent: _HomeTopPalette.plum,
            tint: const Color(0xFFF2EFF5),
            onTap: onViewReports,
          ),
        ),
      ],
    );
  }
}

class _QuickCareCard extends StatelessWidget {
  const _QuickCareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 86,
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _HomeTopPalette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1A332E),
                  blurRadius: 17,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 21),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _HomeTopPalette.muted,
                          fontSize: 9.7,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: .72),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HomeTopPalette {
  const _HomeTopPalette._();

  static const Color ink = Color(0xFF172521);
  static const Color body = Color(0xFF4F625C);
  static const Color muted = Color(0xFF718079);
  static const Color border = Color(0xFFE1E8E4);

  static const Color primary = Color(0xFF176B5B);
  static const Color sage = Color(0xFF6E8B75);
  static const Color plum = Color(0xFF6D667F);
  static const Color warm = Color(0xFFC08A5C);
}
