import 'package:flutter/material.dart';

import 'home_constants.dart';

/// The two primary booking paths plus a separate completed-reports shortcut.
class HomeServiceActions extends StatelessWidget {
  const HomeServiceActions({
    required this.onBookTest,
    required this.onUploadPrescription,
    required this.onViewReports,
    super.key,
  });

  final VoidCallback onBookTest;
  final VoidCallback onUploadPrescription;
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _ServiceCard(
            eyebrow: 'PRESCRIPTION ASSIST',
            title: 'Book via prescription',
            subtitle: 'Upload once. Approve every mapped test',
            icon: Icons.assignment_turned_in_outlined,
            accent: HomeColors.primary,
            background: const Color(0xFFEAF2FF),
            onTap: onUploadPrescription,
          ),
          _ServiceCard(
            eyebrow: 'BOOK DIRECTLY',
            title: 'Choose a lab test',
            subtitle: 'Search the complete catalogue',
            icon: Icons.biotech_outlined,
            accent: HomeColors.mint,
            background: const Color(0xFFE6F7F2),
            onTap: onBookTest,
          ),
        ];

        return Column(
          children: [
            if (constraints.maxWidth < 310) ...[
              SizedBox(height: 174, child: cards[0]),
              const SizedBox(height: 12),
              SizedBox(height: 174, child: cards[1]),
            ] else
              SizedBox(
                height: 196,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            _ReportsShortcut(onTap: onViewReports),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: accent.withValues(alpha: .12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: accent, size: 23),
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 8.7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .62,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 16.2,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeColors.textSecondary,
                    fontSize: 10.3,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
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

class _ReportsShortcut extends StatelessWidget {
  const _ReportsShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Reports. View completed lab reports',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            height: 86,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: HomeColors.mintSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: HomeColors.mint,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          color: HomeColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'View completed lab reports',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: HomeColors.textSecondary,
                          fontSize: 11.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: HomeColors.textMuted,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
