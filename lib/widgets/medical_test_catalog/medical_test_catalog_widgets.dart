import 'package:flutter/material.dart';

import '../../models/medical_test.dart';
import '../../utils/test_pricing.dart';

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
  final icon = _medicalTestCategoryIcon(name);

  // Home category modules own their category-specific palettes. Every other
  // catalogue surface intentionally shares this single Testified-blue system.
  return MedicalTestCategoryStyle(
    accent: const Color(0xFF2563EB),
    soft: const Color(0xFFEAF2FF),
    tint: const Color(0xFFF6F9FF),
    icon: icon,
  );
}

IconData _medicalTestCategoryIcon(String name) {
  if (name.contains('blood') || name.contains('coagulation')) {
    return Icons.bloodtype_rounded;
  }
  if (name.contains('heart') || name.contains('cardiac')) {
    return Icons.favorite_rounded;
  }
  if (name.contains('kidney') ||
      name.contains('renal') ||
      name.contains('urine')) {
    return Icons.water_drop_rounded;
  }
  if (name.contains('liver') ||
      name.contains('hepatic') ||
      name.contains('digestive')) {
    return Icons.health_and_safety_rounded;
  }
  if (name.contains('diabetes') || name.contains('sugar')) {
    return Icons.monitor_heart_rounded;
  }
  if (name.contains('thyroid') ||
      name.contains('hormone') ||
      name.contains('fertility')) {
    return Icons.biotech_rounded;
  }
  if (name.contains('women') || name.contains('pregnancy')) {
    return Icons.female_rounded;
  }
  if (name.contains('men')) return Icons.male_rounded;
  if (name.contains('infection') || name.contains('sexual')) {
    return Icons.coronavirus_rounded;
  }
  if (name.contains('vitamin') ||
      name.contains('electrolyte') ||
      name.contains('mineral') ||
      name.contains('bone')) {
    return Icons.energy_savings_leaf_rounded;
  }
  if (name.contains('allergy') ||
      name.contains('autoimmune') ||
      name.contains('immunity')) {
    return Icons.shield_rounded;
  }
  if (name.contains('cancer') || name.contains('histopath')) {
    return Icons.manage_search_rounded;
  }
  if (name.contains('drug')) return Icons.medication_rounded;
  if (name.contains('genetic')) return Icons.hub_rounded;
  return Icons.science_rounded;
}

String? medicalTestCategoryArtworkAsset(String category) {
  final name = category.toLowerCase();

  if (name.contains('liver') ||
      name.contains('hepatic') ||
      name.contains('digestive')) {
    return 'assets/images/medical_categories/liver.webp';
  }
  if (name.contains('heart') ||
      name.contains('cardiac') ||
      name.contains('lipid')) {
    return 'assets/images/medical_categories/heart.webp';
  }
  if (name.contains('thyroid')) {
    return 'assets/images/medical_categories/thyroid.webp';
  }
  if (name.contains('kidney') ||
      name.contains('renal') ||
      name.contains('urine')) {
    return 'assets/images/medical_categories/kidney.webp';
  }
  if (name.contains('vitamin') ||
      name.contains('electrolyte') ||
      name.contains('mineral') ||
      name.contains('bone')) {
    return 'assets/images/medical_categories/vitamins.webp';
  }
  if (name.contains('blood') ||
      name.contains('coagulation') ||
      name.contains('diabetes') ||
      name.contains('sugar')) {
    return 'assets/images/medical_categories/blood.webp';
  }
  if (name.contains('allergy') ||
      name.contains('autoimmune') ||
      name.contains('immunity') ||
      name.contains('infection')) {
    return 'assets/images/medical_categories/immunity.webp';
  }
  return null;
}

class MedicalCategoryIllustration extends StatelessWidget {
  const MedicalCategoryIllustration({
    required this.category,
    required this.color,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String category;
  final Color color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = medicalTestCategoryArtworkAsset(category);
    final fallbackIcon = medicalTestCategoryStyle(category).icon;

    if (asset == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Icon(fallbackIcon, color: color),
      );
    }

    return Image.asset(
      asset,
      fit: fit,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Icon(fallbackIcon, color: color),
      ),
    );
  }
}

String medicalTestHeroTag(MedicalTest test) => 'medical-test-${test.id}';

class DiscountedPrice extends StatelessWidget {
  const DiscountedPrice({
    required this.mrp,
    required this.sellingPrice,
    this.fallbackLabel = 'Price at booking',
    this.semanticLabel,
    this.showMrpLabel = true,
    this.mrpFontSize = 10.8,
    this.priceFontSize = 15,
    this.priceColor = const Color(0xFF0F172A),
    this.mrpColor = const Color(0xFF7C8799),
    this.alignment = WrapAlignment.start,
    super.key,
  });

  final double? mrp;
  final double? sellingPrice;
  final String fallbackLabel;
  final String? semanticLabel;
  final bool showMrpLabel;
  final double mrpFontSize;
  final double priceFontSize;
  final Color priceColor;
  final Color mrpColor;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final original = mrp;
    final offer = sellingPrice;
    if (original == null || offer == null) {
      return Text(
        fallbackLabel,
        style: TextStyle(
          color: priceColor,
          fontSize: priceFontSize,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    final mrpText =
        '${showMrpLabel ? 'MRP ' : ''}${TestPricing.formatCurrency(original)}';
    final offerText = TestPricing.formatCurrency(offer);
    final accessibleLabel =
        semanticLabel ??
        'MRP ${TestPricing.formatCurrency(original)}, offer price $offerText';

    return Semantics(
      label: accessibleLabel,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: alignment,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          runSpacing: 3,
          children: [
            Text(
              mrpText,
              maxLines: 1,
              style: TextStyle(
                color: mrpColor,
                fontSize: mrpFontSize,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                decorationColor: mrpColor,
                decorationThickness: 1.5,
              ),
            ),
            Text(
              offerText,
              maxLines: 1,
              style: TextStyle(
                color: priceColor,
                fontSize: priceFontSize,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -.12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicalTestPrice extends StatelessWidget {
  const MedicalTestPrice({
    required this.test,
    this.showMrpLabel = true,
    this.mrpFontSize = 10.8,
    this.priceFontSize = 15,
    this.priceColor = const Color(0xFF0F172A),
    this.alignment = WrapAlignment.start,
    super.key,
  });

  final MedicalTest test;
  final bool showMrpLabel;
  final double mrpFontSize;
  final double priceFontSize;
  final Color priceColor;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return DiscountedPrice(
      mrp: test.mrp,
      sellingPrice: test.sellingPrice,
      fallbackLabel: test.priceLabel,
      semanticLabel: test.priceSemanticsLabel,
      showMrpLabel: showMrpLabel,
      mrpFontSize: mrpFontSize,
      priceFontSize: priceFontSize,
      priceColor: priceColor,
      alignment: alignment,
    );
  }
}

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
        child: Padding(
          padding: EdgeInsets.all(size * .17),
          child: MedicalCategoryIllustration(
            category: test.category,
            color: style.accent,
          ),
        ),
      ),
    );

    if (!useHero || test.id.isEmpty) return badge;
    return Hero(tag: medicalTestHeroTag(test), child: badge);
  }
}

/// Image-led artwork for a medical category using the supplied organ drawings.
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
              padding: EdgeInsets.all(height * .09),
              child: MedicalCategoryIllustration(
                category: category,
                color: style.accent,
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

/// A test-card visual using the supplied medical line artwork.
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
                    color: test.isPopular ? Colors.white : style.accent,
                    fontSize: 8.2,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
              ),
            ),
          Center(
            child: Container(
              width: compact ? height * .56 : height * .58,
              height: compact ? height * .63 : height * .66,
              padding: EdgeInsets.all(height * .08),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(height * .16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .96),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.accent.withValues(alpha: .14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: MedicalCategoryIllustration(
                category: test.category,
                color: style.accent,
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
                      child: MedicalTestPrice(
                        test: test,
                        showMrpLabel: false,
                        mrpFontSize: 9.4,
                        priceFontSize: 14.2,
                        priceColor: const Color(0xFF111827),
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
                        child: MedicalTestPrice(
                          test: test,
                          showMrpLabel: false,
                          mrpFontSize: 9.4,
                          priceFontSize: 14.4,
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
  final sample =
      ('${test.sampleSourceLabel ?? ''} '
              '${test.sampleSource ?? ''} ${test.sampleTypeVolume ?? ''}')
          .toLowerCase();

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
                    MedicalTestPrice(
                      test: test,
                      showMrpLabel: false,
                      mrpFontSize: 10,
                      priceFontSize: 16,
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
