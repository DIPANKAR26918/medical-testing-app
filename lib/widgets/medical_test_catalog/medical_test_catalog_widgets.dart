import 'package:flutter/material.dart';

import '../../models/medical_test.dart';

class MedicalTestCategoryStyle {
  const MedicalTestCategoryStyle({
    required this.accent,
    required this.soft,
    required this.tint,
    required this.icon,
  });

  final Color accent;
  final Color soft;
  final Color tint;
  final IconData icon;

  List<Color> get gradient => [tint, soft];
}

MedicalTestCategoryStyle medicalTestCategoryStyle(String category) {
  final name = category.toLowerCase();

  if (name.contains('blood') || name.contains('coagulation')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFBE123C),
      soft: Color(0xFFFFE9EE),
      tint: Color(0xFFFFF9FA),
      icon: Icons.bloodtype_rounded,
    );
  }
  if (name.contains('heart')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFDC2626),
      soft: Color(0xFFFFEAEA),
      tint: Color(0xFFFFFAFA),
      icon: Icons.favorite_rounded,
    );
  }
  if (name.contains('kidney') || name.contains('urine')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0369A1),
      soft: Color(0xFFE2F3FF),
      tint: Color(0xFFF8FCFF),
      icon: Icons.water_drop_rounded,
    );
  }
  if (name.contains('liver') || name.contains('digestive')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFB45309),
      soft: Color(0xFFFFEED3),
      tint: Color(0xFFFFFCF7),
      icon: Icons.health_and_safety_rounded,
    );
  }
  if (name.contains('diabetes')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0E7490),
      soft: Color(0xFFDDF9FC),
      tint: Color(0xFFF7FEFF),
      icon: Icons.monitor_heart_rounded,
    );
  }
  if (name.contains('thyroid') ||
      name.contains('hormone') ||
      name.contains('fertility')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF6D28D9),
      soft: Color(0xFFECE7FF),
      tint: Color(0xFFFBFAFF),
      icon: Icons.biotech_rounded,
    );
  }
  if (name.contains('women') || name.contains('pregnancy')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFBE185D),
      soft: Color(0xFFFCE4F1),
      tint: Color(0xFFFFF9FC),
      icon: Icons.female_rounded,
    );
  }
  if (name.contains('men')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF3730A3),
      soft: Color(0xFFE7E9FF),
      tint: Color(0xFFF9FAFF),
      icon: Icons.male_rounded,
    );
  }
  if (name.contains('infection') || name.contains('sexual')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF047857),
      soft: Color(0xFFDCF8EA),
      tint: Color(0xFFF7FFFB),
      icon: Icons.coronavirus_rounded,
    );
  }
  if (name.contains('vitamin') ||
      name.contains('electrolyte') ||
      name.contains('mineral') ||
      name.contains('bone')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFC2410C),
      soft: Color(0xFFFFEAD8),
      tint: Color(0xFFFFFBF7),
      icon: Icons.energy_savings_leaf_rounded,
    );
  }
  if (name.contains('allergy') ||
      name.contains('autoimmune') ||
      name.contains('immunity')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF7E22CE),
      soft: Color(0xFFF1E4FF),
      tint: Color(0xFFFDFBFF),
      icon: Icons.shield_rounded,
    );
  }
  if (name.contains('stool') || name.contains('respiratory')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0F766E),
      soft: Color(0xFFDCF7F2),
      tint: Color(0xFFF8FFFD),
      icon: Icons.science_rounded,
    );
  }
  if (name.contains('cancer') || name.contains('histopath')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF4338CA),
      soft: Color(0xFFE5E9FF),
      tint: Color(0xFFFAFAFF),
      icon: Icons.manage_search_rounded,
    );
  }
  if (name.contains('drug')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF4F46E5),
      soft: Color(0xFFE8E7FF),
      tint: Color(0xFFFAFAFF),
      icon: Icons.medication_rounded,
    );
  }
  if (name.contains('genetic')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0E7490),
      soft: Color(0xFFDFF7FB),
      tint: Color(0xFFF8FEFF),
      icon: Icons.hub_rounded,
    );
  }

  return const MedicalTestCategoryStyle(
    accent: Color(0xFF1D4ED8),
    soft: Color(0xFFE3EDFF),
    tint: Color(0xFFF8FBFF),
    icon: Icons.science_rounded,
  );
}

String medicalTestHeroTag(MedicalTest test) => 'medical-test-${test.id}';

class MedicalTestIconBadge extends StatelessWidget {
  const MedicalTestIconBadge({
    required this.test,
    this.size = 44,
    this.useHero = true,
    super.key,
  });

  final MedicalTest test;
  final double size;
  final bool useHero;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);
    final badge = Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, style.soft],
          ),
          borderRadius: BorderRadius.circular(size * .32),
          border: Border.all(color: style.accent.withValues(alpha: .12)),
        ),
        child: Icon(style.icon, color: style.accent, size: size * .48),
      ),
    );

    if (!useHero || test.id.isEmpty) return badge;
    return Hero(tag: medicalTestHeroTag(test), child: badge);
  }
}

class MedicalTestCompactCard extends StatelessWidget {
  const MedicalTestCompactCard({
    required this.test,
    required this.onTap,
    super.key,
  });

  final MedicalTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);
    final statusLabel = test.isPopular
        ? 'Popular'
        : test.labVisitRequired
        ? 'Lab visit'
        : test.homeCollectionAvailable
        ? 'At home'
        : 'Available';
    final statusIcon = test.isPopular
        ? Icons.local_fire_department_rounded
        : test.labVisitRequired
        ? Icons.apartment_rounded
        : Icons.home_work_outlined;
    final statusForeground = test.isPopular
        ? const Color(0xFFB45309)
        : test.labVisitRequired
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF15803D);
    final statusBackground = test.isPopular
        ? const Color(0xFFFFF5D9)
        : test.labVisitRequired
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFECFDF3);

    return Semantics(
      button: true,
      label: 'Open ${test.displayName} details',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Ink(
            width: 190,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MedicalTestIconBadge(test: test, size: 42),
                    const Spacer(),
                    _StatusChip(
                      label: statusLabel,
                      icon: statusIcon,
                      foreground: statusForeground,
                      background: statusBackground,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  test.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.2,
                    height: 1.24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.18,
                  ),
                ),
                const Spacer(),
                _CompactMeta(
                  icon: Icons.science_outlined,
                  label: test.sampleLabel,
                ),
                const SizedBox(height: 6),
                _CompactMeta(
                  icon: Icons.schedule_rounded,
                  label: test.reportLabel,
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFEEF2F6)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.15,
                        ),
                      ),
                    ),
                    Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: style.soft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: style.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicalTestListCard extends StatelessWidget {
  const MedicalTestListCard({
    required this.test,
    required this.onTap,
    super.key,
  });

  final MedicalTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);

    return Semantics(
      button: true,
      label: 'Open ${test.displayName} details',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4EAF1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0B0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MedicalTestIconBadge(test: test, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  test.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 15,
                                    height: 1.25,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.16,
                                  ),
                                ),
                              ),
                              if (test.isPopular) ...[
                                const SizedBox(width: 8),
                                const _StatusChip(
                                  label: 'Popular',
                                  icon: Icons.local_fire_department_rounded,
                                  foreground: Color(0xFFB45309),
                                  background: Color(0xFFFFF5D9),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            test.parameterCount == null
                                ? test.testTypeLabel
                                : '${test.parameterCount} parameters',
                            style: TextStyle(
                              color: style.accent,
                              fontSize: 11.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.science_outlined,
                      label: test.sampleLabel,
                    ),
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: test.reportLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Container(height: 1, color: const Color(0xFFEEF2F6)),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Text(
                      test.priceLabel,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      test.labVisitRequired
                          ? Icons.apartment_rounded
                          : Icons.home_work_outlined,
                      size: 15,
                      color: const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        test.collectionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: style.soft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: style.accent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 9.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMeta extends StatelessWidget {
  const _CompactMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9EEF4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
