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

/// Image-led, code-native artwork for a medical category.
///
/// The catalogue does not store product photography. This keeps the visual
/// hierarchy of a marketplace tile without inventing test images or relying on
/// a network asset that may not match the selected test.
class MedicalCategoryArtwork extends StatelessWidget {
  const MedicalCategoryArtwork({
    required this.category,
    this.height = 108,
    this.borderRadius = 18,
    super.key,
  });

  final String category;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(category);

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.tint, style.soft],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: style.accent.withValues(alpha: .10)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -26,
            child: Container(
              width: height * .92,
              height: height * .92,
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -34,
            child: Container(
              width: height * .78,
              height: height * .78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .52),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Container(
              width: height * .53,
              height: height * .53,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(height * .18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .92),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.accent.withValues(alpha: .13),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                style.icon,
                color: style.accent,
                size: height * .28,
              ),
            ),
          ),
          Positioned(
            right: 11,
            bottom: 10,
            child: Container(
              width: height * .25,
              height: height * .25,
              decoration: BoxDecoration(
                color: style.accent,
                borderRadius: BorderRadius.circular(height * .09),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: height * .15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A photo-shaped visual area for a test card. It deliberately resembles a
/// packaged diagnostic vial rather than a generic icon badge.
class MedicalTestArtwork extends StatelessWidget {
  const MedicalTestArtwork({
    required this.test,
    this.height = 126,
    this.borderRadius = 18,
    this.compact = false,
    super.key,
  });

  final MedicalTest test;
  final double height;
  final double borderRadius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = medicalTestCategoryStyle(test.category);
    final badgeLabel = test.isPopular
        ? 'Popular'
        : test.parameterCount != null && test.parameterCount! > 0
        ? '${test.parameterCount} MARKERS'
        : test.testTypeLabel.toUpperCase();

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.tint, style.soft],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: style.accent.withValues(alpha: .10)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -height * .16,
            top: -height * .24,
            child: Container(
              width: height * .82,
              height: height * .82,
              decoration: BoxDecoration(
                color: style.accent.withValues(alpha: .065),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -height * .20,
            bottom: -height * .31,
            child: Container(
              width: height * .88,
              height: height * .88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .50),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (!compact)
            Positioned(
              left: 9,
              top: 9,
              child: Container(
                constraints: BoxConstraints(maxWidth: height * .86),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: test.isPopular
                      ? const Color(0xFF0C8B5A)
                      : Colors.white.withValues(alpha: .90),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badgeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: test.isPopular
                        ? Colors.white
                        : style.accent,
                    fontSize: 8.2,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
              ),
            ),
          Center(
            child: Transform.rotate(
              angle: -.055,
              child: Container(
                width: compact ? height * .42 : height * .38,
                height: compact ? height * .62 : height * .60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(height * .14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .96),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: style.accent.withValues(alpha: .16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: compact ? 9 : 11,
                      margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                      decoration: BoxDecoration(
                        color: style.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: Icon(
                        style.icon,
                        color: style.accent,
                        size: compact ? height * .24 : height * .22,
                      ),
                    ),
                    Container(
                      height: compact ? 10 : 13,
                      decoration: BoxDecoration(
                        color: style.accent.withValues(alpha: .15),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(height * .12),
                          bottomRight: Radius.circular(height * .12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: compact ? 7 : 11,
            bottom: compact ? 7 : 10,
            child: Container(
              width: compact ? 25 : 31,
              height: compact ? 25 : 31,
              decoration: BoxDecoration(
                color: style.accent,
                borderRadius: BorderRadius.circular(compact ? 9 : 11),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _sampleIconFor(test),
                color: Colors.white,
                size: compact ? 14 : 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicalTestMarketplaceGridCard extends StatelessWidget {
  const MedicalTestMarketplaceGridCard({
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
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EAF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C0F172A),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalTestArtwork(test: test, height: 116),
                const SizedBox(height: 9),
                Text(
                  test.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 12.8,
                    height: 1.22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  test.parameterCount == null
                      ? test.sampleLabel
                      : '${test.parameterCount} health markers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: style.soft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: style.accent,
                        size: 15,
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

    return Semantics(
      button: true,
      label: 'Open ${test.displayName} details',
      child: SizedBox(
        width: 164,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MedicalTestArtwork(test: test, height: 126),
                  const SizedBox(height: 9),
                  Text(
                    test.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13.4,
                      height: 1.20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    test.reportLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: style.accent,
                      fontSize: 10.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          test.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14.4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        test.labVisitRequired
                            ? Icons.apartment_rounded
                            : Icons.home_work_outlined,
                        color: style.accent,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _sampleIconFor(MedicalTest test) {
  final sample = (
    '${test.sampleSourceLabel ?? ''} '
    '${test.sampleSource ?? ''} ${test.sampleTypeVolume ?? ''}'
  ).toLowerCase();

  if (sample.contains('urine')) return Icons.water_drop_rounded;
  if (sample.contains('stool')) return Icons.biotech_rounded;
  if (sample.contains('swab')) return Icons.air_rounded;
  if (sample.contains('saliva')) return Icons.water_rounded;
  if (test.labVisitRequired) return Icons.apartment_rounded;
  return Icons.bloodtype_rounded;
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
