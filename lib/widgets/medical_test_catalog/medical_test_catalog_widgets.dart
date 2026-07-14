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
      soft: Color(0xFFFFF1F2),
      tint: Color(0xFFFFF8F8),
      icon: Icons.bloodtype_rounded,
    );
  }
  if (name.contains('heart')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFDC2626),
      soft: Color(0xFFFEF2F2),
      tint: Color(0xFFFFFAFA),
      icon: Icons.favorite_rounded,
    );
  }
  if (name.contains('kidney') || name.contains('urine')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0369A1),
      soft: Color(0xFFEFF8FF),
      tint: Color(0xFFF8FCFF),
      icon: Icons.water_drop_rounded,
    );
  }
  if (name.contains('liver') || name.contains('digestive')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFB45309),
      soft: Color(0xFFFFF7E8),
      tint: Color(0xFFFFFCF7),
      icon: Icons.health_and_safety_rounded,
    );
  }
  if (name.contains('diabetes')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0E7490),
      soft: Color(0xFFECFEFF),
      tint: Color(0xFFF7FEFF),
      icon: Icons.monitor_heart_rounded,
    );
  }
  if (name.contains('thyroid') ||
      name.contains('hormone') ||
      name.contains('fertility')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF6D28D9),
      soft: Color(0xFFF5F3FF),
      tint: Color(0xFFFBFAFF),
      icon: Icons.biotech_rounded,
    );
  }
  if (name.contains('women') || name.contains('pregnancy')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFFBE185D),
      soft: Color(0xFFFDF2F8),
      tint: Color(0xFFFFF9FC),
      icon: Icons.female_rounded,
    );
  }
  if (name.contains('men')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF3730A3),
      soft: Color(0xFFEEF2FF),
      tint: Color(0xFFF9FAFF),
      icon: Icons.male_rounded,
    );
  }
  if (name.contains('infection') || name.contains('sexual')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF047857),
      soft: Color(0xFFECFDF5),
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
      soft: Color(0xFFFFF7ED),
      tint: Color(0xFFFFFBF7),
      icon: Icons.energy_savings_leaf_rounded,
    );
  }
  if (name.contains('allergy') ||
      name.contains('autoimmune') ||
      name.contains('immunity')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF7E22CE),
      soft: Color(0xFFFAF5FF),
      tint: Color(0xFFFDFBFF),
      icon: Icons.shield_rounded,
    );
  }
  if (name.contains('stool') || name.contains('respiratory')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF0F766E),
      soft: Color(0xFFF0FDFA),
      tint: Color(0xFFF8FFFD),
      icon: Icons.science_rounded,
    );
  }
  if (name.contains('cancer') || name.contains('histopath')) {
    return const MedicalTestCategoryStyle(
      accent: Color(0xFF4338CA),
      soft: Color(0xFFEEF2FF),
      tint: Color(0xFFFAFAFF),
      icon: Icons.manage_search_rounded,
    );
  }

  return const MedicalTestCategoryStyle(
    accent: Color(0xFF1D4ED8),
    soft: Color(0xFFEFF6FF),
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
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.soft,
        borderRadius: BorderRadius.circular(size * .32),
        border: Border.all(color: style.accent.withValues(alpha: .10)),
      ),
      child: Icon(style.icon, color: style.accent, size: size * .48),
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
    return Semantics(
      button: true,
      label: 'Open ${test.displayName} details',
      child: Material(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 166,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFE6EAF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x090F172A),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MedicalTestIconBadge(test: test, size: 39),
                    const Spacer(),
                    if (test.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Popular',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 9.5,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  test.displayName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.4,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.12,
                  ),
                ),
                const Spacer(),
                _CompactMeta(
                  icon: Icons.schedule_rounded,
                  label: test.reportLabel,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: Color(0xFF64748B),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EAF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicalTestIconBadge(test: test),
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
                              fontSize: 14.5,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          test.priceLabel,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _InlineMeta(
                          icon: Icons.science_outlined,
                          label: test.sampleLabel,
                        ),
                        _InlineMeta(
                          icon: Icons.schedule_rounded,
                          label: test.reportLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
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
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
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
        const SizedBox(width: 5),
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

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
